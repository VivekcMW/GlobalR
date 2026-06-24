# Global Radio — content pipeline (`tools/`)

Generates **real neural-voice MP3s** + a **real `catalog.json`** laid out exactly
like the production Cloudflare R2 / CDN bucket, so the app can run the real
streaming path with `--dart-define=DEMO_AUDIO=false`. No paid API key required:
audio is synthesised with **edge-tts** (free Microsoft neural voices).

```
CDN / R2 layout (also produced under cdn_dist/):
  catalog.json
  {language}/{voiceId}/{itemId}.mp3      # voiceId ∈ male_story | female_warm | devotional
```
The app builds the same URL in `lib/data/models/catalog_item.dart`:
`{CDN_BASE}/{language}/{voiceId}/{itemId}.mp3`.

## One-time setup
```bash
cd global_radio
python3 -m venv tools/.venv && source tools/.venv/bin/activate
pip install edge-tts skyfield        # skyfield only needed for astrology
```

## 1. Build the library (stories + devotion)
```bash
python tools/build_catalog.py                 # all free-voice languages
python tools/build_catalog.py --langs hindi,english   # subset
```
- Source: `tools/content/library.json` (public-domain fables + original
  devotion, with attribution) and `tools/content/voices.json` (preset→voice map).
- Output: real MP3s + `cdn_dist/catalog.json` with measured durations/sizes.

## 2. Generate daily astrology (the engagement driver)
```bash
python tools/astrology_cron.py                # today, all languages
python tools/astrology_cron.py --date 2026-06-24 --keep-days 2
```
- Real Moon phase via **Skyfield + JPL DE421** (public domain); falls back to a
  synodic approximation offline.
- Readings are **original**, deterministic per (date, sign); merged into
  `catalog.json` as `type:"daily"` items, old days pruned. Idempotent → safe for cron.
- Cron (00:30 IST): `30 19 * * * cd /path/global_radio && tools/.venv/bin/python tools/astrology_cron.py --out cdn_dist && tools/deploy_r2.sh`

## 3. Prove the streaming path locally (DEMO_AUDIO=false)
```bash
python tools/serve_cdn.py --dir cdn_dist --port 8787     # R2 emulator (CORS + 206 ranges)
# in another shell:
flutter test test/streaming/cdn_streaming_path_test.dart \
  --dart-define=DEMO_AUDIO=false \
  --dart-define=CDN_BASE=http://localhost:8787 \
  --dart-define=CATALOG_URL=http://localhost:8787/catalog.json
# or run the app on a device (use your LAN IP instead of localhost):
flutter run --dart-define=DEMO_AUDIO=false \
  --dart-define=CDN_BASE=http://192.168.x.x:8787 \
  --dart-define=CATALOG_URL=http://192.168.x.x:8787/catalog.json
```

## 4. Go live on real Cloudflare R2
```bash
./tools/deploy_r2.sh r2 globalradio-cdn cdn_dist   # rclone remote, bucket, src
# then build pointing at the bucket's public domain:
flutter build apk --dart-define=DEMO_AUDIO=false \
  --dart-define=CDN_BASE=https://cdn.globalradio.app \
  --dart-define=CATALOG_URL=https://cdn.globalradio.app/catalog.json
```

## Language coverage
Free edge-tts voices cover **10 of the 13 Tier-1 languages**: hindi, english,
bengali, marathi, telugu, tamil, gujarati, urdu, kannada, malayalam.
**Odia, Punjabi, Assamese** need the paid Azure key (listed in
`voices.json → needs_paid_tts`); add their voices there and re-run — the rest of
the pipeline is unchanged.
