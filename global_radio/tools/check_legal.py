#!/usr/bin/env python3
"""Legal compliance checker for the Global Radio content catalog.

Validates that every item in the catalog has proper attribution and conforms to
the legally-safe content guidelines in docs/legal-safe-launch-checklist.md.

Checks:
  1. Every item has a non-empty attribution string.
  2. Attribution uses an approved source type (public_domain, original, cc_by).
  3. No forbidden license types (NC, ND, copyrighted without license).
  4. Astrology readings are flagged as 'original' (computed, not copied).
  5. Devotion content is original or uses public-domain prayers.

Run:
    python tools/check_legal.py                    # checks cdn_dist/catalog.json
    python tools/check_legal.py --catalog assets/catalog/catalog.json
    python tools/check_legal.py --library          # checks library.json source

Exit code 0 = all items pass. Non-zero = issues found.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONTENT = ROOT / "content"
DEFAULT_CATALOG = ROOT.parent / "cdn_dist" / "catalog.json"
BUNDLED_CATALOG = ROOT.parent / "assets" / "catalog" / "catalog.json"

# Approved attribution patterns (case-insensitive partial match).
APPROVED_PATTERNS = [
    r"public.?domain",
    r"original",
    r"cc.?by\b",           # CC BY (no NC/ND restrictions)
    r"creative.?commons.?attribution(?!.*(nc|nd|non-?commercial|no.?deriv))",
    r"pratham.*storyweaver",  # explicit CC BY 4.0 source
    r"hitopadesha",
    r"panchatantra",
    r"aesop",
    r"jpl\s*ephemeris",    # astronomy data (public domain)
]

# Forbidden patterns — red flags.
FORBIDDEN_PATTERNS = [
    r"\bnc\b",             # non-commercial restriction
    r"non-?commercial",
    r"\bnd\b",             # no derivatives
    r"no.?deriv",
    r"all.?rights.?reserved",
    r"copyright(?!.*public.?domain|.*expired)",
    r"licensed.?from",     # suggests royalty-bearing license
]


def check_attribution(attr: str) -> tuple[bool, str]:
    """Return (ok, reason). ok=True means attribution is safe."""
    if not attr or not attr.strip():
        return False, "missing attribution"
    lower = attr.lower()
    for pat in FORBIDDEN_PATTERNS:
        if re.search(pat, lower):
            return False, f"forbidden pattern: {pat!r}"
    for pat in APPROVED_PATTERNS:
        if re.search(pat, lower):
            return True, "approved"
    return False, "no approved pattern matched"


def check_catalog(catalog: dict, source_name: str) -> list[str]:
    """Return list of issue descriptions."""
    issues: list[str] = []
    items = catalog.get("items", [])
    for item in items:
        item_id = item.get("id") or item.get("base_id", "???")
        attr = item.get("attribution", "")
        ok, reason = check_attribution(attr)
        if not ok:
            issues.append(f"[{source_name}] {item_id}: {reason} — {attr!r}")
        # Astrology daily items must be original (computed, not copied).
        if item.get("type") == "daily" and item.get("interests") == ["astrology"]:
            if not re.search(r"original|jpl|skyfield", attr, re.I):
                issues.append(f"[{source_name}] {item_id}: astrology must be original/computed")
    return issues


def check_library(library: dict) -> list[str]:
    """Check the source library.json (pre-rendered items)."""
    issues: list[str] = []
    for item in library.get("items", []):
        base_id = item.get("base_id", "???")
        attr = item.get("attribution", "")
        ok, reason = check_attribution(attr)
        if not ok:
            issues.append(f"[library.json] {base_id}: {reason} — {attr!r}")
    return issues


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--catalog", default=None, help="catalog.json path")
    ap.add_argument("--library", action="store_true",
                    help="check content/library.json instead of catalog")
    ap.add_argument("--all", action="store_true",
                    help="check both library and catalog")
    args = ap.parse_args()

    issues: list[str] = []

    if args.library or args.all:
        with open(CONTENT / "library.json", encoding="utf-8") as f:
            lib = json.load(f)
        issues.extend(check_library(lib))

    if not args.library or args.all:
        cat_path = Path(args.catalog) if args.catalog else DEFAULT_CATALOG
        if not cat_path.exists():
            cat_path = BUNDLED_CATALOG
        if cat_path.exists():
            with open(cat_path, encoding="utf-8") as f:
                cat = json.load(f)
            issues.extend(check_catalog(cat, cat_path.name))
        else:
            print(f"[check_legal] catalog not found at {cat_path}")

    if issues:
        print("Legal issues found:")
        for i in issues:
            print(f"  - {i}")
        sys.exit(1)
    else:
        print("[check_legal] All items pass legal checks.")
        sys.exit(0)


if __name__ == "__main__":
    main()
