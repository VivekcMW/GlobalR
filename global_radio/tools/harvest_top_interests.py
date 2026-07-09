#!/usr/bin/env python3
"""Interest-driven content harvest: find out what real users are actually
interested in, scrape fresh English-language public-domain text matched to
that demand, fan it out to every language, and promote it straight into the
live catalog — fully unattended (see CHANGELOG for the review-gate decision).

Deliberately scrapes English only. Building a reliable per-interest search
query in 9 other languages by hand isn't practical; translate_fanout.py
(deep-translator, already in this pipeline) already exists specifically to
take one English draft and fan it out to every supported language, so this
reuses that instead of duplicating it per-language.

Usage:
    python tools/harvest_top_interests.py                 # top 3 interests
    python tools/harvest_top_interests.py --top 5 --limit 10
    python tools/harvest_top_interests.py --dry-run
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# English search query per interest, for Wikisource (public-domain prose).
# Interests with no good fit for a text-source harvest (e.g. "news", which
# is already handled by fetch_news.py) are simply omitted.
INTEREST_QUERIES = {
    "kids": "fable moral story for children",
    "moral": "moral story fable",
    "devotion": "devotional hymn prayer",
    "meditation": "meditation mindfulness",
    "yoga": "yoga philosophy",
    "astrology": "astrology zodiac",
    "mantras": "mantra chant hymn",
    "education": "science biography scientist",
    "history": "Indian history freedom fighter",
    "science": "scientist discovery",
    "technology": "invention technology history",
    "biography": "biography life story",
    "comedy": "humor comic story",
    "drama": "drama play story",
    "music": "music musician biography",
    "poetry": "poem poetry",
    "fiction": "short story fiction",
    "health": "health wellness",
    "cooking": "recipe cooking traditional",
    "travel": "travel adventure story",
    "motivation": "motivational quotes inspiration",
    "relationships": "family relationships story",
    "business": "business entrepreneur biography",
    "sports": "sports athlete biography",
    "politics": "political leader biography",
    "folklore": "folk tale legend",
    "culture": "culture tradition festival",
    "festivals": "festival tradition celebration",
}


def run(cmd: list[str], dry_run: bool) -> None:
    print(f"$ {' '.join(cmd)}")
    if dry_run:
        return
    subprocess.run(cmd, check=False)  # never let one interest's failure stop the rest


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=3)
    ap.add_argument("--limit", type=int, default=8, help="Wikisource pages per interest")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    import json
    if args.dry_run:
        print("--dry-run: skipping live aggregate_user_interests.py, using its defaults")
        from aggregate_user_interests import DEFAULT_INTERESTS
        top_interests = DEFAULT_INTERESTS[: args.top]
    else:
        agg = subprocess.run(
            [sys.executable, str(ROOT / "aggregate_user_interests.py"), "--top", str(args.top), "--json"],
            capture_output=True, text=True,
        )
        if agg.returncode != 0:
            print(f"[warn] aggregate_user_interests.py failed: {agg.stderr}", file=sys.stderr)
            top_interests = []
        else:
            top_interests = json.loads(agg.stdout.strip() or "[]")

    mapped = [i for i in top_interests if i in INTEREST_QUERIES]
    print(f"Top interests: {top_interests} -> harvesting for: {mapped}")

    for interest in mapped:
        query = INTEREST_QUERIES[interest]
        run([sys.executable, str(ROOT / "ingest_public_sources.py"),
             "--source", "wikisource", "--language", "english",
             "--query", query, "--interest", interest, "--limit", str(args.limit)],
            args.dry_run)

    if mapped:
        run([sys.executable, str(ROOT / "translate_fanout.py"), "--limit", "25"], args.dry_run)

    run([sys.executable, str(ROOT / "auto_promote_drafts.py")], args.dry_run)


if __name__ == "__main__":
    main()
