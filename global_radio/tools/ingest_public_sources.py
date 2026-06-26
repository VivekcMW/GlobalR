#!/usr/bin/env python3
"""
Public Audio Content Ingestion Pipeline for Global Radio

Sources:
  1. LibriVox - Public domain audiobooks (CC0/Public Domain)
  2. Internet Archive - Diverse audio content (various CC licenses)
  3. Wikimedia Commons - Educational audio (CC licenses)

Outputs catalog-compatible items to cdn_dist/ structure:
    cdn_dist/{language}/{voice}/{item_id}.mp3
    cdn_dist/catalog.json (updated with new items)

Usage:
    python ingest_public_sources.py --source librivox --language hindi --limit 10
    python ingest_public_sources.py --source archive --collection indian_languages
    python ingest_public_sources.py --verify-health   # Check all URLs still work
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import quote, urljoin

import requests

ROOT = Path(__file__).resolve().parent
CDN_DIST = ROOT.parent / "cdn_dist"
CONTENT = ROOT / "content"
INGEST_CACHE = ROOT / ".ingest_cache"
INGEST_CACHE.mkdir(exist_ok=True)

# API endpoints
LIBRIVOX_API = "https://librivox.org/api/feed/audiobooks"
ARCHIVE_API = "https://archive.org/advancedsearch.php"
ARCHIVE_METADATA = "https://archive.org/metadata"
ARCHIVE_DOWNLOAD = "https://archive.org/download"

# Language mappings (ISO 639-1 to our catalog format)
LANG_MAP = {
    "hi": "hindi",
    "en": "english",
    "bn": "bengali",
    "mr": "marathi",
    "te": "telugu",
    "ta": "tamil",
    "kn": "kannada",
    "ml": "malayalam",
    "gu": "gujarati",
    "ur": "urdu",
    "pa": "punjabi",
    "or": "odia",
    "as": "assamese",
}

# Reverse mapping
LANG_CODES = {v: k for k, v in LANG_MAP.items()}

# Interest classification keywords
INTEREST_KEYWORDS = {
    "kids": ["children", "child", "kids", "fairy", "fable", "nursery", "bedtime"],
    "moral": ["moral", "fable", "aesop", "panchatantra", "jataka", "story", "tale"],
    "devotion": ["devotion", "prayer", "religious", "spiritual", "bhajan", "kirtan", "hymn"],
    "mythology": ["mythology", "epic", "ramayana", "mahabharata", "purana", "legend"],
    "education": ["education", "science", "history", "biography", "documentary"],
}


@dataclass
class IngestedItem:
    """A single audio item ready for the catalog."""
    id: str
    title: str
    interests: list[str]
    language: str
    source_url: str  # Original source URL for attribution
    download_url: str  # Direct download URL
    duration_sec: int = 0
    size_kb: int = 0
    attribution: str = ""
    license: str = "Public Domain"
    popularity: int = 50
    type: str = "library"
    reachable: bool = True
    local_path: Path | None = None

    def to_catalog_item(self, voice: str = "original") -> dict:
        """Convert to catalog.json format."""
        return {
            "id": self.id,
            "title": self.title,
            "interests": self.interests,
            "language": self.language,
            "availableVoices": [voice],
            "defaultVoice": voice,
            "durationSec": self.duration_sec,
            "sizeKb": self.size_kb,
            "attribution": self.attribution,
            "popularity": self.popularity,
            "type": self.type,
            "publishedDate": datetime.now().strftime("%Y-%m-%d"),
            "reachable": self.reachable,
            "sourceUrl": self.source_url,
        }


class LibriVoxIngester:
    """Ingest audiobooks from LibriVox API."""

    def __init__(self, language: str = "english"):
        self.language = language
        self.lang_code = LANG_CODES.get(language, "en")

    def search(self, limit: int = 20, genre: str | None = None) -> list[dict]:
        """Search LibriVox for audiobooks in the target language."""
        params = {
            "format": "json",
            "limit": limit,
        }
        if genre:
            params["genre"] = genre

        try:
            resp = requests.get(LIBRIVOX_API, params=params, timeout=30)
            resp.raise_for_status()
            data = resp.json()
            return data.get("books", [])
        except Exception as e:
            print(f"[LibriVox] Search failed: {e}")
            return []

    def ingest_book(self, book: dict) -> list[IngestedItem]:
        """Extract chapters from a LibriVox book as individual items."""
        items = []
        book_id = book.get("id", "")
        book_title = book.get("title", "Unknown")
        authors = book.get("authors", [])
        author_name = authors[0].get("last_name", "Unknown") if authors else "Unknown"

        # Get individual chapter files from RSS or direct links
        url_librivox = book.get("url_librivox", "")
        url_zip_file = book.get("url_zip_file", "")

        # Classify interests based on title and description
        interests = self._classify_interests(book_title, book.get("description", ""))

        # Create a single item for the whole book (simplified for quick launch)
        if url_zip_file:
            item_id = f"librivox-{book_id}-{self.language}"
            item = IngestedItem(
                id=item_id,
                title=book_title,
                interests=interests or ["education"],
                language=self.language,
                source_url=url_librivox or f"https://librivox.org/search?primary_key={book_id}",
                download_url=url_zip_file,
                attribution=f"LibriVox ({author_name}) — Public Domain",
                license="Public Domain",
                duration_sec=int(book.get("totaltimesecs", 0)),
                popularity=60,
            )
            items.append(item)

        return items

    def _classify_interests(self, title: str, description: str) -> list[str]:
        """Classify content into interest categories."""
        text = f"{title} {description}".lower()
        matched = []
        for interest, keywords in INTEREST_KEYWORDS.items():
            if any(kw in text for kw in keywords):
                matched.append(interest)
        return matched[:3] if matched else ["education"]


class InternetArchiveIngester:
    """Ingest audio from Internet Archive collections."""

    INDIAN_COLLECTIONS = [
        "hindi_audio",
        "indian_languages",
        "audio_bookspoetry",
        "librivoxaudio",
        "audio_religion",
    ]

    def __init__(self, language: str = "hindi"):
        self.language = language

    def search(
        self,
        collection: str | None = None,
        query: str | None = None,
        limit: int = 50,
    ) -> list[dict]:
        """Search Internet Archive for audio content."""
        collections = [collection] if collection else self.INDIAN_COLLECTIONS

        all_items = []
        for coll in collections:
            params = {
                "q": f"collection:{coll} AND mediatype:audio",
                "fl[]": ["identifier", "title", "description", "creator", "licenseurl"],
                "rows": min(limit, 100),
                "output": "json",
            }
            if query:
                params["q"] = f"{params['q']} AND ({query})"

            try:
                resp = requests.get(ARCHIVE_API, params=params, timeout=30)
                resp.raise_for_status()
                data = resp.json()
                docs = data.get("response", {}).get("docs", [])
                all_items.extend(docs)
                if len(all_items) >= limit:
                    break
            except Exception as e:
                print(f"[Archive] Search failed for {coll}: {e}")

        return all_items[:limit]

    def get_audio_files(self, identifier: str) -> list[dict]:
        """Get audio files for an Archive item."""
        try:
            resp = requests.get(f"{ARCHIVE_METADATA}/{identifier}", timeout=30)
            resp.raise_for_status()
            data = resp.json()
            files = data.get("files", [])
            # Filter for audio files
            audio_files = [
                f for f in files
                if f.get("format", "").lower() in ("mp3", "vbr mp3", "ogg vorbis", "flac")
                or f.get("name", "").lower().endswith((".mp3", ".ogg", ".flac"))
            ]
            return audio_files
        except Exception as e:
            print(f"[Archive] Failed to get files for {identifier}: {e}")
            return []

    def ingest_item(self, doc: dict) -> list[IngestedItem]:
        """Convert an Archive item to catalog items."""
        items = []
        identifier = doc.get("identifier", "")
        title = doc.get("title", "Unknown")
        creator = doc.get("creator", "Unknown")
        description = doc.get("description", "")
        license_url = doc.get("licenseurl", "")

        # Determine license type
        license_type = "Public Domain"
        if "creativecommons" in str(license_url).lower():
            if "by-sa" in license_url:
                license_type = "CC BY-SA"
            elif "by-nc" in license_url:
                license_type = "CC BY-NC"
            elif "by" in license_url:
                license_type = "CC BY"

        # Get audio files
        audio_files = self.get_audio_files(identifier)
        interests = self._classify_interests(title, description)

        for i, audio in enumerate(audio_files[:5]):  # Limit to 5 per item
            file_name = audio.get("name", "")
            file_title = audio.get("title", file_name.replace(".mp3", "").replace("_", " "))

            item_id = f"archive-{identifier}-{i}-{self.language}"
            download_url = f"{ARCHIVE_DOWNLOAD}/{identifier}/{quote(file_name)}"

            # Get duration and size
            duration = 0
            try:
                length = audio.get("length", "0")
                if ":" in str(length):
                    parts = str(length).split(":")
                    duration = sum(int(p) * (60 ** (len(parts) - 1 - i)) for i, p in enumerate(parts))
                else:
                    duration = int(float(length))
            except (ValueError, TypeError):
                pass

            size_kb = int(float(audio.get("size", 0)) / 1024)

            item = IngestedItem(
                id=item_id,
                title=f"{title} - {file_title}" if len(audio_files) > 1 else title,
                interests=interests or ["education"],
                language=self.language,
                source_url=f"https://archive.org/details/{identifier}",
                download_url=download_url,
                attribution=f"Internet Archive ({creator}) — {license_type}",
                license=license_type,
                duration_sec=duration,
                size_kb=size_kb,
                popularity=50,
            )
            items.append(item)

        return items

    def _classify_interests(self, title: str, description: str) -> list[str]:
        """Classify content into interest categories."""
        text = f"{title} {description}".lower()
        matched = []
        for interest, keywords in INTEREST_KEYWORDS.items():
            if any(kw in text for kw in keywords):
                matched.append(interest)
        return matched[:3] if matched else ["education"]


class HealthChecker:
    """Verify audio URLs are still reachable."""

    def __init__(self, timeout: int = 10):
        self.timeout = timeout

    def check_url(self, url: str) -> tuple[bool, int]:
        """Check if URL is reachable. Returns (success, http_status)."""
        try:
            resp = requests.head(url, timeout=self.timeout, allow_redirects=True)
            return resp.status_code == 200, resp.status_code
        except Exception:
            return False, 0

    async def check_batch(self, urls: list[str], concurrency: int = 10) -> dict[str, bool]:
        """Check multiple URLs concurrently."""
        import aiohttp

        results = {}
        semaphore = asyncio.Semaphore(concurrency)

        async def check_one(session: aiohttp.ClientSession, url: str):
            async with semaphore:
                try:
                    async with session.head(url, timeout=aiohttp.ClientTimeout(total=self.timeout)) as resp:
                        results[url] = resp.status == 200
                except Exception:
                    results[url] = False

        async with aiohttp.ClientSession() as session:
            await asyncio.gather(*[check_one(session, url) for url in urls])

        return results


def download_audio(item: IngestedItem, out_dir: Path) -> Path | None:
    """Download audio file to local storage."""
    lang_dir = out_dir / item.language / "original"
    lang_dir.mkdir(parents=True, exist_ok=True)
    out_path = lang_dir / f"{item.id}.mp3"

    if out_path.exists():
        print(f"[Download] Skipping (exists): {item.id}")
        return out_path

    try:
        print(f"[Download] Fetching: {item.title[:50]}...")
        resp = requests.get(item.download_url, timeout=120, stream=True)
        resp.raise_for_status()

        with open(out_path, "wb") as f:
            for chunk in resp.iter_content(chunk_size=8192):
                f.write(chunk)

        # Get duration using ffprobe
        item.size_kb = int(out_path.stat().st_size / 1024)
        item.duration_sec = ffprobe_duration(out_path)
        item.local_path = out_path

        print(f"[Download] Saved: {out_path} ({item.duration_sec}s, {item.size_kb}KB)")
        return out_path
    except Exception as e:
        print(f"[Download] Failed {item.id}: {e}")
        return None


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


def update_catalog(items: list[IngestedItem], catalog_path: Path) -> None:
    """Merge ingested items into the existing catalog."""
    # Load existing catalog
    if catalog_path.exists():
        with open(catalog_path, "r", encoding="utf-8") as f:
            catalog = json.load(f)
    else:
        catalog = {"version": datetime.now().strftime("%Y-%m-%d"), "items": []}

    existing_ids = {it["id"] for it in catalog["items"]}

    # Add new items
    added = 0
    for item in items:
        if item.id not in existing_ids:
            catalog["items"].append(item.to_catalog_item())
            added += 1

    # Update version
    catalog["version"] = datetime.now().strftime("%Y-%m-%d-ingest")

    # Save
    with open(catalog_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)

    print(f"[Catalog] Added {added} new items, total: {len(catalog['items'])}")


def verify_health(catalog_path: Path) -> None:
    """Check all URLs in catalog are still reachable."""
    if not catalog_path.exists():
        print("[Health] No catalog found")
        return

    with open(catalog_path, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    checker = HealthChecker()
    dead_urls = []
    live_count = 0

    for item in catalog["items"]:
        source_url = item.get("sourceUrl", "")
        if source_url:
            ok, status = checker.check_url(source_url)
            if ok:
                live_count += 1
            else:
                dead_urls.append((item["id"], source_url, status))
                item["reachable"] = False
        else:
            live_count += 1  # Local items assumed OK

    print(f"[Health] {live_count} reachable, {len(dead_urls)} dead")

    if dead_urls:
        print("\nDead URLs:")
        for item_id, url, status in dead_urls[:10]:
            print(f"  {item_id}: {url} (HTTP {status})")

    # Save updated catalog
    with open(catalog_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description="Ingest public audio sources")
    parser.add_argument(
        "--source",
        choices=["librivox", "archive", "all"],
        default="archive",
        help="Source to ingest from",
    )
    parser.add_argument("--language", default="hindi", help="Target language")
    parser.add_argument("--collection", help="Archive.org collection ID")
    parser.add_argument("--query", help="Search query")
    parser.add_argument("--limit", type=int, default=20, help="Max items to fetch")
    parser.add_argument("--download", action="store_true", help="Download audio files")
    parser.add_argument("--verify-health", action="store_true", help="Verify all URLs")
    parser.add_argument("--out", type=Path, default=CDN_DIST, help="Output directory")
    args = parser.parse_args()

    catalog_path = args.out / "catalog.json"

    if args.verify_health:
        verify_health(catalog_path)
        return

    all_items: list[IngestedItem] = []

    if args.source in ("archive", "all"):
        print(f"\n[Archive] Searching for {args.language} content...")
        ingester = InternetArchiveIngester(args.language)
        docs = ingester.search(collection=args.collection, query=args.query, limit=args.limit)
        print(f"[Archive] Found {len(docs)} items")

        for doc in docs:
            items = ingester.ingest_item(doc)
            all_items.extend(items)

    if args.source in ("librivox", "all"):
        print(f"\n[LibriVox] Searching...")
        ingester = LibriVoxIngester(args.language)
        books = ingester.search(limit=args.limit)
        print(f"[LibriVox] Found {len(books)} books")

        for book in books:
            items = ingester.ingest_book(book)
            all_items.extend(items)

    print(f"\n[Total] Ingested {len(all_items)} items")

    if args.download:
        print("\n[Download] Fetching audio files...")
        for item in all_items:
            download_audio(item, args.out)

    # Update catalog
    update_catalog(all_items, catalog_path)

    print("\nDone! Run with --verify-health to check URL availability.")


if __name__ == "__main__":
    main()
