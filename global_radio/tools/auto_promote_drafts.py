#!/usr/bin/env python3
"""Promote every draft in content/library/drafts/*.json straight into a
permanent category file — no human review step.

This project used to require an editor to review each scraped/translated
draft before it could build (see ingest_public_sources.py's DRAFTS_DIR
comment). That gate has been intentionally removed for the automated
pipeline: drafts are stripped of their draft markers and merged into
content/library/scraped.json unattended, then picked up by the next
build_catalog.py run like any other category file.

Promoted draft files are moved to content/library/drafts/promoted/ (not
deleted) so there's still an audit trail of exactly what got auto-published
and when, even though nothing blocks on it.

Usage:
    python tools/auto_promote_drafts.py
    python tools/auto_promote_drafts.py --dry-run
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONTENT = ROOT / "content"
DRAFTS_DIR = CONTENT / "library" / "drafts"
PROMOTED_DIR = DRAFTS_DIR / "promoted"
SCRAPED_PATH = CONTENT / "library" / "scraped.json"

DRAFT_ONLY_KEYS = ("_draft", "_sourceUrl", "_note")


def load_scraped() -> dict[str, dict]:
    if not SCRAPED_PATH.exists():
        return {}
    with open(SCRAPED_PATH, encoding="utf-8") as f:
        return {it["base_id"]: it for it in json.load(f).get("items", [])}


def promote_item(item: dict) -> dict:
    return {k: v for k, v in item.items() if k not in DRAFT_ONLY_KEYS}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="report what would happen, change nothing")
    args = ap.parse_args()

    draft_files = sorted(p for p in DRAFTS_DIR.glob("*.json") if p.parent == DRAFTS_DIR)
    if not draft_files:
        print("No draft files to promote.")
        return

    scraped = load_scraped()
    before = len(scraped)
    promoted_files: list[Path] = []

    for path in draft_files:
        with open(path, encoding="utf-8") as f:
            payload = json.load(f)
        items = payload.get("items", [])
        if not items:
            continue
        for item in items:
            promoted = promote_item(item)
            base_id = promoted["base_id"]
            if base_id in scraped:
                # Merge titles/text across languages instead of overwriting,
                # in case the same story was scraped for two languages.
                scraped[base_id]["titles"].update(promoted.get("titles", {}))
                scraped[base_id]["text"].update(promoted.get("text", {}))
            else:
                scraped[base_id] = promoted
        promoted_files.append(path)
        print(f"[promote] {path.name}: {len(items)} item(s)")

    added = len(scraped) - before
    print(f"\n{added} new base story/stories, {len(scraped)} total in scraped.json")

    if args.dry_run:
        print("--dry-run: not writing scraped.json or moving drafts")
        return

    CONTENT.joinpath("library").mkdir(parents=True, exist_ok=True)
    with open(SCRAPED_PATH, "w", encoding="utf-8") as f:
        json.dump({"items": list(scraped.values())}, f, ensure_ascii=False, indent=2)

    PROMOTED_DIR.mkdir(parents=True, exist_ok=True)
    for path in promoted_files:
        path.rename(PROMOTED_DIR / path.name)
    print(f"Moved {len(promoted_files)} draft file(s) to {PROMOTED_DIR}")


if __name__ == "__main__":
    main()
