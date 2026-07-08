#!/usr/bin/env python3
"""Translation fan-out: multiply library items across all 10 languages.

Takes reviewed items from tools/content/library/*.json that only have text in
some languages (typically hindi/english) and machine-translates title + text
into the missing languages. Output goes to a *review file* — translations are
NEVER auto-published; an editor moves approved translations back into the
category file.

Backend: deep-translator's GoogleTranslator (free web endpoint, no API key).
Install:  tools/.venv/bin/pip install deep-translator

Usage:
    # See what's missing
    python tools/translate_fanout.py --dry-run

    # Fan hindi/english items out into all missing languages, one category
    python tools/translate_fanout.py --file kids.json --target-langs marathi,tamil

    # Everything missing, everywhere (slow; be polite to the endpoint)
    python tools/translate_fanout.py --all

Output: tools/content/library/drafts/translated-<file> for review. Each
translated block is tagged "_machineTranslated": true so reviewers know to
spot-check before merging back into the category file.
"""
from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIBRARY = ROOT / "content" / "library"
DRAFTS = LIBRARY / "drafts"

# Google Translate codes for Global Radio languages.
GT_CODES = {
    "hindi": "hi", "english": "en", "bengali": "bn", "marathi": "mr",
    "telugu": "te", "tamil": "ta", "kannada": "kn", "malayalam": "ml",
    "gujarati": "gu", "urdu": "ur",
}
ALL_LANGS = list(GT_CODES.keys())


def translate_text(text: str, src: str, dest: str,
                   retries: int = 3) -> str | None:
    """Translate one string. Returns None on repeated failure."""
    from deep_translator import GoogleTranslator

    translator = GoogleTranslator(source=GT_CODES[src], target=GT_CODES[dest])
    # The endpoint caps ~5000 chars; our items are far shorter, but chunk
    # defensively on sentence boundaries just in case.
    if len(text) <= 4500:
        chunks = [text]
    else:
        chunks, cur = [], ""
        for sent in text.replace("। ", "।\u0001").replace(". ", ".\u0001").split("\u0001"):
            if len(cur) + len(sent) > 4500:
                chunks.append(cur)
                cur = sent
            else:
                cur += sent + " "
        if cur.strip():
            chunks.append(cur)
    out: list[str] = []
    for chunk in chunks:
        for attempt in range(retries):
            try:
                out.append(translator.translate(chunk.strip()))
                break
            except Exception as e:
                if attempt == retries - 1:
                    print(f"    ! translate failed ({src}->{dest}): {e}")
                    return None
                time.sleep(3 * (attempt + 1))
        time.sleep(0.5)  # rate-friendly
    return " ".join(out)


def pick_source_lang(item: dict) -> str | None:
    """Prefer english as MT source (best quality), else hindi, else any."""
    texts = item.get("text", {})
    for lang in ("english", "hindi"):
        if texts.get(lang):
            return lang
    return next((l for l in texts if texts[l]), None)


def fanout_item(item: dict, targets: list[str]) -> dict | None:
    """Return a draft carrying ONLY the newly translated languages."""
    src = pick_source_lang(item)
    if not src:
        return None
    missing = [l for l in targets
               if l not in item.get("text", {}) and l in GT_CODES]
    if not missing:
        return None
    new_titles: dict = {}
    new_texts: dict = {}
    for lang in missing:
        print(f"  {item['base_id']}: {src} -> {lang}")
        t_title = translate_text(item["titles"].get(src, item["base_id"]),
                                 src, lang)
        t_text = translate_text(item["text"][src], src, lang)
        if t_title and t_text:
            new_titles[lang] = t_title
            new_texts[lang] = t_text
    if not new_texts:
        return None
    return {
        "base_id": item["base_id"],
        "interests": item["interests"],
        "voices": item["voices"],
        "defaultVoice": item["defaultVoice"],
        "attribution": item["attribution"],
        "popularity": item.get("popularity", 50),
        "titles": new_titles,
        "text": new_texts,
        "_draft": True,
        "_machineTranslated": True,
        "_sourceLang": src,
        "_note": "REVIEW: spot-check the machine translation, then merge "
                 "these titles/text blocks into the item in the category "
                 "file and delete this entry.",
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", default=None,
                    help="single category file (e.g. kids.json); default all")
    ap.add_argument("--target-langs", default="",
                    help="comma list; default = every missing language")
    ap.add_argument("--limit", type=int, default=0,
                    help="max items to translate this run (0 = no cap)")
    ap.add_argument("--all", action="store_true",
                    help="process every category file")
    ap.add_argument("--dry-run", action="store_true",
                    help="only report what would be translated")
    args = ap.parse_args()

    targets = ([l.strip() for l in args.target_langs.split(",") if l.strip()]
               or ALL_LANGS)
    files = ([LIBRARY / args.file] if args.file
             else sorted(LIBRARY.glob("*.json")))

    total_missing = 0
    done = 0
    for path in files:
        with open(path, encoding="utf-8") as f:
            items = json.load(f).get("items", [])
        pending = []
        for it in items:
            if it.get("_draft"):
                continue
            missing = [l for l in targets
                       if l not in it.get("text", {}) and l in GT_CODES]
            if missing:
                pending.append((it, missing))
        total_missing += len(pending)
        if not pending:
            continue
        print(f"{path.name}: {len(pending)} item(s) missing translations")
        if args.dry_run:
            for it, missing in pending[:5]:
                print(f"  {it['base_id']}: missing {', '.join(missing)}")
            if len(pending) > 5:
                print(f"  ... and {len(pending) - 5} more")
            continue

        drafts = []
        for it, _missing in pending:
            if args.limit and done >= args.limit:
                break
            d = fanout_item(it, targets)
            if d:
                drafts.append(d)
                done += 1
        if drafts:
            DRAFTS.mkdir(parents=True, exist_ok=True)
            out = DRAFTS / f"translated-{path.name}"
            with open(out, "w", encoding="utf-8") as f:
                json.dump({
                    "_comment": ("MACHINE TRANSLATIONS for review — merge "
                                 "approved blocks back into the category "
                                 "file."),
                    "items": drafts,
                }, f, ensure_ascii=False, indent=2)
            print(f"  -> {len(drafts)} translated draft(s): {out}")
        if args.limit and done >= args.limit:
            break

    if args.dry_run:
        print(f"\nTotal items with missing translations: {total_missing}")
    else:
        print(f"\nTranslated {done} item(s). Review drafts, merge, then run "
              "build_catalog.py.")


if __name__ == "__main__":
    main()
