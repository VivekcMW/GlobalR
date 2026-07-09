#!/usr/bin/env python3
"""Drain the `scrapeQueue` Firestore collection: for every interest a user
has typed into the app that has no matching catalog content yet (see
lib/features/settings/interests_screen.dart + scrape_queue_service.dart),
scrape English public-domain text for it, fan it out to every language, and
auto-promote it straight into the catalog — same unattended pipeline as
tools/harvest_top_interests.py, just driven by explicit user requests
instead of aggregate interest popularity.

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


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default="globalir")
    ap.add_argument("--limit", type=int, default=8, help="Wikisource pages per queued interest")
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

    for req in pending:
        interest = req["interest"]
        query = INTEREST_QUERIES.get(interest, f"{interest} story")
        run([sys.executable, str(ROOT / "ingest_public_sources.py"),
             "--source", "wikisource", "--language", "english",
             "--query", query, "--interest", interest, "--limit", str(args.limit)],
            args.dry_run)

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
