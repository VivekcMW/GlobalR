#!/usr/bin/env python3
"""Merge this run's freshly-built catalog.json on top of whatever's
actually live on the CDN right now, id-keyed.

Used by the "Deploy to interim GitHub-raw CDN" step in
nightly-content.yml, immediately before commit+push. A run's own
catalog.json was last synced from the live CDN at job START ("Sync
catalog.json baseline from the live CDN") — for the twice-daily full
pipeline that can be up to ~an hour before this step runs. If another
run published a brand-new item in the meantime (e.g. a scrape-queue
promotion), a blind overwrite here would silently erase it. Confirmed
in practice on 2026-08-12: a "devops" scrape-queue promotion pushed by
one run at 13:41 was wiped by another run's deploy at 14:11, because
that run's local catalog.json was built from a 13:30 snapshot that
predated the devops push.

Rule: id-keyed union. An id present in both keeps OUR version (we're
the more recent/authoritative source for anything we actually touched
this run); an id only the live base has is kept as-is; an id only we
have is added.

Usage:
    python tools/merge_deploy_catalog.py --base catalog.json --ours ours.json --out catalog.json
"""
from __future__ import annotations

import argparse
import json


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True, help="freshly-cloned live catalog.json")
    ap.add_argument("--ours", required=True, help="this run's own catalog.json")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    with open(args.base, encoding="utf-8") as f:
        base = json.load(f)
    with open(args.ours, encoding="utf-8") as f:
        ours = json.load(f)

    ours_ids = {it["id"] for it in ours["items"]}
    base_only = [it for it in base.get("items", []) if it["id"] not in ours_ids]
    merged_items = base_only + ours["items"]

    merged = dict(ours)  # keep our run's version/metadata tag
    merged["items"] = merged_items
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    print(f"merged: {len(base.get('items', []))} base + {len(ours['items'])} ours "
          f"-> {len(merged_items)} total ({len(base_only)} kept only-in-base)")


if __name__ == "__main__":
    main()
