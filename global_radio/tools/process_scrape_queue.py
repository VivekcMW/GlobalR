#!/usr/bin/env python3
"""Drain the `scrapeQueue` Firestore collection: for every interest a user
has typed into the app that has no matching catalog content yet (see
lib/features/settings/interests_screen.dart + scrape_queue_service.dart),
scrape English text for it from a legally-approved source (Wikisource for
curated literary interests, falling back to Wikipedia — CC BY-SA, real
coverage of any current topic — for anything Wikisource has no chance of
matching, e.g. a modern/technical free-typed interest), fan it out to
every language, and auto-promote it straight into the catalog — same
unattended pipeline as tools/harvest_top_interests.py, just driven by
explicit user requests instead of aggregate interest popularity.

Deliberately stays inside tools/check_legal.py's approved-source list
(public domain / CC-BY / CC-BY-SA) rather than scraping arbitrary web
content — the latter would mean redistributing copyrighted text with no
license, which is exactly what the legal-check gate exists to catch.

Auth: `gcloud auth print-access-token` (Application Default Credentials),
same as tools/aggregate_user_interests.py. Marking a request 'done' needs
Firestore *write* access — if that's not configured for this runner, the
scrape still happens, it just logs a warning and leaves the doc 'pending'
(so it'll just be reprocessed next run — wasteful but harmless, never
silently lost).

Usage:
    python tools/process_scrape_queue.py
    python tools/process_scrape_queue.py --project globalir --limit 8
    python tools/process_scrape_queue.py --dry-run
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent

# Reuse the same interest -> English query mapping as the popularity-based
# harvest; anything not in this dict (i.e. any free-typed custom interest)
# falls back to a generic "<interest> story" query.
from harvest_top_interests import INTEREST_QUERIES  # noqa: E402


def get_access_token() -> str:
    out = subprocess.run(
        ["gcloud", "auth", "print-access-token"],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def fetch_pending(project: str, token: str) -> list[dict]:
    docs: list[dict] = []
    page_token: str | None = None
    base = f"https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents/scrapeQueue"
    headers = {"Authorization": f"Bearer {token}", "x-goog-user-project": project}
    while True:
        params: dict = {"pageSize": 300}
        if page_token:
            params["pageToken"] = page_token
        resp = requests.get(base, headers=headers, params=params, timeout=30)
        if resp.status_code == 404:
            return []  # collection doesn't exist yet — nothing queued, ever
        if resp.status_code != 200:
            raise RuntimeError(f"Firestore list failed: {resp.status_code} {resp.text[:300]}")
        data = resp.json()
        docs.extend(data.get("documents", []))
        page_token = data.get("nextPageToken")
        if not page_token:
            break

    pending = []
    for doc in docs:
        fields = doc.get("fields", {})
        status = fields.get("status", {}).get("stringValue")
        interest = fields.get("interest", {}).get("stringValue")
        if status == "pending" and interest:
            pending.append({"name": doc["name"], "interest": interest})
    return pending


def mark_done(name: str, token: str, project: str) -> None:
    url = f"https://firestore.googleapis.com/v1/{name}"
    headers = {"Authorization": f"Bearer {token}", "x-goog-user-project": project}
    params = {"updateMask.fieldPaths": "status"}
    body = {"fields": {"status": {"stringValue": "done"}}}
    resp = requests.patch(url, headers=headers, params=params, json=body, timeout=30)
    if resp.status_code != 200:
        print(f"  [warn] couldn't mark {name} done ({resp.status_code}) — "
              "will just be reprocessed next run", file=sys.stderr)


def run(cmd: list[str], dry_run: bool) -> None:
    print(f"$ {' '.join(cmd)}")
    if dry_run:
        return
    subprocess.run(cmd, check=False)


# Wikisource is a literature archive (pre-1929 public-domain text) — it has
# no chance of matching a modern/technical free-typed interest (e.g.
# "devops"), only literary/thematic ones. Wikipedia (CC BY-SA, already an
# approved source — see tools/check_legal.py) has real coverage of almost
# any current topic, so it's the better first attempt for interests that
# aren't in INTEREST_QUERIES's hand-tuned literary list; for curated ones,
# try Wikisource first since its query was tuned specifically for it.
FALLBACK_SOURCES = ("wikisource", "wikipedia")


def draft_path(language: str, source: str) -> Path:
    return ROOT / "content" / "library" / "drafts" / f"{source}-{language}.json"


def scrape_one_source(source: str, language: str, query: str, interest: str,
                      limit: int, dry_run: bool) -> bool:
    """Run ingest_public_sources.py for a single source. Returns True if it
    actually produced a draft (a search returning zero hits exits 0 with no
    file written, so success has to be checked by file presence, not
    exit code)."""
    path = draft_path(language, source)
    path.unlink(missing_ok=True)  # so we can tell if THIS call created it
    run([sys.executable, str(ROOT / "ingest_public_sources.py"),
         "--source", source, "--language", language,
         "--query", query, "--interest", interest, "--limit", str(limit)],
        dry_run)
    return dry_run or path.exists()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default="globalir")
    ap.add_argument("--limit", type=int, default=8, help="pages per queued interest, per source")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    try:
        token = get_access_token()
        pending = fetch_pending(args.project, token)
    except (subprocess.CalledProcessError, RuntimeError) as e:
        print(f"[warn] couldn't read scrapeQueue ({e}); nothing to process this run", file=sys.stderr)
        return

    if not pending:
        print("scrapeQueue is empty — nothing to do.")
        return

    print(f"{len(pending)} pending request(s): {[p['interest'] for p in pending]}")

    # Each source's ingest call always writes to the SAME file
    # (drafts/{source}-english.json), overwriting it each call. Translating
    # + promoting immediately after each interest drains that file before
    # the next interest's scrape can clobber it — batching all scrapes
    # first (the original design) silently lost every interest but the
    # last one in the queue.
    for req in pending:
        interest = req["interest"]
        curated = interest in INTEREST_QUERIES
        sources = FALLBACK_SOURCES if curated else tuple(reversed(FALLBACK_SOURCES))
        found = False
        for source in sources:
            # Wikisource's query is tuned for literary/thematic phrasing
            # ("<interest> story"); Wikipedia just wants the topic itself.
            query = INTEREST_QUERIES.get(interest, f"{interest} story") if source == "wikisource" else interest
            if scrape_one_source(source, "english", query, interest, args.limit, args.dry_run):
                found = True
                break
        if not found and not args.dry_run:
            print(f"  [warn] no content found for '{interest}' on any source ({', '.join(sources)})")
        run([sys.executable, str(ROOT / "translate_fanout.py"), "--limit", "25"], args.dry_run)
        run([sys.executable, str(ROOT / "auto_promote_drafts.py")], args.dry_run)

    if args.dry_run:
        print("--dry-run: not marking any request done")
        return

    for req in pending:
        try:
            mark_done(req["name"], token, args.project)
        except requests.RequestException as e:
            print(f"  [warn] mark_done failed for {req['interest']}: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
