#!/usr/bin/env python3
"""One-off: repair transliterated titles in translation drafts.

Google Translate often transliterates short Title-Case English titles
(e.g. "The Monkey and the Crocodile" -> Telugu phonetics) instead of
translating them. Detect suspect titles and retranslate them from the
item's *Hindi* title (Devanagari source never transliterates).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from translate_fanout import translate_text, LIBRARY, DRAFTS

# Transliteration artifacts of common English words in Indic scripts / Urdu.
SUSPECT = re.compile(
    r"ది |అండ్|మంకీ|డాన్|ಡಾನ್|ডন|ڈان|ద్ ఆర్ట్|స్లో డే|ఫారెస్ట్|బ్లాంకెట్|స్టార్స్"
    r"|ఎలిఫెంట్|గార్డెన్|డ్రీమ్స్|సాంగ్|బస్|ప్రిన్స్|పాట్|వై ది|సెవెన్|బెల్"
    r"|వీవర్స్|క్రోకోడైల్|సరెండర్|డేడ్రీమర్|ڈے ڈریمر|ఫ్రాగ్|విస్పరింగ్|రెయిన్స్"
    r"|నైట్|స్కై|ఈజ్|హై|జస్టిస్|విజ్డమ్|విషెస్|సిస్టర్|స్టార్|లెట్టింగ్ గో"
)


def hindi_title(base_id: str, cat_file: str) -> str | None:
    src = LIBRARY / cat_file
    data = json.loads(src.read_text())
    for item in data["items"]:
        if item["base_id"] == base_id:
            return item.get("titles", {}).get("hindi")
    return None


def main() -> None:
    dry = "--dry-run" in sys.argv
    fixed = skipped = 0
    for draft_path in sorted(DRAFTS.glob("translated-*.json")):
        cat_file = draft_path.name.replace("translated-", "")
        data = json.loads(draft_path.read_text())
        changed = False
        for item in data["items"]:
            for lang, title in list(item["titles"].items()):
                if not SUSPECT.search(title):
                    continue
                hi = hindi_title(item["base_id"], cat_file)
                if not hi:
                    print(f"  ? no hindi source: {item['base_id']} [{lang}] {title}")
                    skipped += 1
                    continue
                new = None if dry else translate_text(hi, "hindi", lang)
                print(f"  {item['base_id']} [{lang}]\n    old: {title}\n    hi : {hi}\n    new: {new}")
                if new and new != title:
                    item["titles"][lang] = new
                    changed = True
                    fixed += 1
        if changed and not dry:
            draft_path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n")
            print(f"-> wrote {draft_path.name}")
    print(f"\nFixed {fixed} title(s), skipped {skipped}.")


if __name__ == "__main__":
    main()
