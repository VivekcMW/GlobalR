#!/usr/bin/env python3
"""Fetch a real, appropriately-licensed photo for non-fiction content,
instead of an AI-generated illustration.

Scoped to NON_FICTION_LIBRARY_FILES: scraped.json (Wikisource/Wikipedia
harvested biographies, historical events, festivals — real people/places,
so a real photo is both more accurate and easier to source than an AI
reinterpretation) plus devotion.json and finance.json (hand-written but
factual explainer/devotional content — no invented characters, even though
a Wikipedia topic search often won't have a specific real-world subject to
match against). The hand-written fictional catalog (kids/moral/fairytales/
bedtime/folklore — invented characters) is deliberately excluded and always
gets the AI illustration strip from build_story_images.py, since a "real
photo" of a fictional character doesn't make sense.

For any non-fiction item this script can't find a license-clear match for
(most devotion/finance items, or a scraped biography Wikipedia has no
image for), it falls through silently and leaves it for
build_story_images.py's AI illustration step, which runs after this one
and is resumable (skips anything that already has an image) — so nothing
ships without an image, real photos are just preferred where findable.

Uses Wikipedia's `pageimages` API (a topic's curated infobox thumbnail),
NOT raw Wikimedia Commons full-text search. An earlier version tried
Commons search directly and got confident-looking but wrong matches — e.g.
searching "Candlemas" (the religious holiday) top-matched a satellite photo
of "Candlemas Islands" (a real but unrelated place in the South Atlantic).
Both share the literal word "Candlemas", so a keyword search can't tell
them apart; Wikipedia's own topic-to-thumbnail mapping already encodes
that disambiguation because it's tied to the actual matching article.

Writes a single hero image (not a multi-panel strip) to
{out}/images/{base_id}.jpg, and records {base_id: {"panelCount": 1,
"source": "commons", "attribution": "..."}} in {out}/images_manifest.json
so build_catalog.py can emit the right imagePanelCount (1, not the AI
strip's 4) and fold the photographer/license into the item's existing
`attribution` field.

Falls through silently (does nothing) for any base story Wikipedia has no
matching article/image for. build_story_images.py's AI illustration step
already runs after this one and is resumable (skips anything that already
has an image), so it picks up whatever this script couldn't find.

Usage:
    python tools/fetch_commons_images.py
    python tools/fetch_commons_images.py --limit 10
    python tools/fetch_commons_images.py --out ../cdn_dist
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
DEFAULT_OUT = ROOT.parent / "cdn_dist"
NON_FICTION_LIBRARY_FILES = ("scraped.json", "devotion.json", "finance.json")

WIKIPEDIA_API = "https://en.wikipedia.org/w/api.php"
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
USER_AGENT = "GlobalRadioContentPipeline/1.0 (contact: prince11jose@gmail.com)"
HEADERS = {"User-Agent": USER_AGENT}

# Commons' extmetadata.LicenseShortName values we're comfortable using
# without further review (all permit reuse; some require attribution,
# which we already fold into `attribution`). Deliberately excludes
# anything ambiguous (e.g. "No restrictions known" — a red flag, not a
# clear license) or requiring non-commercial/no-derivatives terms.
ALLOWED_LICENSE_SUBSTRINGS = (
    "public domain", "pd-", "cc0",
    "cc-by-sa", "cc-by ", "cc by-sa", "cc by ",
)
MIN_DIMENSION = 400
REQUEST_DELAY_SEC = 1.0


def search_query_for(title: str) -> str:
    """Encyclopedia-style titles look like "1911 Encyclopædia Britannica/
    Candlemas" — the part after the last '/' is the actual topic."""
    topic = title.rsplit("/", 1)[-1]
    return re.sub(r"\s+", " ", topic).strip()


def _throttle(last_call: list[float]) -> None:
    elapsed = time.monotonic() - last_call[0]
    if elapsed < REQUEST_DELAY_SEC:
        time.sleep(REQUEST_DELAY_SEC - elapsed)
    last_call[0] = time.monotonic()


def find_wikipedia_pageimage(query: str, last_call: list[float]) -> dict | None:
    """Find the best-matching Wikipedia article for `query` and its curated
    infobox thumbnail filename (not yet license-checked — that's a separate
    Commons lookup, since Wikipedia's own API doesn't expose license)."""
    _throttle(last_call)
    try:
        resp = requests.get(WIKIPEDIA_API, headers=HEADERS, timeout=20, params={
            "action": "query", "generator": "search", "gsrsearch": query,
            "gsrlimit": 1, "prop": "pageimages", "piprop": "name",
            "format": "json",
        })
        pages = resp.json().get("query", {}).get("pages", {})
    except (requests.RequestException, ValueError):
        return None
    for page in pages.values():
        filename = page.get("pageimage")
        if filename:
            return {"filename": filename, "article_title": page.get("title", query)}
    return None


