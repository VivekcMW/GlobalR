#!/usr/bin/env python3
"""Build one multi-panel illustration per story, via the free Pollinations.ai
image endpoint (no API key, no billing).

For each story spec, splits its English text into N roughly-equal panels,
generates one image per panel (Pollinations.ai), and composites them
side-by-side into a single horizontal-strip JPEG:

    {out}/images/{base_id}.jpg   (N panels, each panel_w x panel_h)

The app windows this single image to whichever panel matches current
playback position (see CatalogItem.imageUrl / imagePanelCount) instead of
downloading N separate files per story.

Images are per base_id (language-independent) and reused across every
language variant of the same story, same as how one story has one set of
titles/text per language but shares this one illustration strip.

Builds are RESUMABLE: an existing {base_id}.jpg is left alone unless
--force is passed. Pollinations.ai's documented anonymous-tier rate limit is
one request every 15s per IP (https://github.com/pollinations/pollinations/
blob/master/APIDOCS.md) — this script enforces that as a hard minimum gap
before every request (not just reactively on 429), plus exponential backoff
on top if a 429 slips through anyway. At ~15-16s/panel, a full run across
every story takes roughly (panels x stories x 16s) — e.g. 134 stories x 4
panels ~= 536 requests ~= 2.3 hours. Safe to Ctrl-C and resume any time.

Usage:
    python tools/build_story_images.py                  # all stories
    python tools/build_story_images.py --limit 5         # pilot run
    python tools/build_story_images.py --category kids
    python tools/build_story_images.py --panels 4 --force
"""
from __future__ import annotations

import argparse
import io
import json
import re
import time
from pathlib import Path

import requests
from PIL import Image

ROOT = Path(__file__).resolve().parent
CONTENT = ROOT / "content"
DEFAULT_OUT = ROOT.parent / "cdn_dist"


def load_library_items() -> list[dict]:
    """Load item specs from content/library.json (legacy) plus every
    content/library/*.json (one file per category). Mirrors pipeline.py's
    loader without pulling in its edge-tts dependency, which this script
    doesn't need."""
    specs: dict[str, dict] = {}
    legacy = CONTENT / "library.json"
    if legacy.exists():
        with open(legacy, encoding="utf-8") as f:
            for it in json.load(f).get("items", []):
                specs[it["base_id"]] = it
    split_dir = CONTENT / "library"
    if split_dir.is_dir():
        for p in sorted(split_dir.glob("*.json")):
            with open(p, encoding="utf-8") as f:
                for it in json.load(f).get("items", []):
                    if it.get("_draft"):
                        continue  # unreviewed ingested drafts never build
                    specs[it["base_id"]] = it
    return list(specs.values())


POLLINATIONS_BASE = "https://image.pollinations.ai/prompt/{prompt}"
PANEL_SIZE = (768, 768)  # per-panel width x height before compositing
MAX_RETRIES = 5
INITIAL_BACKOFF_SEC = 3
# Pollinations.ai anonymous tier: 1 request/15s per IP. Add a 1s safety
# margin — enforced as a hard minimum gap before every request, not just
# reactively after a 429.
MIN_REQUEST_INTERVAL_SEC = 16.0
_last_request_at: float = 0.0


def _throttle() -> None:
    global _last_request_at
    elapsed = time.monotonic() - _last_request_at
    wait = MIN_REQUEST_INTERVAL_SEC - elapsed
    if wait > 0:
        time.sleep(wait)
    _last_request_at = time.monotonic()


