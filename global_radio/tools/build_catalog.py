#!/usr/bin/env python3
"""Build the Global Radio library: real neural MP3s + catalog.json.

Reads tools/content/library.json plus every tools/content/library/*.json
(one file per category), synthesises real audio for every
(item x language x voice) into the CDN layout, computes real durations/sizes,
and writes catalog.json. This is the same artifact the app fetches from R2.

Builds are RESUMABLE: existing MP3s are probed and reused, not re-synthesised
(pass --force to regenerate).

Usage:
    python tools/build_catalog.py                      # all languages with free voices
    python tools/build_catalog.py --langs hindi,english
    python tools/build_catalog.py --category kids      # only items tagged 'kids'
    python tools/build_catalog.py --out ../cdn_dist

Then serve cdn_dist/ (see tools/serve_cdn.py) and run the app with
--dart-define=DEMO_AUDIO=false --dart-define=CDN_BASE=... --dart-define=CATALOG_URL=...
"""
from __future__ import annotations

import argparse
import datetime as dt
import json

from pipeline import (CONTENT, DEFAULT_OUT, LANG_VOICES, NEEDS_PAID_TTS,
                      load_library_items, render_batch, short_code,
                      write_catalog)


def build(langs: list[str], out_root, category: str | None = None,
          force: bool = False, concurrency: int = 8) -> list[dict]:
    specs = load_library_items()
    if category:
        specs = [s for s in specs if category in s["interests"]]

    # Phase 1: collect every (item x language x voice) render job.
    jobs: list[tuple] = []
    job_keys: list[tuple] = []  # (spec_idx, language, preset)
    for si, spec in enumerate(specs):
        for language in langs:
            text = spec["text"].get(language)
            if not text:
                continue
            item_id = f"{spec['base_id']}-{short_code(language)}"
            for preset in spec["voices"]:
                jobs.append((out_root, language, item_id, preset, text, force))
                job_keys.append((si, language, preset))

    print(f"Rendering {len(jobs)} audio job(s), {concurrency}-way parallel...")
    results = render_batch(jobs, concurrency=concurrency)

    # Phase 2: fold results back into per-(item, language) catalog entries.
    rendered: dict[tuple, dict] = {}  # (spec_idx, language) -> {preset: res}
    for (si, language, preset), job, res in zip(job_keys, jobs, results):
        if res is None:
            continue
        item_id = job[2]
        mark = "↻" if res.get("reused") else "✓"
        print(f"  {mark} {language}/{preset}/{item_id}.mp3  "
              f"({res['durationSec']}s, {res['sizeKb']}kb)")
        rendered.setdefault((si, language), {})[preset] = res

    items: list[dict] = []
    published = "2026-05-01"
    for (si, language), by_preset in rendered.items():
        spec = specs[si]
        available = [p for p in spec["voices"] if p in by_preset]
        meta = by_preset[available[-1]]  # last voice's stats are representative
        default_voice = spec["defaultVoice"] if spec["defaultVoice"] in available else available[0]
        items.append({
            "id": f"{spec['base_id']}-{short_code(language)}",
            "title": spec["titles"].get(language, spec["base_id"]),
            "interests": spec["interests"],
            "language": language,
            "availableVoices": available,
            "defaultVoice": default_voice,
            "durationSec": meta["durationSec"],
            "sizeKb": meta["sizeKb"],
            "attribution": spec["attribution"],
            "popularity": spec.get("popularity", 50),
            "type": "library",
            "publishedDate": published,
            "reachable": True,
        })
    return items


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--langs", default="", help="comma list; default = all free-voice langs")
    ap.add_argument("--category", default=None,
                    help="only build items tagged with this interest")
    ap.add_argument("--force", action="store_true",
                    help="re-synthesise even if the MP3 already exists")
    ap.add_argument("--concurrency", type=int, default=8,
                    help="parallel TTS renders (default 8)")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    ap.add_argument("--version", default=dt.date.today().isoformat())
    args = ap.parse_args()

    from pathlib import Path
    out_root = Path(args.out)

    if args.langs:
        langs = [l.strip() for l in args.langs.split(",") if l.strip()]
    else:
        langs = list(LANG_VOICES.keys())

    print(f"Building {len(langs)} language(s) -> {out_root}")
    if NEEDS_PAID_TTS:
        print(f"  (skipping {', '.join(NEEDS_PAID_TTS)} — need paid Azure key)")

    items = build(langs, out_root, category=args.category, force=args.force,
                  concurrency=args.concurrency)

    # Merge with any existing catalog items that weren't rebuilt this run
    # (e.g. daily astrology, other categories), keyed by item id.
    existing_path = out_root / "catalog.json"
    if existing_path.exists():
        with open(existing_path, encoding="utf-8") as f:
            existing = {it["id"]: it for it in json.load(f).get("items", [])}
        built_ids = {it["id"] for it in items}
        items = items + [it for iid, it in existing.items() if iid not in built_ids]

    path = write_catalog(out_root, args.version, items)

    langs_done = sorted({it["language"] for it in items})
    print(f"\nWrote {len(items)} items across {len(langs_done)} languages "
          f"({', '.join(langs_done)})")
    print(f"Catalog: {path}  (version {args.version})")


if __name__ == "__main__":
    main()
