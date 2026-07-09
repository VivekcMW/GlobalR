#!/usr/bin/env python3
"""
Public Audio Content Ingestion Pipeline for Global Radio

Sources:
  1. LibriVox - Public domain audiobooks (CC0/Public Domain)
  2. Internet Archive - Diverse audio content (various CC licenses)
  3. Wikimedia Commons - Educational audio (CC licenses)
  4. Pratham StoryWeaver - CC BY 4.0 children's stories (TEXT -> our TTS)
  5. Project Gutenberg (gutendex API) - public-domain texts (TEXT -> our TTS)

Audio sources output catalog-compatible items to cdn_dist/ structure:
    cdn_dist/{language}/{voice}/{item_id}.mp3
    cdn_dist/catalog.json (updated with new items)

Text sources output DRAFT library items for human review:
    tools/content/library/drafts/{source}-{lang}.json
After review, move approved items into tools/content/library/<category>.json
and run build_catalog.py to synthesise audio.

Usage:
    python ingest_public_sources.py --source librivox --language hindi --limit 10
    python ingest_public_sources.py --source archive --collection indian_languages
    python ingest_public_sources.py --source storyweaver --language hindi --limit 25
    python ingest_public_sources.py --source gutenberg --query "aesop fables"
    python ingest_public_sources.py --verify-health   # Check all URLs still work
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import time
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
STORYWEAVER_API = "https://storyweaver.org.in/api/v1/books-search"
GUTENDEX_API = "https://gutendex.com/books"
DRAFTS_DIR = CONTENT / "library" / "drafts"

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


class StoryWeaverIngester:
    """Ingest CC BY 4.0 children's story TEXTS from Pratham StoryWeaver.

    Produces draft library items (title + text + attribution) for human
    review — audio is synthesised later by build_catalog.py.
    """

    # StoryWeaver language names as the API expects them.
    SW_LANG = {
        "hindi": "Hindi", "english": "English", "bengali": "Bengali",
        "marathi": "Marathi", "telugu": "Telugu", "tamil": "Tamil",
        "kannada": "Kannada", "malayalam": "Malayalam",
        "gujarati": "Gujarati", "urdu": "Urdu", "punjabi": "Punjabi",
        "odia": "Odia", "assamese": "Assamese",
    }

    def __init__(self, language: str = "hindi"):
        self.language = language

    def search(self, limit: int = 20, query: str | None = None,
               page: int = 1) -> list[dict]:
        params = {
            "page": page,
            "per_page": min(limit, 24),
            "languages[]": self.SW_LANG.get(self.language, "Hindi"),
            "sort": "Ratings",
        }
        if query:
            params["query"] = query
        try:
            resp = requests.get(STORYWEAVER_API, params=params, timeout=30)
            resp.raise_for_status()
            return resp.json().get("data", [])[:limit]
        except Exception as e:
            print(f"[StoryWeaver] search failed: {e}")
            return []

    def search_bulk(self, pages: int = 5, per_page: int = 24,
                    query: str | None = None) -> list[dict]:
        """Paginate through up to `pages` result pages (top-rated first),
        de-duplicated by slug. ~24 stories/page -> 120 stories at defaults."""
        seen: dict[str, dict] = {}
        for page in range(1, pages + 1):
            batch = self.search(limit=per_page, query=query, page=page)
            if not batch:
                break
            for book in batch:
                slug = book.get("slug")
                if slug and slug not in seen:
                    seen[slug] = book
            time.sleep(0.5)  # be polite to the API
        return list(seen.values())

    def fetch_story_text(self, slug: str, max_chars: int = 6000) -> str:
        """Fetch the full story text from the StoryWeaver reader API and
        strip page HTML down to plain narration. Returns '' on failure
        (callers fall back to the synopsis)."""
        url = f"https://storyweaver.org.in/api/v1/stories/{slug}/read"
        try:
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            pages = (resp.json().get("data") or {}).get("pages", [])
        except Exception as e:
            print(f"[StoryWeaver] read failed for {slug}: {e}")
            return ""
        chunks: list[str] = []
        for p in pages:
            html_content = p.get("html") or p.get("content") or ""
            text = re.sub(r"<[^>]+>", " ", html_content)
            text = html.unescape(text)
            text = re.sub(r"\s+", " ", text).strip()
            if text:
                chunks.append(text)
        return " ".join(chunks)[:max_chars]

    def to_draft(self, book: dict, fetch_text: bool = False) -> dict | None:
        """Convert a search hit into a draft library item. With
        fetch_text=True the full story text is pulled from the reader API
        (falling back to the synopsis when unavailable)."""
        title = (book.get("title") or "").strip()
        slug = book.get("slug", "")
        synopsis = (book.get("synopsis") or "").strip()
        if not title or not slug:
            return None
        text = ""
        if fetch_text:
            text = self.fetch_story_text(slug)
        full_text = bool(text)
        if not text:
            text = synopsis
        authors = ", ".join(a.get("name", "") for a in book.get("authors", []))
        base_id = "kids-sw-" + re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:48]
        note = ("REVIEW: verify CC BY licence on the story page, check the "
                "text reads well for TTS, then move to the category file "
                "and delete _draft/_sourceUrl/_note.") if full_text else (
                "REVIEW: replace text with full story from _sourceUrl, "
                "verify CC BY licence on the story page, then move to "
                "the category file and delete _draft/_sourceUrl/_note.")
        return {
            "base_id": base_id,
            "interests": ["kids"],
            "voices": ["kids_story"],
            "defaultVoice": "kids_story",
            "attribution": (f"'{title}' by {authors}, Pratham Books StoryWeaver, "
                            "CC BY 4.0."),
            "popularity": 50,
            "titles": {self.language: title},
            "text": {self.language: text},
            "_draft": True,
            "_fullText": full_text,
            "_sourceUrl": f"https://storyweaver.org.in/en/stories/{slug}",
            "_note": note,
        }


class WikisourceIngester:
    """Ingest PUBLIC-DOMAIN texts from Wikisource via the open MediaWiki API.

    Wikisource hosts proofread public-domain literature in every Global Radio
    language (hi/bn/ta/te/kn/ml/mr/gu/ur/en wikis) — Premchand, Panchatantra,
    Aesop translations, devotional classics — with no bot-blocking, making it
    the most reliable bulk text source. Produces draft library items.
    """

    WS_LANG = {
        "hindi": "hi", "english": "en", "bengali": "bn", "marathi": "mr",
        "telugu": "te", "tamil": "ta", "kannada": "kn", "malayalam": "ml",
        "gujarati": "gu", "urdu": "ur",
    }
    HEADERS = {"User-Agent": "GlobalRadioContentBot/1.0 "
                             "(public-domain story sourcing; contact: repo)"}

    # Subclasses override these to target other MediaWiki sites.
    SITE = "wikisource.org"
    PREFIX = "ws"
    DEFAULT_INTERESTS = ["folklore"]
    LICENCE_TEXT = "public domain"
    REVIEW_NOTE = ("REVIEW: confirm the work is public domain (author died "
                   ">60 years ago), trim to 60-120s of narration, fix "
                   "category/voice, then move to the category file and "
                   "delete _draft/_sourceUrl/_note.")

    def __init__(self, language: str = "hindi"):
        self.language = language
        code = self.WS_LANG.get(language, "hi")
        self.api = f"https://{code}.{self.SITE}/w/api.php"

    def _get(self, params: dict, retries: int = 3) -> dict | None:
        """GET with exponential backoff on 429 rate-limits."""
        for attempt in range(retries):
            try:
                resp = requests.get(self.api, params=params,
                                    headers=self.HEADERS, timeout=30)
                if resp.status_code == 429:
                    wait = 10 * (attempt + 1)
                    print(f"[Wikisource] rate-limited, waiting {wait}s...")
                    time.sleep(wait)
                    continue
                resp.raise_for_status()
                return resp.json()
            except Exception as e:
                print(f"[Wikisource] request failed: {e}")
                return None
        return None

    def search(self, query: str, limit: int = 20, offset: int = 0) -> list[dict]:
        params = {
            "action": "query", "list": "search", "srsearch": query,
            "srlimit": min(limit, 50), "sroffset": offset,
            "srnamespace": 0, "format": "json",
        }
        data = self._get(params)
        if not data:
            return []
        return data.get("query", {}).get("search", [])[:limit]

    def search_bulk(self, query: str, pages: int = 4,
                    per_page: int = 50) -> list[dict]:
        """Paginate search results, de-duplicated by pageid."""
        seen: dict[int, dict] = {}
        for i in range(pages):
            batch = self.search(query, limit=per_page, offset=i * per_page)
            if not batch:
                break
            for hit in batch:
                seen.setdefault(hit["pageid"], hit)
            time.sleep(0.3)
        return list(seen.values())

    def fetch_text(self, title: str, max_chars: int = 8000) -> str:
        """Fetch page content via action=parse (TextExtracts is unreliable on
        Wikisource subpages) and strip the HTML down to plain narration."""
        params = {
            "action": "parse", "page": title, "prop": "text",
            "format": "json", "redirects": 1, "disabletoc": 1,
        }
        data = self._get(params)
        if not data:
            return ""
        html_content = (data.get("parse") or {}).get("text", {}).get("*", "")
        # Drop nav/metadata blocks, then strip tags.
        html_content = re.sub(
            r"<(table|style|script)[^>]*>.*?</\1>", " ",
            html_content, flags=re.S)
        html_content = re.sub(
            r'<(div|span)[^>]*class="[^"]*(noprint|mw-editsection|ws-noexport'
            r'|header)[^"]*"[^>]*>.*?</\1>', " ", html_content, flags=re.S)
        text = re.sub(r"<[^>]+>", " ", html_content)
        text = html.unescape(text)
        text = re.sub(r"\[\s*\d+\s*\]", " ", text)  # footnote markers
        text = re.sub(r"\s+", " ", text).strip()
        return text[:max_chars]

    def to_draft(self, hit: dict, interests: list[str] | None = None) -> dict | None:
        title = (hit.get("title") or "").strip()
        if not title or ":" in title:  # skip non-main-namespace leftovers
            return None
        text = self.fetch_text(title)
        if len(text.split()) < 40:  # index/disambiguation pages are short
            return None
        slug = re.sub(r"[^a-z0-9]+", "-",
                      re.sub(r"[^\w\s-]", "", title.lower()))[:48].strip("-")
        if not slug:  # non-Latin titles (Devanagari etc.) -> use the page id
            slug = f"p{hit.get('pageid', abs(hash(title)) % 10**8)}"
        base_id = f"{self.PREFIX}-{self.WS_LANG.get(self.language, 'xx')}-{slug}"
        url_title = title.replace(" ", "_")
        code = self.WS_LANG.get(self.language, "hi")
        return {
            "base_id": base_id,
            "interests": interests or list(self.DEFAULT_INTERESTS),
            "voices": ["male_story"],
            "defaultVoice": "male_story",
            "attribution": (f"'{title}', {self.LICENCE_TEXT}, "
                            f"via {code}.{self.SITE}."),
            "popularity": 50,
            "titles": {self.language: title},
            "text": {self.language: text},
            "_draft": True,
            "_sourceUrl": f"https://{code}.{self.SITE}/wiki/{url_title}",
            "_note": self.REVIEW_NOTE,
        }


class WikipediaIngester(WikisourceIngester):
    """Education/GK drafts from Wikipedia (CC BY-SA 4.0) — biographies,
    history, science explainers in every Global Radio language."""

    SITE = "wikipedia.org"
    PREFIX = "wp"
    DEFAULT_INTERESTS = ["education"]
    LICENCE_TEXT = "CC BY-SA 4.0"
    REVIEW_NOTE = ("REVIEW: summarise/retell in our own words for a 60-120s "
                   "narration (CC BY-SA requires attribution + share-alike "
                   "for verbatim use), fix category/voice, then move to the "
                   "category file and delete _draft/_sourceUrl/_note.")


class WikiquoteIngester(WikisourceIngester):
    """Motivational quote-collection drafts from Wikiquote (CC BY-SA 4.0)."""

    SITE = "wikiquote.org"
    PREFIX = "wq"
    DEFAULT_INTERESTS = ["motivation"]
    LICENCE_TEXT = "CC BY-SA 4.0"
    REVIEW_NOTE = ("REVIEW: pick 8-12 strong quotes, verify attribution of "
                   "each quote, weave into a short narration, then move to "
                   "the category file and delete _draft/_sourceUrl/_note.")


class GutenbergIngester:
    """Ingest public-domain TEXTS from Project Gutenberg via gutendex.

    Produces draft library items; the plain-text book is downloaded and
    truncated for editors to carve into short items.
    """

    def __init__(self, language: str = "english"):
        self.language = language

    def search(self, query: str, limit: int = 10) -> list[dict]:
        params = {
            "search": query,
            "languages": LANG_CODES.get(self.language, "en"),
            "copyright": "false",  # public domain only
        }
        try:
            resp = requests.get(GUTENDEX_API, params=params, timeout=30)
            resp.raise_for_status()
            return resp.json().get("results", [])[:limit]
        except Exception as e:
            print(f"[Gutenberg] search failed: {e}")
            return []

    def fetch_text(self, book: dict, max_chars: int = 20000) -> str:
        formats = book.get("formats", {})
        url = (formats.get("text/plain; charset=us-ascii")
               or formats.get("text/plain; charset=utf-8")
               or formats.get("text/plain"))
        if not url:
            return ""
        try:
            resp = requests.get(url, timeout=60)
            resp.raise_for_status()
            return resp.text[:max_chars]
        except Exception as e:
            print(f"[Gutenberg] text fetch failed: {e}")
            return ""

    def to_draft(self, book: dict) -> dict | None:
        title = (book.get("title") or "").strip()
        if not title:
            return None
        authors = ", ".join(a.get("name", "") for a in book.get("authors", []))
        base_id = "pd-gut-" + re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:48]
        excerpt = self.fetch_text(book)
        return {
            "base_id": base_id,
            "interests": ["kids"],
            "voices": ["kids_story"],
            "defaultVoice": "kids_story",
            "attribution": f"'{title}' by {authors} (public domain, Project "
                           "Gutenberg) — retold in our own words.",
            "popularity": 50,
            "titles": {self.language: title},
            "text": {self.language: excerpt},
            "_draft": True,
            "_sourceUrl": f"https://www.gutenberg.org/ebooks/{book.get('id')}",
            "_note": "REVIEW: carve the raw excerpt into 60-90 second items, "
                     "retell in our own words, then move to the category "
                     "file and delete _draft/_sourceUrl/_note.",
        }


def write_drafts(drafts: list[dict], source: str, language: str) -> Path:
    """Write draft library items for editorial review."""
    DRAFTS_DIR.mkdir(parents=True, exist_ok=True)
    path = DRAFTS_DIR / f"{source}-{language}.json"
    payload = {
        "_comment": ("DRAFTS — not built until reviewed and moved into a "
                     "category file in tools/content/library/."),
        "items": drafts,
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    return path


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
        choices=["librivox", "archive", "storyweaver", "gutenberg",
                 "wikisource", "wikipedia", "wikiquote", "all"],
        default="archive",
        help="Source to ingest from",
    )
    parser.add_argument("--language", default="hindi", help="Target language")
    parser.add_argument("--collection", help="Archive.org collection ID")
    parser.add_argument("--query", help="Search query")
    parser.add_argument("--interest", help="Tag drafts with this interest instead of the source's default")
    parser.add_argument("--limit", type=int, default=20, help="Max items to fetch")
    parser.add_argument("--bulk", action="store_true",
                        help="StoryWeaver: paginate + fetch FULL story text; "
                             "--language all harvests every supported language")
    parser.add_argument("--pages", type=int, default=5,
                        help="Bulk mode: result pages per language (~24/page)")
    parser.add_argument("--download", action="store_true", help="Download audio files")
    parser.add_argument("--verify-health", action="store_true", help="Verify all URLs")
    parser.add_argument("--out", type=Path, default=CDN_DIST, help="Output directory")
    args = parser.parse_args()

    catalog_path = args.out / "catalog.json"

    if args.verify_health:
        verify_health(catalog_path)
        return

    # Text sources -> draft library items (no catalog/audio changes).
    wiki_sources = {
        "wikisource": WikisourceIngester,
        "wikipedia": WikipediaIngester,
        "wikiquote": WikiquoteIngester,
    }
    if args.source in wiki_sources:
        cls = wiki_sources[args.source]
        langs = (list(WikisourceIngester.WS_LANG.keys())
                 if args.language == "all" else [args.language])
        # Default queries tuned per pipeline goals; override with --query.
        default_queries = {
            "wikisource": {
                "hindi": "पंचतंत्र कहानी", "english": "fable moral story",
                "bengali": "গল্প", "marathi": "गोष्ट", "telugu": "कथ",
                "tamil": "கதை", "kannada": "ಕಥೆ", "malayalam": "കഥ",
                "gujarati": "વાર્તા", "urdu": "کہانی",
            },
            "wikipedia": {
                "hindi": "स्वतंत्रता सेनानी", "english": "Indian scientist",
                "bengali": "বিজ্ঞানী", "marathi": "स्वातंत्र्यसैनिक",
                "telugu": "స్వాతంత్ర్య సమరయోధుడు", "tamil": "விஞ்ஞானி",
                "kannada": "ಸ್ವಾತಂತ್ರ್ಯ ಹೋರಾಟಗಾರ", "malayalam": "ശാസ്ത്രജ്ഞൻ",
                "gujarati": "સ્વતંત્રતા સેનાની", "urdu": "سائنسدان",
            },
            "wikiquote": {
                "hindi": "महात्मा गांधी", "english": "Swami Vivekananda",
                "bengali": "রবীন্দ্রনাথ", "marathi": "शिवाजी",
                "telugu": "గాంధీ", "tamil": "திருக்குறள்", "kannada": "ಗಾಂಧಿ",
                "malayalam": "ഗാന്ധി", "gujarati": "ગાંધી", "urdu": "اقبال",
            },
        }[args.source]
        grand_total = 0
        for lang in langs:
            ws = cls(lang)
            query = args.query or default_queries.get(lang, "story")
            hits = (ws.search_bulk(query, pages=args.pages) if args.bulk
                    else ws.search(query, limit=args.limit))
            print(f"[{args.source}:{lang}] Found {len(hits)} pages for '{query}'")
            lang_drafts = []
            draft_interests = [args.interest] if args.interest else None
            for hit in hits:
                d = ws.to_draft(hit, interests=draft_interests)
                if d:
                    lang_drafts.append(d)
                time.sleep(1.0)  # stay under the API rate limit
            if lang_drafts:
                path = write_drafts(lang_drafts, args.source, lang)
                print(f"[Drafts:{lang}] {len(lang_drafts)} drafts -> {path}")
                grand_total += len(lang_drafts)
        print(f"\n[{args.source}] {grand_total} total drafts. Review, then move "
              "approved items into tools/content/library/<category>.json "
              "and run build_catalog.py.")
        return

    if args.source in ("storyweaver", "gutenberg"):
        drafts: list[dict] = []
        if args.source == "storyweaver" and args.bulk:
            langs = (list(StoryWeaverIngester.SW_LANG.keys())
                     if args.language == "all" else [args.language])
            grand_total = 0
            for lang in langs:
                sw = StoryWeaverIngester(lang)
                books = sw.search_bulk(pages=args.pages, query=args.query)
                print(f"[StoryWeaver:{lang}] Found {len(books)} stories")
                lang_drafts = []
                for book in books:
                    d = sw.to_draft(book, fetch_text=True)
                    if d and len(d["text"].get(lang, "").split()) >= 15:
                        lang_drafts.append(d)
                    time.sleep(0.3)
                if lang_drafts:
                    path = write_drafts(lang_drafts, "storyweaver", lang)
                    full = sum(1 for d in lang_drafts if d.get("_fullText"))
                    print(f"[Drafts:{lang}] {len(lang_drafts)} drafts "
                          f"({full} with full text) -> {path}")
                    grand_total += len(lang_drafts)
            print(f"\n[Bulk] {grand_total} total drafts. Review, then move "
                  "approved items into tools/content/library/<category>.json "
                  "and run build_catalog.py.")
            return
        if args.source == "storyweaver":
            sw = StoryWeaverIngester(args.language)
            books = sw.search(limit=args.limit, query=args.query)
            print(f"[StoryWeaver] Found {len(books)} stories")
            drafts = [d for d in (sw.to_draft(b) for b in books) if d]
        else:
            gut = GutenbergIngester(args.language)
            books = gut.search(args.query or "fables", limit=args.limit)
            print(f"[Gutenberg] Found {len(books)} books")
            drafts = [d for d in (gut.to_draft(b) for b in books) if d]
        if drafts:
            path = write_drafts(drafts, args.source, args.language)
            print(f"[Drafts] Wrote {len(drafts)} draft items -> {path}")
            print("Review, edit, move approved items into "
                  "tools/content/library/<category>.json, then run "
                  "build_catalog.py.")
        else:
            print("[Drafts] Nothing ingested.")
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