def split_into_panels(text: str, n: int) -> list[str]:
    """Split story text into n roughly-equal, sentence-aligned chunks."""
    sentences = [s.strip() for s in re.split(r"(?<=[.!?।])\s+", text) if s.strip()]
    if len(sentences) < n:
        # Not enough sentences to split cleanly — pad by repeating the last.
        sentences += [sentences[-1] if sentences else text] * (n - len(sentences))
    per = max(1, len(sentences) // n)
    chunks = [" ".join(sentences[i * per:(i + 1) * per]) for i in range(n - 1)]
    chunks.append(" ".join(sentences[(n - 1) * per:]))
    return [c if c else text[:200] for c in chunks]


def panel_prompt(title: str, category: str, panel_text: str) -> str:
    """A short, visual, English prompt for one panel (Pollinations.ai works
    best with plain English scene descriptions, not full prose).

    Deliberately avoids the story title and any "book"/"storybook"/"cover"
    framing — those words reliably made the model render garbled fake text,
    as if drawing a book-cover caption. A plain scene description with no
    "book" framing at all doesn't trigger that, confirmed by an A/B test
    (with vs. without an explicit negative prompt — the negative prompt
    made no difference; dropping "picture book" wording did).

    Also strips a short trailing aphorism/blessing sentence (e.g. "Where
    there is a will, there is a way.", "Good morning.") if present — those
    read to the model like an inspirational-quote-graphic caption and it
    tries to render them as literal on-image text. This only affects the
    image prompt, never the story text actually shown/narrated."""
    sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+", panel_text) if s.strip()]
    if len(sentences) > 1 and len(sentences[-1]) <= 80:
        panel_text = " ".join(sentences[:-1])
    snippet = panel_text[:220].replace("\n", " ")
    return (f"a children's illustration, {category} scene: {snippet}, "
            f"warm colors, flat illustration style")


def fetch_panel(prompt: str, size: tuple[int, int]) -> Image.Image:
    url = POLLINATIONS_BASE.format(prompt=requests.utils.quote(prompt))
    params = {"width": size[0], "height": size[1], "nologo": "true"}
    backoff = INITIAL_BACKOFF_SEC
    last_err: Exception | None = None
    for attempt in range(1, MAX_RETRIES + 1):
        _throttle()
        try:
            resp = requests.get(url, params=params, timeout=60)
            if resp.status_code == 200 and resp.headers.get("content-type", "").startswith("image"):
                return Image.open(io.BytesIO(resp.content)).convert("RGB")
            if resp.status_code == 429:
                print(f"    [ratelimit] 429, backing off {backoff}s (attempt {attempt}/{MAX_RETRIES})")
            else:
                print(f"    [warn] status {resp.status_code}, backing off {backoff}s "
                      f"(attempt {attempt}/{MAX_RETRIES})")
        except requests.RequestException as e:
            last_err = e
            print(f"    [warn] {e}, backing off {backoff}s (attempt {attempt}/{MAX_RETRIES})")
        time.sleep(backoff)
        backoff = min(backoff * 2, 60)
    raise RuntimeError(f"Pollinations.ai failed after {MAX_RETRIES} attempts: {last_err}")


def composite_strip(panels: list[Image.Image], size: tuple[int, int]) -> Image.Image:
    strip = Image.new("RGB", (size[0] * len(panels), size[1]))
    for i, panel in enumerate(panels):
        strip.paste(panel.resize(size), (i * size[0], 0))
    return strip


def build_story_image(spec: dict, out_dir: Path, n_panels: int, force: bool,
                       size: tuple[int, int] = PANEL_SIZE) -> dict | None:
    """Returns None if skipped/failed, else {"reused": bool} — caller owns
    recording the manifest entry (this function doesn't know whether an
    existing file at out_path is its own prior AI strip or a Commons photo
    fetch_commons_images.py placed there; main() checks the manifest before
    ever calling this, so reaching here with the file already existing
    means --force was passed)."""
    base_id = spec["base_id"]
    out_path = out_dir / f"{base_id}.jpg"
    if out_path.exists() and not force:
        return {"reused": True}

    text = spec["text"].get("english") or next(iter(spec["text"].values()), "")
    if not text:
        print(f"  [skip] {base_id}: no text in any language")
        return None
    title = spec["titles"].get("english", base_id)
    category = spec["interests"][0] if spec["interests"] else "story"

    chunks = split_into_panels(text, n_panels)
    print(f"  Generating {n_panels} panel(s) for {base_id}...")
    panels = []
    for i, chunk in enumerate(chunks):
        prompt = panel_prompt(title, category, chunk)
        panels.append(fetch_panel(prompt, size))
        print(f"    panel {i + 1}/{n_panels} done")

    strip = composite_strip(panels, size)
    out_dir.mkdir(parents=True, exist_ok=True)
    strip.save(out_path, "JPEG", quality=85)
    return {"reused": False}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--category", default=None, help="only build items tagged with this interest")
    ap.add_argument("--limit", type=int, default=None, help="only build the first N stories (pilot runs)")
    ap.add_argument("--panels", type=int, default=4, help="panels per story strip (default 4)")
    ap.add_argument("--force", action="store_true", help="regenerate even if the image already exists")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    args = ap.parse_args()

    out_root = Path(args.out)
    images_dir = out_root / "images"

    specs = load_library_items()
    if args.category:
        specs = [s for s in specs if args.category in s["interests"]]
    if args.limit:
        specs = specs[: args.limit]

    print(f"Building images for {len(specs)} story/stories -> {images_dir}")

    # Shared per-base_id manifest — also written by fetch_commons_images.py
    # (real photos, panelCount 1). Load first so a base story that already
    # has a Commons photo is skipped entirely rather than treated as if it
    # needs (or already has) an AI strip.
    manifest_path = out_root / "images_manifest.json"
    manifest: dict = {}
    if manifest_path.exists():
        with open(manifest_path, encoding="utf-8") as f:
            manifest = json.load(f)

    built = reused = failed = 0
    for i, spec in enumerate(specs):
        base_id = spec["base_id"]
        if base_id in manifest:
            continue  # already has an image (Commons or a prior AI run)
        print(f"[{i + 1}/{len(specs)}] {base_id}")
        try:
            res = build_story_image(spec, images_dir, args.panels, args.force)
        except RuntimeError as e:
            print(f"  [FAILED] {base_id}: {e}")
            failed += 1
            continue
        if res is None:
            failed += 1
            continue
        manifest[base_id] = {"panelCount": args.panels, "source": "pollinations"}
        built += 0 if res["reused"] else 1
        reused += 1 if res["reused"] else 0

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(f"\nDone: {built} generated, {reused} reused, {failed} failed/skipped")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
