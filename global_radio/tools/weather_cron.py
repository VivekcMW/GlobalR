#!/usr/bin/env python3
"""Daily weather bulletins — generated from the free open-meteo API (no key).

Builds one spoken bulletin per language covering that language's major cities
(hindi/english cover the metros), renders audio, and merges `type:"daily"`
items into catalog.json (idempotent per date, pruned by --keep-days).
Degrades cleanly when the API is unreachable.

Usage:
    python tools/weather_cron.py                  # today, hindi+english
    python tools/weather_cron.py --langs hindi
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path

import requests

from pipeline import DEFAULT_OUT, render_item_audio, short_code, voice_available
from gita_verse import merge_daily

METEO_API = "https://api.open-meteo.com/v1/forecast"
VOICE = "female_warm"

CITIES = [
    ("delhi", 28.61, 77.21, {"hindi": "दिल्ली", "english": "Delhi"}),
    ("mumbai", 19.08, 72.88, {"hindi": "मुंबई", "english": "Mumbai"}),
    ("kolkata", 22.57, 88.36, {"hindi": "कोलकाता", "english": "Kolkata"}),
    ("chennai", 13.08, 80.27, {"hindi": "चेन्नई", "english": "Chennai"}),
    ("bengaluru", 12.97, 77.59, {"hindi": "बेंगलुरु", "english": "Bengaluru"}),
    ("hyderabad", 17.38, 78.49, {"hindi": "हैदराबाद", "english": "Hyderabad"}),
]

# WMO weather codes -> spoken condition.
CONDITIONS = {
    "hindi": {
        0: "आसमान साफ़ रहेगा", 1: "मौसम ज़्यादातर साफ़ रहेगा",
        2: "आंशिक बादल छाए रहेंगे", 3: "बादल छाए रहेंगे",
        45: "कोहरा रहेगा", 48: "घना कोहरा रहेगा",
        51: "हल्की बूंदाबांदी हो सकती है", 61: "हल्की बारिश हो सकती है",
        63: "बारिश होगी", 65: "तेज़ बारिश होगी",
        80: "बौछारें पड़ सकती हैं", 95: "गरज के साथ बारिश हो सकती है",
    },
    "english": {
        0: "clear skies", 1: "mostly clear skies",
        2: "partly cloudy skies", 3: "cloudy skies",
        45: "fog", 48: "dense fog",
        51: "light drizzle", 61: "light rain",
        63: "rain", 65: "heavy rain",
        80: "scattered showers", 95: "thunderstorms",
    },
}

TEMPLATES = {
    "hindi": {
        "intro": "नमस्कार, आज का मौसम समाचार।",
        "city": "{city} में {cond}, अधिकतम तापमान {tmax} और न्यूनतम {tmin} डिग्री सेल्सियस।",
        "outro": "अपना ख़याल रखें। यह था आज का मौसम।",
        "title": "आज का मौसम",
    },
    "english": {
        "intro": "Hello, here is today's weather bulletin.",
        "city": "{city} will see {cond}, with a high of {tmax} and a low of {tmin} degrees Celsius.",
        "outro": "Take care, and have a pleasant day. That was today's weather.",
        "title": "Today's Weather",
    },
}


def nearest_condition(code: int, lang: str) -> str:
    table = CONDITIONS[lang]
    if code in table:
        return table[code]
    best = min(table.keys(), key=lambda k: abs(k - code))
    return table[best]


def fetch_forecasts() -> list[tuple[dict, dict]] | None:
    """One batched open-meteo call for all cities."""
    try:
        resp = requests.get(METEO_API, params={
            "latitude": ",".join(str(c[1]) for c in CITIES),
            "longitude": ",".join(str(c[2]) for c in CITIES),
            "daily": "weather_code,temperature_2m_max,temperature_2m_min",
            "timezone": "Asia/Kolkata",
            "forecast_days": 1,
        }, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        payload = data if isinstance(data, list) else [data]
        if len(payload) != len(CITIES):
            print("[weather] unexpected response shape")
            return None
        return list(zip([c[3] for c in CITIES], payload))
    except Exception as e:
        print(f"[weather] fetch failed: {e}")
        return None


def build_bulletin(lang: str, forecasts: list[tuple[dict, dict]]) -> str:
    tpl = TEMPLATES[lang]
    lines = [tpl["intro"]]
    for names, fc in forecasts:
        daily = fc.get("daily", {})
        try:
            code = int(daily["weather_code"][0])
            tmax = round(daily["temperature_2m_max"][0])
            tmin = round(daily["temperature_2m_min"][0])
        except (KeyError, IndexError, TypeError):
            continue
        lines.append(tpl["city"].format(
            city=names[lang], cond=nearest_condition(code, lang),
            tmax=tmax, tmin=tmin))
    lines.append(tpl["outro"])
    return " ".join(lines)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", default=dt.date.today().isoformat())
    ap.add_argument("--langs", default="hindi,english")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    ap.add_argument("--keep-days", type=int, default=2)
    args = ap.parse_args()

    date = dt.date.fromisoformat(args.date)
    out_root = Path(args.out)
    langs = [l.strip() for l in args.langs.split(",")
             if l.strip() in TEMPLATES]

    forecasts = fetch_forecasts()
    if not forecasts:
        print("[weather] API unreachable — skipping today (degraded).")
        return

    ymd = date.strftime("%Y%m%d")
    new_items: list[dict] = []
    for language in langs:
        if not voice_available(language, VOICE):
            continue
        text = build_bulletin(language, forecasts)
        item_id = f"weather-{short_code(language)}-{ymd}"
        meta = render_item_audio(out_root, language, item_id, VOICE, text)
        if meta is None:
            continue
        new_items.append({
            "id": item_id,
            "title": f"{TEMPLATES[language]['title']} — {date.isoformat()}",
            "interests": ["news"],
            "language": language,
            "availableVoices": [VOICE],
            "defaultVoice": VOICE,
            "durationSec": meta["durationSec"],
            "sizeKb": meta["sizeKb"],
            "attribution": "Weather data: open-meteo.com (CC BY 4.0). "
                           "Bulletin script original — Global Radio.",
            "popularity": 62,
            "type": "daily",
            "date": date.isoformat(),
            "publishedDate": date.isoformat(),
            "reachable": True,
        })
        print(f"  ✓ {language}: {item_id} ({meta['durationSec']}s)")

    if new_items:
        catalog = merge_daily(out_root, date, "weather-", new_items,
                              args.keep_days, "weather")
        print(f"Added {len(new_items)} weather items; catalog now "
              f"{len(catalog['items'])} items.")
    else:
        print("[weather] nothing rendered.")


if __name__ == "__main__":
    main()
