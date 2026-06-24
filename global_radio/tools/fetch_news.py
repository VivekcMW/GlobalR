#!/usr/bin/env python3
"""
News fetcher and TTS converter for Global Radio.
Fetches news from RSS feeds, converts to audio using Azure TTS.
"""

import asyncio
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

import aiohttp
import feedparser
from azure.cognitiveservices.speech import (
    AudioConfig,
    SpeechConfig,
    SpeechSynthesizer,
)

# Paths
SCRIPT_DIR = Path(__file__).parent
CONTENT_DIR = SCRIPT_DIR / "content"
OUTPUT_DIR = SCRIPT_DIR.parent / "cdn_dist"
NEWS_SOURCES_FILE = CONTENT_DIR / "news_sources.json"

# Azure TTS settings
AZURE_SPEECH_KEY = os.getenv("AZURE_SPEECH_KEY")
AZURE_SPEECH_REGION = os.getenv("AZURE_SPEECH_REGION", "eastus")

# Language to Azure voice mapping
VOICE_MAP = {
    "hindi": "hi-IN-MadhurNeural",
    "english": "en-IN-NeerjaNeural",
    "tamil": "ta-IN-PallaviNeural",
    "telugu": "te-IN-MohanNeural",
    "kannada": "kn-IN-SapnaNeural",
    "malayalam": "ml-IN-MidhunNeural",
    "marathi": "mr-IN-AarohiNeural",
    "gujarati": "gu-IN-DhwaniNeural",
    "bengali": "bn-IN-TanishaaNeural",
    "urdu": "ur-IN-GulNeural",
}


