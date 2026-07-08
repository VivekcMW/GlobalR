#!/usr/bin/env python3
"""Catalog depth guard for Global Radio.

Ensures every active (category x language) pair has at least a minimum number
of ready-to-stream audio items in catalog.json, so listeners never run dry.

Run before every deploy and nightly in CI:

    python tools/catalog_depth.py                          # cdn_dist/catalog.json
    python tools/catalog_depth.py --min 20 --langs hindi,english
    python tools/catalog_depth.py --catalog assets/catalog/catalog.json --report

Exit code 0 = all enforced pairs meet the minimum. Non-zero = gaps found
(the output lists exactly which categories need more authored items).
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DEFAULT_CATALOG = ROOT.parent / "cdn_dist" / "catalog.json"

# Categories the radio experience actively programs. Only these are enforced;
# everything else is report-only. Grow this list as new categories launch.
CORE_CATEGORIES = [
    "kids",
    "moral",
    "bedtime",
    "fairytales",
    "devotion",
    "folklore",
]

# Languages with a live audience today. Enforcement applies to these only.
CORE_LANGUAGES = ["hindi", "english"]


def depth_table(items: list[dict]) -> dict[str, dict[str, int]]:
    """counts[category][language] = number of reachable items."""
    counts: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for item in items:
        if item.get("reachable") is False:
            continue
        lang = item.get("language", "?")
        for cat in item.get("interests", []):
            counts[cat][lang] += 1
    return counts


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--catalog", default=str(DEFAULT_CATALOG))
    ap.add_argument("--min", type=int, default=20,
                    help="minimum items per enforced (category x language)")
    ap.add_argument("--langs", default=",".join(CORE_LANGUAGES),
                    help="comma list of languages to enforce")
    ap.add_argument("--categories", default=",".join(CORE_CATEGORIES),
                    help="comma list of categories to enforce")
    ap.add_argument("--report", action="store_true",
                    help="print full depth table for all pairs")
    args = ap.parse_args()

    catalog_path = Path(args.catalog)
    if not catalog_path.exists():
        print(f"[depth] catalog not found: {catalog_path}")
        sys.exit(2)

    with open(catalog_path, encoding="utf-8") as f:
        items = json.load(f).get("items", [])

    counts = depth_table(items)
    langs = [l.strip() for l in args.langs.split(",") if l.strip()]
    cats = [c.strip() for c in args.categories.split(",") if c.strip()]

    if args.report:
        all_langs = sorted({it.get("language", "?") for it in items})
        header = "category".ljust(14) + "".join(l[:8].ljust(10) for l in all_langs)
        print(header)
        for cat in sorted(counts):
            row = cat.ljust(14)
            for lang in all_langs:
                row += str(counts[cat].get(lang, 0)).ljust(10)
            print(row)
        print()

    gaps: list[str] = []
    for cat in cats:
        for lang in langs:
            have = counts.get(cat, {}).get(lang, 0)
            if have < args.min:
                gaps.append(f"  {cat} / {lang}: {have}/{args.min} "
                            f"(need {args.min - have} more)")

    if gaps:
        print(f"[depth] FAIL — pairs below minimum of {args.min}:")
        print("\n".join(gaps))
        print("\nAuthor more items in tools/content/library/<category>.json "
              "then run build_catalog.py.")
        sys.exit(1)

    print(f"[depth] OK — all {len(cats)}x{len(langs)} enforced pairs have "
          f">= {args.min} items.")
    sys.exit(0)


if __name__ == "__main__":
    main()
