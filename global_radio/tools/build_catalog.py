#!/usr/bin/env python3
"""Build the Global Radio library: real neural MP3s + catalog.json.

Reads tools/content/library.json, synthesises real audio for every
(item x language x voice) into the CDN layout, computes real durations/sizes,
and writes catalog.json. This is the same artifact the app fetches from R2.

Usage:
    python tools/build_catalog.py                      # all languages with free voices
    python tools/build_catalog.py --langs hindi,english
    python tools/build_catalog.py --out ../cdn_dist

Then serve cdn_dist/ (see tools/serve_cdn.py) and run the app with
--dart-define=DEMO_AUDIO=false --dart-define=CDN_BASE=... --dart-define=CATALOG_URL=...
"""
from __future__ import annotations

import argparse
import datetime as dt
import json

from pipeline import (CONTENT, DEFAULT_OUT, LANG_VOICES, NEEDS_PAID_TTS,
                      render_item_audio, short_code, write_catalog)


def build(langs: list[str], out_root) -> list[dict]:
    with open(CONTENT / "library.json", encoding="utf-8") as f:
        library = json.load(f)

    items: list[dict] = []
    published = "2026-05-01"
    for spec in library["items"]:
        base_id = spec["base_id"]
        for language in langs:
            text = spec["text"].get(language)
            if not text:
                continue
            item_id = f"{base_id}-{short_code(language)}"
            available: list[str] = []
            meta = {"durationSec": 0, "sizeKb": 0}
            for preset in spec["voices"]:
                res = render_item_audio(out_root, language, item_id, preset, text)
                if res is None:
                    continue
                available.append(preset)
                meta = res  # last voice's stats are representative
                print(f"  ✓ {language}/{preset}/{item_id}.mp3  "
                      f"({res['durationSec']}s, {res['sizeKb']}kb)")
            if not available:
                continue
            default_voice = spec["defaultVoice"] if spec["defaultVoice"] in available else available[0]
            items.append({
                "id": item_id,
                "title": spec["titles"].get(language, base_id),
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

    items = build(langs, out_root)
    path = write_catalog(out_root, args.version, items)

    langs_done = sorted({it["language"] for it in items})
    print(f"\nWrote {len(items)} items across {len(langs_done)} languages "
          f"({', '.join(langs_done)})")
    print(f"Catalog: {path}  (version {args.version})")


if __name__ == "__main__":
    main()
