#!/usr/bin/env python3
"""Generate the bundled per-language, per-voice demo narration clips.

These are placeholder voices so the app has real, language-appropriate audio to
play with no backend. Output layout mirrors the real CDN convention:

    assets/audio/demo/{language}/{voiceId}.mp3

Engine: Piper (offline neural TTS). This is the best *fully offline* option but
its Indic voices are only "medium" quality and cover 5 of the 13 Tier-1
languages (hindi, english, telugu, urdu, malayalam). For "very good" quality
across ALL 13 languages, swap the engine for Azure Neural TTS (see
docs/technical-build-spec.md) — keep this same output layout and the app needs
no changes.

Prereqs:
    pip install piper-tts          # + ffmpeg on PATH
    # Piper voice models (.onnx + .onnx.json) downloaded under MODELS_DIR.

Run:
    python3 tools/generate_demo_audio.py --models-dir /path/to/piper_models

Add a language by giving it an entry in VOICES below (model file per voiceId)
and a greeting in PROMPTS. Anything not listed simply isn't generated, and the
app falls back to the English clip at runtime.
"""
import argparse
import os
import shutil
import subprocess
import sys

# voiceId -> (piper model basename, length_scale). Higher length_scale = slower.
# kids_story uses the same female model as female_warm but at length_scale 0.92
# (slightly faster) to match the +10% rate used in the production edge-tts path.
VOICES = {
    "english": {
        "male_story":  ("en_US-ryan-high",     1.0),
        "female_warm": ("en_US-amy-medium",    1.0),
        "kids_story":  ("en_US-amy-medium",    0.92),
        "devotional":  ("en_US-lessac-medium", 1.25),
    },
    "hindi": {
        "male_story":  ("hi_IN-rohan-medium",      1.0),
        "female_warm": ("hi_IN-priyamvada-medium", 1.0),
        "kids_story":  ("hi_IN-priyamvada-medium", 0.92),
        "devotional":  ("hi_IN-pratham-medium",    1.2),
    },
    # Supported by Piper but not in the current seed catalog. Uncomment + add
    # PROMPTS to generate. (telugu / urdu / malayalam models also exist.)
    # "telugu":    {"male_story": ("te_IN-venkatesh-medium", 1.0), ...},
    # "urdu":      {"male_story": ("ur_PK-fasih-medium", 1.0), ...},
    # "malayalam": {"male_story": ("ml_IN-arjun-medium", 1.0), ...},
}

# Short greeting per (language, voiceId). Native script for natural prosody.
PROMPTS = {
    "english": {
        "male_story":  "Hello, this is the Storyteller voice. Once upon a time, a "
                       "thirsty crow found a pot of water and dropped pebbles in, one "
                       "by one, until the water rose high enough to drink. Thank you "
                       "for listening to Global Radio.",
        "female_warm": "Hi there, this is the Warm voice. Here is a gentle story for "
                       "you. A little mouse once helped a great lion, proving that even "
                       "the smallest friend can be the most important. Enjoy listening "
                       "on Global Radio.",
        "kids_story":  "Hi kids! This is the Kids Storyteller voice, bright and fun "
                       "just for you! Once upon a time, a clever little rabbit outsmarted "
                       "a proud lion using just his wits. Are you ready for a great story "
                       "on Global Radio? Let's go!",
        "devotional":  "Welcome. This is the Devotional voice. May your day be peaceful "
                       "and full of light. Let us take a calm, deep breath together as "
                       "we begin. Thank you for listening on Global Radio.",
    },
    "hindi": {
        "male_story":  "नमस्ते, यह कहानीकार की आवाज़ है। एक बार की बात है, एक प्यासे कौवे को "
                       "पानी से भरा घड़ा मिला। उसने एक-एक करके कंकड़ डाले, जब तक पानी ऊपर "
                       "नहीं आ गया और वह पी सका। ग्लोबल रेडियो सुनने के लिए धन्यवाद।",
        "female_warm": "नमस्ते, यह कोमल आवाज़ है। आपके लिए एक प्यारी सी कहानी। एक छोटे से "
                       "चूहे ने एक बार एक बड़े शेर की मदद की, यह साबित करते हुए कि सबसे "
                       "छोटा मित्र भी सबसे महत्वपूर्ण हो सकता है। ग्लोबल रेडियो पर सुनिए।",
        "kids_story":  "नमस्ते बच्चों! यह बच्चों की कहानीकार की आवाज़ है, एकदम मज़ेदार और "
                       "खुशनुमा! एक बार एक चतुर खरगोश ने अपनी बुद्धि से एक घमंडी शेर को "
                       "हरा दिया। क्या आप एक शानदार कहानी के लिए तैयार हैं? चलिए शुरू करते हैं "
                       "ग्लोबल रेडियो पर!",
        "devotional":  "स्वागत है। यह भक्ति की आवाज़ है। आपका दिन शांति और प्रकाश से भरा हो। "
                       "आइए, आरंभ करते हुए एक गहरी, शांत साँस साथ में लें। ग्लोबल रेडियो पर "
                       "सुनने के लिए धन्यवाद।",
    },
}

OUT_ROOT = os.path.join("assets", "audio", "demo")


def gen_one(models_dir, language, voice_id, model, length_scale, text):
    model_path = os.path.join(models_dir, f"{model}.onnx")
    if not os.path.exists(model_path):
        print(f"  SKIP {language}/{voice_id}: model not found ({model}.onnx)")
        return False
    out_dir = os.path.join(OUT_ROOT, language)
    os.makedirs(out_dir, exist_ok=True)
    wav = os.path.join(out_dir, f"{voice_id}.wav")
    mp3 = os.path.join(out_dir, f"{voice_id}.mp3")

    p = subprocess.run(
        [sys.executable, "-m", "piper", "-m", model_path,
         "--length-scale", str(length_scale), "-f", wav],
        input=text.encode("utf-8"),
        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
    )
    if p.returncode != 0:
        print(f"  FAIL {language}/{voice_id}: piper -> {p.stderr.decode()[:200]}")
        return False

    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", wav,
         "-codec:a", "libmp3lame", "-b:a", "128k", "-ar", "44100", mp3],
        check=True,
    )
    os.remove(wav)
    print(f"  OK   {language}/{voice_id}.mp3  ({model})")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models-dir", required=True,
                    help="Directory holding Piper *.onnx + *.onnx.json models")
    args = ap.parse_args()

    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg not found on PATH")

    total = ok = 0
    for language, voices in VOICES.items():
        for voice_id, (model, ls) in voices.items():
            text = PROMPTS.get(language, {}).get(voice_id)
            if not text:
                print(f"  SKIP {language}/{voice_id}: no prompt text")
                continue
            total += 1
            ok += gen_one(args.models_dir, language, voice_id, model, ls, text)
    print(f"\nGenerated {ok}/{total} clips into {OUT_ROOT}/<language>/")


if __name__ == "__main__":
    main()
