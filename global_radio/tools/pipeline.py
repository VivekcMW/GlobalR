"""Shared helpers for the Global Radio content pipeline.

Generates REAL neural-voice MP3s with edge-tts (free Microsoft voices, no API
key) laid out exactly like the production CDN / Cloudflare R2 bucket:

    {out}/{language}/{voiceId}/{itemId}.mp3
    {out}/catalog.json

The Flutter app streams from `{CDN_BASE}/{language}/{voiceId}/{itemId}.mp3`
(see lib/data/models/catalog_item.dart -> audioUrlFor), so anything this script
writes can be served as-is and played with --dart-define=DEMO_AUDIO=false.
"""
from __future__ import annotations

import asyncio
import json
import os
import subprocess
from pathlib import Path

import edge_tts

ROOT = Path(__file__).resolve().parent
CONTENT = ROOT / "content"
DEFAULT_OUT = ROOT.parent / "cdn_dist"

with open(CONTENT / "voices.json", encoding="utf-8") as f:
    VOICES = json.load(f)

LANG_VOICES: dict = VOICES["languages"]       # free Microsoft Edge voices
AZURE_VOICES: dict = VOICES.get("azure", {})  # paid Azure voices (the long tail)
RATES: dict = VOICES["rates"]
NEEDS_PAID_TTS: list = VOICES["needs_paid_tts"]

# Paid Azure Speech is opt-in via env. When the key is set, languages that have
# no free edge voice (odia/punjabi/assamese) render through Azure; otherwise
# they're skipped exactly as before. Free languages always use edge-tts.
AZURE_KEY = os.environ.get("AZURE_SPEECH_KEY")
AZURE_REGION = os.environ.get("AZURE_SPEECH_REGION", "centralindia")


def azure_enabled() -> bool:
    return bool(AZURE_KEY)


def short_code(language: str) -> str:
    return (LANG_VOICES.get(language) or AZURE_VOICES.get(language)
            or {}).get("short", language[:2])


def edge_voice(language: str, preset: str) -> str | None:
    return LANG_VOICES.get(language, {}).get(preset)


def resolve_voice(language: str, preset: str) -> tuple[str | None, str | None]:
    """Pick the backend + voice id for (language, preset). A free edge voice
    always wins; a paid Azure voice is used only for languages with no edge
    voice AND only when AZURE_SPEECH_KEY is set. Returns (None, None) if the
    language can't be rendered right now (so callers skip it)."""
    v = LANG_VOICES.get(language, {}).get(preset)
    if v:
        return ("edge", v)
    av = AZURE_VOICES.get(language, {}).get(preset)
    if av and azure_enabled():
        return ("azure", av)
    return (None, None)


def voice_available(language: str, preset: str) -> bool:
    return resolve_voice(language, preset)[1] is not None


def ffprobe_duration(path: Path) -> int:
    """Return the audio duration in whole seconds (0 on failure)."""
    try:
        out = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "csv=p=0", str(path)],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        return round(float(out))
    except Exception:
        return 0


async def synth(text: str, voice: str, rate: str, out_path: Path) -> None:
    """Free edge-tts backend."""
    out_path.parent.mkdir(parents=True, exist_ok=True)
    communicate = edge_tts.Communicate(text, voice, rate=rate)
    await communicate.save(str(out_path))


def _xml_escape(s: str) -> str:
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
             .replace('"', "&quot;"))


def synth_azure(text: str, voice: str, rate: str, out_path: Path) -> None:
    """Paid Azure Speech backend (REST, no SDK dependency). Used for languages
    edge-tts doesn't cover. Requires AZURE_SPEECH_KEY (+ AZURE_SPEECH_REGION)."""
    import requests  # only needed on the paid path

    out_path.parent.mkdir(parents=True, exist_ok=True)
    locale = "-".join(voice.split("-")[:2]) or "en-US"  # e.g. or-IN-SubhasiniNeural -> or-IN
    ssml = (
        f'<speak version="1.0" xml:lang="{locale}">'
        f'<voice name="{voice}"><prosody rate="{rate}">'
        f'{_xml_escape(text)}</prosody></voice></speak>'
    )
    resp = requests.post(
        f"https://{AZURE_REGION}.tts.speech.microsoft.com/cognitiveservices/v1",
        headers={
            "Ocp-Apim-Subscription-Key": AZURE_KEY,
            "Content-Type": "application/ssml+xml",
            "X-Microsoft-OutputFormat": "audio-24khz-48kbitrate-mono-mp3",
            "User-Agent": "global-radio-pipeline",
        },
        data=ssml.encode("utf-8"),
        timeout=30,
    )
    resp.raise_for_status()
    out_path.write_bytes(resp.content)


def render_item_audio(out_root: Path, language: str, item_id: str,
                      preset: str, text: str) -> dict | None:
    """Render one (language, voice) MP3 via the right backend. Returns
    {durationSec, sizeKb, backend} or None if the language can't be rendered
    (no free voice and no Azure key)."""
    backend, voice = resolve_voice(language, preset)
    if not voice:
        return None
    rate = RATES.get(preset, "+0%")
    dest = out_root / language / preset / f"{item_id}.mp3"
    if backend == "azure":
        synth_azure(text, voice, rate, dest)
    else:
        asyncio.run(synth(text, voice, rate, dest))
    size_kb = max(1, round(dest.stat().st_size / 1024))
    return {"durationSec": ffprobe_duration(dest), "sizeKb": size_kb,
            "backend": backend}


def write_catalog(out_root: Path, version: str, items: list[dict]) -> Path:
    out_root.mkdir(parents=True, exist_ok=True)
    path = out_root / "catalog.json"
    payload = {"version": version, "items": items}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    return path
