#!/usr/bin/env python3
"""Aggregate the `interests` field across every user in Firestore's `users`
collection, so the content pipeline can prioritise scraping/generation for
whatever real users actually care about.

Auth: uses `gcloud auth print-access-token` (Application Default
Credentials) — same pattern already used elsewhere in this project for
Firebase/GCP REST calls. Needs an identity with Firestore read access on
the target project (globalir).

Usage:
    python tools/aggregate_user_interests.py                    # top 5, human-readable
    python tools/aggregate_user_interests.py --top 3 --json      # machine-readable for CI
    python tools/aggregate_user_interests.py --project globalir
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import Counter

import requests

# Sensible fallback when there are few/no real users yet (e.g. pre-launch),
# so the pipeline still has something to work with instead of doing nothing.
DEFAULT_INTERESTS = ["kids", "moral", "devotion", "folklore", "motivation"]


def get_access_token() -> str:
    out = subprocess.run(
        ["gcloud", "auth", "print-access-token"],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def fetch_all_user_docs(project: str, token: str) -> list[dict]:
    docs: list[dict] = []
    page_token: str | None = None
    base = f"https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents/users"
    headers = {"Authorization": f"Bearer {token}", "x-goog-user-project": project}
    while True:
        params: dict = {"pageSize": 300}
        if page_token:
            params["pageToken"] = page_token
        resp = requests.get(base, headers=headers, params=params, timeout=30)
        if resp.status_code != 200:
            raise RuntimeError(f"Firestore list failed: {resp.status_code} {resp.text[:300]}")
        data = resp.json()
        docs.extend(data.get("documents", []))
        page_token = data.get("nextPageToken")
        if not page_token:
            break
    return docs


def extract_interests(doc: dict) -> list[str]:
    fields = doc.get("fields", {})
    arr = fields.get("interests", {}).get("arrayValue", {}).get("values", [])
    return [v.get("stringValue", "") for v in arr if v.get("stringValue")]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default="globalir")
    ap.add_argument("--top", type=int, default=5)
    ap.add_argument("--json", action="store_true", help="print a JSON list instead of a human summary")
    args = ap.parse_args()

    try:
        token = get_access_token()
        docs = fetch_all_user_docs(args.project, token)
    except (subprocess.CalledProcessError, RuntimeError) as e:
        print(f"[warn] couldn't read Firestore users ({e}); falling back to defaults", file=sys.stderr)
        docs = []

    counts = Counter()
    for doc in docs:
        counts.update(extract_interests(doc))

    if counts:
        top = [interest for interest, _ in counts.most_common(args.top)]
    else:
        top = DEFAULT_INTERESTS[: args.top]

    if args.json:
        print(json.dumps(top))
    else:
        print(f"Read {len(docs)} user profile(s).")
        if counts:
            print("Interest counts:")
            for interest, n in counts.most_common():
                print(f"  {interest}: {n}")
        else:
            print("No interest data yet — using defaults.")
        print(f"\nTop {args.top}: {', '.join(top)}")


if __name__ == "__main__":
    main()
