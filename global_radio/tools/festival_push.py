#!/usr/bin/env python3
"""Engagement push cron: festival day-of pushes + rashi win-back nudges.

Two subcommands, both built on notify_fcm.send() (same no-op-without-creds
behavior, same --dry-run testability):

  festival   Check assets/catalog/festivals.json for festivals happening
             *today* and push one celebratory message per festival to the
             per-language astro topics (astro_{language}) plus the general
             daily_astrology topic. Run daily at ~08:00 IST after
             astrology_cron.py.

  winback    Rashi-based win-back copy generator. FCM topics can't target
             "inactive 7 days" — that segmentation lives in the Firebase
             console (Messaging → New campaign → audience "last app open
             > 7 days ago"). This subcommand prints today's suggested
             rashi-flavoured copy for that campaign, or sends it to the
             astro_{language} topics with --send-topics for projects without
             console access.

Usage:
    python tools/festival_push.py festival --dry-run
    python tools/festival_push.py festival --credentials serviceAccount.json
    python tools/festival_push.py winback                 # print copy only
    python tools/festival_push.py winback --send-topics --dry-run
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path

import notify_fcm

ROOT = Path(__file__).resolve().parent.parent
FESTIVALS_JSON = ROOT / "assets" / "catalog" / "festivals.json"

# Languages with astro_{language} topics (mirrors push_service.dart).
LANGUAGES = [
    "hindi", "tamil", "telugu", "kannada", "malayalam",
    "bengali", "marathi", "gujarati", "urdu", "english",
]

WINBACK_LINES = [
    "Your rashi has been waiting for you 🌙 Today's reading is ready.",
    "The stars moved while you were away ✨ See what changed for your rashi.",
    "Missed a few days? Your rashi's fresh reading takes just 2 minutes 🎧",
]


def todays_festivals(today: dt.date) -> list[dict]:
    data = json.loads(FESTIVALS_JSON.read_text(encoding="utf-8"))
    hits = []
    for f in data.get("festivals", []):
        for d in f.get("dates", []):
            try:
                if dt.date.fromisoformat(d) == today:
                    hits.append(f)
                    break
            except ValueError:
                continue
    return hits


def push_festivals(args: argparse.Namespace) -> int:
    today = dt.date.fromisoformat(args.date) if args.date else dt.date.today()
    festivals = todays_festivals(today)
    if not festivals:
        print(f"[festival_push] no festivals on {today} — nothing to send.")
        return 0

    sent = 0
    for f in festivals:
        icon = f.get("icon", "🎉")
        name = f.get("name", f.get("id", "Festival"))
        regional = f.get("names_regional", {})
        data = {"type": "festival", "festival_id": f.get("id", "")}
        # General topic: English copy.
        title = f"{icon} Happy {name}!"
        body = "Join the live festival station — special stories and bhajans all day."
        if notify_fcm.send("daily_astrology", title, body, data,
                           credentials=args.credentials, project=args.project,
                           dry_run=args.dry_run):
            sent += 1
        # Per-language topics: use the regional festival name when we have it.
        for lang in LANGUAGES:
            local_name = regional.get(lang, name)
            if notify_fcm.send(f"astro_{lang}", f"{icon} {local_name}", body,
                               data, credentials=args.credentials,
                               project=args.project, dry_run=args.dry_run):
                sent += 1
    print(f"[festival_push] done — {sent} message(s) for {len(festivals)} festival(s).")
    return 0


def push_winback(args: argparse.Namespace) -> int:
    today = dt.date.fromisoformat(args.date) if args.date else dt.date.today()
    line = WINBACK_LINES[today.toordinal() % len(WINBACK_LINES)]
    print("[festival_push] today's win-back copy:")
    print(f"  title: We miss you at Global Radio")
    print(f"  body:  {line}")
    if not args.send_topics:
        print("[festival_push] (copy only — use the Firebase console inactive-user "
              "audience for real win-back targeting, or pass --send-topics)")
        return 0
    sent = 0
    for lang in LANGUAGES:
        if notify_fcm.send(f"astro_{lang}", "We miss you at Global Radio", line,
                           {"type": "winback"}, credentials=args.credentials,
                           project=args.project, dry_run=args.dry_run):
            sent += 1
    print(f"[festival_push] done — {sent} win-back message(s).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    for name, fn in (("festival", push_festivals), ("winback", push_winback)):
        p = sub.add_parser(name)
        p.add_argument("--date", help="Override today (YYYY-MM-DD) for testing")
        p.add_argument("--credentials", help="Firebase service-account JSON")
        p.add_argument("--project", help="Firebase project id override")
        p.add_argument("--dry-run", action="store_true")
        if name == "winback":
            p.add_argument("--send-topics", action="store_true",
                           help="Send to astro_* topics instead of printing copy")
        p.set_defaults(fn=fn)
    args = parser.parse_args()
    return args.fn(args)


if __name__ == "__main__":
    raise SystemExit(main())
