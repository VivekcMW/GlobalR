#!/usr/bin/env python3
"""FCM push sender — the daily-astrology engagement hook.

Sends a single Firebase Cloud Messaging (HTTP v1) topic message so every device
subscribed to a topic gets the "your daily reading is ready" nudge. Used by
astrology_cron.py after it publishes the day's items.

Design goals (matches the rest of this repo: works locally, degrades cleanly):
  - No hard dependency: if `google-auth` isn't installed or no service-account
    credentials are provided, this NO-OPS with a clear message instead of
    crashing the cron. The catalog still publishes.
  - `--dry-run` prints the exact HTTP v1 payload without sending — so the hook
    is testable with zero accounts.

Auth: a Firebase service-account JSON (Project Settings → Service accounts →
Generate new private key). Point at it with --credentials or env FCM_CREDENTIALS.
The project id is read from the key file (or --project / env FCM_PROJECT_ID).

Topics (clients subscribe by language — see lib/data/services/push_service.dart):
  daily_astrology          all astrology listeners
  astro_{language}         per-language (e.g. astro_hindi)

Usage:
    python tools/notify_fcm.py --topic daily_astrology \
        --title "Aaj ka rashifal" --body "Your daily reading is ready" --dry-run
    # real send:
    python tools/notify_fcm.py --topic astro_hindi --title ... --body ... \
        --credentials serviceAccount.json
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
FCM_ENDPOINT = "https://fcm.googleapis.com/v1/projects/{project}/messages:send"


def _resolve_credentials(path: str | None) -> str | None:
    path = path or os.environ.get("FCM_CREDENTIALS")
    if path and Path(path).is_file():
        return path
    return None


def build_message(topic: str, title: str, body: str,
                  data: dict | None = None) -> dict:
    """The HTTP v1 message body. android/apns blocks make the daily reading a
    high-priority, user-visible notification on both platforms."""
    payload = {
        "message": {
            "topic": topic,
            "notification": {"title": title, "body": body},
            "data": {k: str(v) for k, v in (data or {}).items()},
            "android": {
                "priority": "high",
                "notification": {
                    "channel_id": "daily_astrology",
                    "default_sound": True,
                },
            },
            "apns": {
                "headers": {"apns-priority": "10"},
                "payload": {"aps": {"sound": "default"}},
            },
        }
    }
    return payload


def send(topic: str, title: str, body: str, data: dict | None = None,
         credentials: str | None = None, project: str | None = None,
         dry_run: bool = False) -> bool:
    """Send one topic message. Returns True if sent (or dry-run rendered),
    False if skipped (missing creds/deps). Never raises for the cron's sake."""
    message = build_message(topic, title, body, data)

    if dry_run:
        print("[notify_fcm] DRY RUN — would POST:")
        print(json.dumps(message, ensure_ascii=False, indent=2))
        return True

    cred_path = _resolve_credentials(credentials)
    if not cred_path:
        print("[notify_fcm] skipped: no service-account credentials "
              "(set --credentials or FCM_CREDENTIALS). Catalog still published.")
        return False

    try:
        import google.auth.transport.requests
        from google.oauth2 import service_account
    except ImportError:
        print("[notify_fcm] skipped: `pip install google-auth requests` to enable push.")
        return False

    try:
        creds = service_account.Credentials.from_service_account_file(
            cred_path, scopes=[FCM_SCOPE])
        project_id = project or os.environ.get("FCM_PROJECT_ID") or creds.project_id
        if not project_id:
            print("[notify_fcm] skipped: no project id (set --project / FCM_PROJECT_ID).")
            return False

        request = google.auth.transport.requests.Request()
        creds.refresh(request)

        import requests
        resp = requests.post(
            FCM_ENDPOINT.format(project=project_id),
            headers={
                "Authorization": f"Bearer {creds.token}",
                "Content-Type": "application/json; UTF-8",
            },
            data=json.dumps(message, ensure_ascii=False).encode("utf-8"),
            timeout=20,
        )
        if resp.status_code == 200:
            print(f"[notify_fcm] sent → topic '{topic}' ({resp.json().get('name', 'ok')})")
            return True
        print(f"[notify_fcm] FCM error {resp.status_code}: {resp.text[:300]}")
        return False
    except Exception as exc:  # never break the cron over a push failure
        print(f"[notify_fcm] skipped: {type(exc).__name__}: {exc}")
        return False


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--topic", default="daily_astrology")
    ap.add_argument("--title", required=True)
    ap.add_argument("--body", required=True)
    ap.add_argument("--data", default="", help="k=v,k2=v2 extra data payload")
    ap.add_argument("--credentials", default=None)
    ap.add_argument("--project", default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    data = {}
    for pair in (p for p in args.data.split(",") if p.strip()):
        k, _, v = pair.partition("=")
        data[k.strip()] = v.strip()

    ok = send(args.topic, args.title, args.body, data,
              credentials=args.credentials, project=args.project,
              dry_run=args.dry_run)
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
