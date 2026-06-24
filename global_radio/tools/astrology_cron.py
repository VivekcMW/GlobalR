#!/usr/bin/env python3
"""Daily astrology generator — the daily-engagement driver.

For a given date it produces, for every zodiac sign x language:
  - a deterministic, original reading (real Moon phase via Skyfield/JPL when
    available; lucky number/colour + theme line chosen by a date+sign hash),
  - real neural audio (edge-tts) at the CDN path
    {lang}/female_warm/astro-{sign}-{short}-{YYYYMMDD}.mp3,
  - a `type:"daily"` catalog entry (with `date` and `sign`).

It merges into the existing catalog.json: library items are kept, daily items
for the SAME date are replaced (idempotent), older daily items are pruned
beyond --keep-days. Designed to run from cron at 00:30 IST.

Usage:
    python tools/astrology_cron.py                         # today, all free-voice langs
    python tools/astrology_cron.py --date 2026-06-24 --langs hindi,english
    python tools/astrology_cron.py --keep-days 3
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path

from pipeline import (AZURE_VOICES, CONTENT, DEFAULT_OUT, LANG_VOICES,
                      render_item_audio, short_code, voice_available)

ASTRO_VOICE = "female_warm"


def moon_phase_key(date: dt.date) -> str:
    """Real Moon phase via Skyfield + JPL ephemeris if available, else a
    well-known synodic approximation (no network needed). Returns one of
    new / waxing / full / waning."""
    try:
        from skyfield.api import Loader
        from skyfield import almanac
        load = Loader(str(Path(__file__).resolve().parent))  # cache de421.bsp in tools/
        ts = load.timescale()
        eph = load("de421.bsp")
        t0 = ts.utc(date.year, date.month, date.day)
        phase = almanac.moon_phase(eph, t0).degrees  # 0=new,90=fq,180=full,270=lq
    except Exception:
        # Synodic approximation: days since a known new moon (2000-01-06).
        ref = dt.date(2000, 1, 6)
        synodic = 29.53058867
        age = (date - ref).days % synodic
        phase = age / synodic * 360.0
    if phase < 45 or phase >= 315:
        return "new"
    if phase < 135:
        return "waxing"
    if phase < 225:
        return "full"
    return "waning"


def pick(seed: str, n: int) -> int:
    return int(hashlib.md5(seed.encode("utf-8")).hexdigest(), 16) % n


def build_reading(tpl: dict, sign_name: str, phase_key: str, seed: str) -> str:
    phase = tpl["phases"][phase_key]
    line = tpl["lines"][pick(seed + "line", len(tpl["lines"]))]
    color = tpl["colors"][pick(seed + "color", len(tpl["colors"]))]
    num = pick(seed + "num", 9) + 1
    parts = [
        tpl["intro"].format(sign=sign_name),
        tpl["moon"].format(phase=phase),
        line,
        tpl["lucky"].format(num=num, color=color),
        tpl["outro"],
    ]
    return " ".join(parts)


def load_catalog(path: Path) -> dict:
    if path.exists():
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return {"version": "init", "items": []}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", default=dt.date.today().isoformat())
    ap.add_argument("--langs", default="")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    ap.add_argument("--keep-days", type=int, default=2,
                    help="prune daily items older than N days")
    ap.add_argument("--notify", action="store_true",
                    help="send an FCM push when the day's items are published")
    ap.add_argument("--notify-dry-run", action="store_true",
                    help="render the push payload without sending (no accounts needed)")
    ap.add_argument("--fcm-credentials", default=None,
                    help="service-account JSON (or env FCM_CREDENTIALS)")
    ap.add_argument("--fcm-project", default=None,
                    help="Firebase project id (or env FCM_PROJECT_ID / key file)")
    args = ap.parse_args()

    date = dt.date.fromisoformat(args.date)
    out_root = Path(args.out)
    with open(CONTENT / "astrology.json", encoding="utf-8") as f:
        astro = json.load(f)
    templates = astro["templates"]
    signs = astro["signs"]

    # Candidate languages: any with a template AND a renderable warm voice
    # (free edge, or paid Azure when AZURE_SPEECH_KEY is set).
    candidates = set(LANG_VOICES) | set(AZURE_VOICES)
    langs = ([l.strip() for l in args.langs.split(",") if l.strip()]
             or [l for l in candidates if l in templates])

    phase_key = moon_phase_key(date)
    ymd = date.strftime("%Y%m%d")
    print(f"Astrology for {date} (moon: {phase_key}) — {len(langs)} langs x {len(signs)} signs")

    new_items: list[dict] = []
    done_langs: list[str] = []
    for language in langs:
        tpl = templates.get(language)
        if not tpl or not voice_available(language, ASTRO_VOICE):
            continue
        for sign in signs:
            sign_name = sign.get(language, sign["en"])
            seed = f"{ymd}-{sign['id']}"
            text = build_reading(tpl, sign_name, phase_key, seed)
            item_id = f"astro-{sign['id']}-{short_code(language)}-{ymd}"
            meta = render_item_audio(out_root, language, item_id, ASTRO_VOICE, text)
            if meta is None:
                continue
            new_items.append({
                "id": item_id,
                "title": f"{sign_name} — {date.isoformat()}",
                "interests": ["astrology"],
                "language": language,
                "availableVoices": [ASTRO_VOICE],
                "defaultVoice": ASTRO_VOICE,
                "durationSec": meta["durationSec"],
                "sizeKb": meta["sizeKb"],
                "attribution": "Original daily reading — Global Radio. Moon phase from JPL ephemeris.",
                "popularity": 60,
                "type": "daily",
                "date": date.isoformat(),
                "sign": sign["id"],
                "publishedDate": date.isoformat(),
                "reachable": True,
            })
        done_langs.append(language)
        print(f"  ✓ {language}: {len(signs)} signs")

    catalog = merge_catalog(out_root, date, new_items, args.keep_days)
    print(f"\nAdded {len(new_items)} daily items; catalog now has "
          f"{len(catalog['items'])} items (version {catalog['version']}).")

    if args.notify or args.notify_dry_run:
        send_daily_push(date, done_langs, args)


def merge_catalog(out_root: Path, date: dt.date, new_items: list[dict],
                  keep_days: int) -> dict:
    """Keep library items + recent daily items (not this date), add new ones,
    prune anything older than keep_days. Idempotent for a given date."""
    catalog_path = out_root / "catalog.json"
    catalog = load_catalog(catalog_path)
    cutoff = date - dt.timedelta(days=max(0, keep_days))
    today = date.isoformat()
    kept = []
    for it in catalog["items"]:
        if it.get("type") == "daily":
            d = it.get("date", "")
            if d == today:
                continue  # replaced below
            if d and dt.date.fromisoformat(d) < cutoff:
                continue  # pruned
        kept.append(it)
    catalog["items"] = kept + new_items
    catalog["version"] = f"{today}-astro"
    with open(catalog_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
    return catalog


def send_daily_push(date: dt.date, langs: list[str], args) -> None:
    """The engagement hook: one broadcast push (english) + one per-language
    push to topic astro_{lang}. Localized copy lives in content/push.json.
    Delegates to notify_fcm, which no-ops cleanly without credentials."""
    import notify_fcm

    with open(CONTENT / "push.json", encoding="utf-8") as f:
        copy = json.load(f)
    fallback = copy.get("english", {"title": "Today's reading is ready",
                                    "body": "Your daily horoscope is in."})

    def push(topic: str, language: str) -> None:
        c = copy.get(language, fallback)
        notify_fcm.send(
            topic, c["title"], c["body"],
            data={"type": "daily_astrology", "date": date.isoformat(),
                  "language": language},
            credentials=args.fcm_credentials, project=args.fcm_project,
            dry_run=args.notify_dry_run,
        )

    push("daily_astrology", "english")  # broadcast nudge
    for language in langs:
        push(f"astro_{language}", language)


if __name__ == "__main__":
    main()