def check_license_and_get_url(filename: str, last_call: list[float]) -> dict | None:
    _throttle(last_call)
    try:
        resp = requests.get(COMMONS_API, headers=HEADERS, timeout=20, params={
            "action": "query", "titles": f"File:{filename}", "prop": "imageinfo",
            "iiprop": "url|extmetadata|size", "format": "json",
        })
        pages = resp.json().get("query", {}).get("pages", {})
    except (requests.RequestException, ValueError):
        return None
    for page in pages.values():
        infos = page.get("imageinfo")
        if not infos:
            continue
        info = infos[0]
        if info.get("width", 0) < MIN_DIMENSION or info.get("height", 0) < MIN_DIMENSION:
            return None
        meta = info.get("extmetadata", {})
        license_name = (meta.get("LicenseShortName", {}).get("value") or "").lower()
        if not any(s in license_name for s in ALLOWED_LICENSE_SUBSTRINGS):
            return None
        artist_html = meta.get("Artist", {}).get("value", "")
        artist = re.sub(r"<[^>]+>", "", artist_html).strip() or "Unknown"
        return {
            "url": info["url"],
            "license": meta.get("LicenseShortName", {}).get("value", "Unknown license"),
            "artist": artist,
        }
    return None


def find_real_image(title: str, last_call: list[float]) -> dict | None:
    query = search_query_for(title)
    match = find_wikipedia_pageimage(query, last_call)
    if match is None:
        return None
    licensed = check_license_and_get_url(match["filename"], last_call)
    if licensed is None:
        return None
    return {**licensed, "article_title": match["article_title"], "filename": match["filename"]}


def download_image(url: str) -> Image.Image:
    resp = requests.get(url, headers=HEADERS, timeout=30)
    resp.raise_for_status()
    return Image.open(io.BytesIO(resp.content)).convert("RGB")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None, help="only process the first N stories (testing)")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    args = ap.parse_args()

    out_root = Path(args.out)
    images_dir = out_root / "images"
    manifest_path = out_root / "images_manifest.json"

    library_dir = ROOT / "content" / "library"
    specs: dict[str, dict] = {}
    for filename in NON_FICTION_LIBRARY_FILES:
        path = library_dir / filename
        if not path.exists():
            continue
        with open(path, encoding="utf-8") as f:
            for item in json.load(f).get("items", []):
                if item.get("_draft"):
                    continue  # unreviewed ingested drafts never build
                specs[item["base_id"]] = item
    specs = list(specs.values())
    if not specs:
        print("No non-fiction library files found yet — nothing to do.")
        return
    if args.limit:
        specs = specs[: args.limit]

    manifest: dict = {}
    if manifest_path.exists():
        with open(manifest_path, encoding="utf-8") as f:
            manifest = json.load(f)

    last_call = [0.0]
    found = 0
    for i, spec in enumerate(specs):
        base_id = spec["base_id"]
        if base_id in manifest:
            continue  # already has an image (Commons or AI) — resumable

        title = spec["titles"].get("english", base_id)
        print(f"[{i + 1}/{len(specs)}] {base_id} -> Wikipedia topic: \"{search_query_for(title)}\"")

        result = find_real_image(title, last_call)
        if result is None:
            print("  no license-clear match — leaving for AI illustration fallback")
            continue

        try:
            img = download_image(result["url"])
        except (requests.RequestException, OSError) as e:
            print(f"  [warn] download failed: {e}")
            continue

        images_dir.mkdir(parents=True, exist_ok=True)
        out_path = images_dir / f"{base_id}.jpg"
        img.save(out_path, "JPEG", quality=90)
        manifest[base_id] = {
            "panelCount": 1,
            "source": "commons",
            "attribution": (f"Photo: {result['artist']} — {result['license']}, "
                             f"via Wikimedia Commons (from Wikipedia: {result['article_title']})"),
        }
        found += 1
        print(f"  found: {result['article_title']} -> {result['filename']} ({result['license']})")

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(f"\n{found} real photo(s) found out of {len(specs)} scraped stories checked.")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