def load_news_sources() -> dict:
    """Load news sources configuration."""
    with open(NEWS_SOURCES_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


async def fetch_rss_feed(session: aiohttp.ClientSession, url: str) -> list[dict]:
    """Fetch and parse an RSS feed."""
    try:
        async with session.get(url, timeout=30) as response:
            if response.status != 200:
                print(f"Failed to fetch {url}: HTTP {response.status}")
                return []
            
            content = await response.text()
            feed = feedparser.parse(content)
            
            items = []
            for entry in feed.entries[:10]:  # Limit to 10 items
                items.append({
                    "title": entry.get("title", ""),
                    "summary": entry.get("summary", entry.get("description", "")),
                    "link": entry.get("link", ""),
                    "published": entry.get("published", ""),
                })
            return items
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return []


def clean_html(text: str) -> str:
    """Remove HTML tags and clean text."""
    # Remove HTML tags
    text = re.sub(r"<[^>]+>", "", text)
    # Decode HTML entities
    text = text.replace("&nbsp;", " ")
    text = text.replace("&amp;", "&")
    text = text.replace("&lt;", "<")
    text = text.replace("&gt;", ">")
    text = text.replace("&quot;", '"')
    # Remove extra whitespace
    text = re.sub(r"\s+", " ", text).strip()
    return text


def generate_news_ssml(
    items: list[dict],
    language: str,
    settings: dict
) -> str:
    """Generate SSML for news bulletin."""
    voice = VOICE_MAP.get(language, "en-IN-NeerjaNeural")
    
    date_str = datetime.now().strftime("%d %B %Y")
    intro = settings.get("intro_template", "Today's news, {date}").format(date=date_str)
    outro = settings.get("outro_template", "That's all for today's news.")
    
    ssml_parts = [
        f'<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="{language[:2]}">',
        f'<voice name="{voice}">',
        f'<prosody rate="medium">{intro}</prosody>',
        '<break time="1s"/>',
    ]
    
    for i, item in enumerate(items, 1):
        title = clean_html(item["title"])
        summary = clean_html(item["summary"])
        
        # Truncate summary if too long
        if len(summary) > 200:
            summary = summary[:200].rsplit(" ", 1)[0] + "..."
        
        ssml_parts.append(f'<p>News {i}. {title}.</p>')
        if summary:
            ssml_parts.append(f'<p>{summary}</p>')
        ssml_parts.append('<break time="800ms"/>')
    
    ssml_parts.extend([
        f'<prosody rate="medium">{outro}</prosody>',
        '</voice>',
        '</speak>',
    ])
    
    return "\n".join(ssml_parts)


def synthesize_speech(ssml: str, output_path: Path, language: str) -> bool:
    """Convert SSML to audio using Azure TTS."""
    if not AZURE_SPEECH_KEY:
        print("AZURE_SPEECH_KEY not set, skipping TTS")
        return False
    
    try:
        speech_config = SpeechConfig(
            subscription=AZURE_SPEECH_KEY,
            region=AZURE_SPEECH_REGION
        )
        speech_config.speech_synthesis_voice_name = VOICE_MAP.get(
            language, "en-IN-NeerjaNeural"
        )
        
        audio_config = AudioConfig(filename=str(output_path))
        synthesizer = SpeechSynthesizer(
            speech_config=speech_config,
            audio_config=audio_config
        )
        
        result = synthesizer.speak_ssml_async(ssml).get()
        
        if result.reason.name == "SynthesizingAudioCompleted":
            print(f"Audio saved to {output_path}")
            return True
        else:
            print(f"TTS failed: {result.reason}")
            return False
    except Exception as e:
        print(f"TTS error: {e}")
        return False


def generate_catalog_entry(
    source_id: str,
    source_name: str,
    language: str,
    audio_filename: str,
    duration_seconds: int = 180
) -> dict:
    """Generate a catalog entry for the news audio."""
    today = datetime.now().strftime("%Y-%m-%d")
    item_id = f"news_{source_id}_{today}"
    
    return {
        "id": item_id,
        "title": f"{source_name} - {datetime.now().strftime('%d %b')}",
        "language": language,
        "interests": ["news"],
        "primaryInterest": "news",
        "audioUrl": f"/{language}/news/{audio_filename}",
        "duration": duration_seconds,
        "publishedAt": datetime.now().isoformat(),
        "expiresAt": (datetime.now() + timedelta(hours=24)).isoformat(),
        "type": "news",
        "metadata": {
            "source": source_name,
            "sourceId": source_id,
            "category": "general"
        }
    }


async def process_news_source(
    session: aiohttp.ClientSession,
    source: dict,
    settings: dict
) -> Optional[dict]:
    """Process a single news source."""
    print(f"Processing {source['name']} ({source['language']})...")
    
    # Fetch RSS feed
    items = await fetch_rss_feed(session, source["url"])
    if not items:
        print(f"No items found for {source['name']}")
        return None
    
    # Limit items per source
    max_items = settings.get("max_items_per_source", 5)
    items = items[:max_items]
    
    # Generate SSML
    ssml = generate_news_ssml(items, source["language"], settings)
    
    # Create output directory
    language = source["language"]
    output_dir = OUTPUT_DIR / language / "news"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate output filename
    today = datetime.now().strftime("%Y%m%d")
    audio_filename = f"{source['id']}_{today}.wav"
    output_path = output_dir / audio_filename
    
    # Synthesize speech
    if synthesize_speech(ssml, output_path, language):
        return generate_catalog_entry(
            source["id"],
            source["name"],
            language,
            audio_filename
        )
    
    return None


async def main():
    """Main entry point."""
    print("=== Global Radio News Fetcher ===")
    print(f"Time: {datetime.now()}")
    
    # Load configuration
    config = load_news_sources()
    sources = [s for s in config["sources"] if s.get("enabled", True)]
    settings = config.get("settings", {})
    
    print(f"Found {len(sources)} enabled news sources")
    
    # Process all sources
    catalog_entries = []
    
    async with aiohttp.ClientSession() as session:
        tasks = [
            process_news_source(session, source, settings)
            for source in sources
        ]
        results = await asyncio.gather(*tasks)
        
        for result in results:
            if result:
                catalog_entries.append(result)
    
    # Save catalog entries
    if catalog_entries:
        catalog_file = OUTPUT_DIR / "news_catalog.json"
        with open(catalog_file, "w", encoding="utf-8") as f:
            json.dump({
                "generatedAt": datetime.now().isoformat(),
                "items": catalog_entries
            }, f, ensure_ascii=False, indent=2)
        
        print(f"\nGenerated {len(catalog_entries)} news items")
        print(f"Catalog saved to {catalog_file}")
    else:
        print("\nNo news items generated")
    
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
