#!/usr/bin/env python3
"""Daily Bhagavad Gita verse — devotional daily-engagement content.

Picks a deterministic verse-of-the-day (date-hashed across all 700 shlokas),
fetches Sanskrit + public-domain English translation (Swami Sivananda, d. 1963
— public domain in India) from the free static vedicscriptures API, renders
devotional-voice audio for hindi + english, and merges `type:"daily"` items
into catalog.json (idempotent per date; old verses pruned).

The Hindi rendering is machine-translated from the PD English translation and
labelled as such. Degrades cleanly when the API is unreachable (no items).

Usage:
    python tools/gita_verse.py                    # today
    python tools/gita_verse.py --date 2026-07-04 --keep-days 3
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path

import requests

from pipeline import DEFAULT_OUT, render_item_audio, short_code, voice_available

GITA_API = "https://vedicscriptures.github.io/slok"
VOICE = "devotional"

# Verses per chapter (18 chapters, 700 shlokas).
CHAPTER_VERSES = [47, 72, 43, 42, 29, 47, 30, 28, 34, 42,
                  55, 20, 35, 27, 20, 24, 28, 78]
TOTAL = sum(CHAPTER_VERSES)


def verse_of_day(date: dt.date) -> tuple[int, int]:
    """Deterministic (chapter, verse) for the date."""
    n = int(hashlib.md5(date.isoformat().encode()).hexdigest(), 16) % TOTAL
    for ch, count in enumerate(CHAPTER_VERSES, start=1):
        if n < count:
            return ch, n + 1
        n -= count
    return 2, 47  # unreachable; karmanye vadhikaraste as a safe default


def fetch_verse(ch: int, v: int) -> dict | None:
    try:
        resp = requests.get(f"{GITA_API}/{ch}/{v}", timeout=30)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print(f"[gita] fetch failed for {ch}.{v}: {e}")
        return None


def translate_to_hindi(english: str) -> str | None:
    try:
        from deep_translator import GoogleTranslator
        return GoogleTranslator(source="en", target="hi").translate(english)
    except Exception as e:
        print(f"[gita] hindi translation degraded: {e}")
        return None


def build_texts(data: dict, ch: int, v: int) -> dict[str, str]:
    """Compose narration text per language."""
    shloka = (data.get("slok") or "").replace("\n", " ").strip()
    english_trans = ((data.get("siva") or {}).get("et") or "").strip()
    texts: dict[str, str] = {}
    if shloka and english_trans:
        texts["english"] = (
            f"Today's Bhagavad Gita verse, chapter {ch}, verse {v}. "
            f"{shloka} — Meaning: {english_trans} "
            "May this verse guide your day.")
        hindi_trans = translate_to_hindi(english_trans)
        if hindi_trans:
            texts["hindi"] = (
                f"आज का गीता श्लोक, अध्याय {ch}, श्लोक {v}। "
                f"{shloka} — अर्थ: {hindi_trans} "
                "यह श्लोक आपके दिन को दिशा दे।")
    return texts


def merge_daily(out_root: Path, date: dt.date, prefix: str,
                new_items: list[dict], keep_days: int, tag: str) -> dict:
    """Merge daily items into catalog.json touching ONLY ids with `prefix`
    (astro/news items from other crons are left alone). Idempotent."""
    catalog_path = out_root / "catalog.json"
    if catalog_path.exists():
        with open(catalog_path, encoding="utf-8") as f:
            catalog = json.load(f)
    else:
        catalog = {"version": "init", "items": []}
    cutoff = (date - dt.timedelta(days=max(0, keep_days))).isoformat()
    new_ids = {it["id"] for it in new_items}
    kept = []
    for it in catalog["items"]:
        if it["id"] in new_ids:
            continue  # replaced
        if (it.get("type") == "daily" and it["id"].startswith(prefix)
                and it.get("date", "9999") < cutoff):
            continue  # pruned
        kept.append(it)
    catalog["items"] = kept + new_items
    catalog["version"] = f"{date.isoformat()}-{tag}"
    with open(catalog_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
    return catalog


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", default=dt.date.today().isoformat())
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    ap.add_argument("--keep-days", type=int, default=7)
    args = ap.parse_args()

    date = dt.date.fromisoformat(args.date)
    out_root = Path(args.out)
    ch, v = verse_of_day(date)
    print(f"Gita verse of the day for {date}: {ch}.{v}")

    data = fetch_verse(ch, v)
    if not data:
        print("[gita] API unreachable — skipping today (degraded).")
        return

    texts = build_texts(data, ch, v)
    ymd = date.strftime("%Y%m%d")
    new_items: list[dict] = []
    titles = {"hindi": f"आज का गीता श्लोक {ch}.{v}",
              "english": f"Gita Verse of the Day {ch}.{v}"}
    for language, text in texts.items():
        if not voice_available(language, VOICE):
            continue
        item_id = f"gita-{ch}-{v}-{short_code(language)}-{ymd}"
        meta = render_item_audio(out_root, language, item_id, VOICE, text)
        if meta is None:
            continue
        attribution = ("Bhagavad Gita (ancient Sanskrit, public domain). "
                       "English translation: Swami Sivananda (public domain).")
        if language == "hindi":
            attribution += " Hindi rendering machine-translated from the PD English."
        new_items.append({
            "id": item_id,
            "title": titles[language],
            "interests": ["devotion"],
            "language": language,
            "availableVoices": [VOICE],
            "defaultVoice": VOICE,
            "durationSec": meta["durationSec"],
            "sizeKb": meta["sizeKb"],
            "attribution": attribution,
            "popularity": 65,
            "type": "daily",
            "date": date.isoformat(),
            "publishedDate": date.isoformat(),
            "reachable": True,
        })
        print(f"  ✓ {language}: {item_id} ({meta['durationSec']}s)")

    if new_items:
        catalog = merge_daily(out_root, date, "gita-", new_items,
                              args.keep_days, "gita")
        print(f"Added {len(new_items)} verse items; catalog now "
              f"{len(catalog['items'])} items.")
    else:
        print("[gita] nothing rendered.")


if __name__ == "__main__":
    main()
