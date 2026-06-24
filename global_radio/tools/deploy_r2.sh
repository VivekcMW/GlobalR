#!/usr/bin/env bash
# Upload cdn_dist/ to a real Cloudflare R2 bucket — one command to go live.
#
# Prereqs (once):
#   1. Create an R2 bucket (Cloudflare dashboard) and a public r2.dev domain
#      or a custom domain (e.g. cdn.globalradio.app).
#   2. Create an R2 API token (Access Key + Secret).
#   3. Configure rclone:  rclone config  -> new remote "r2", type "s3",
#      provider "Cloudflare", endpoint https://<ACCOUNT_ID>.r2.cloudflarestorage.com
#
# Usage:
#   ./tools/deploy_r2.sh r2 globalradio-cdn cdn_dist
#
# After upload, run the app pointing at the bucket's public URL:
#   flutter build apk \
#     --dart-define=DEMO_AUDIO=false \
#     --dart-define=CDN_BASE=https://cdn.globalradio.app \
#     --dart-define=CATALOG_URL=https://cdn.globalradio.app/catalog.json
set -euo pipefail

REMOTE="${1:-r2}"
BUCKET="${2:-globalradio-cdn}"
SRC="${3:-cdn_dist}"

command -v rclone >/dev/null || { echo "rclone not found: https://rclone.org/install/"; exit 1; }
[ -f "$SRC/catalog.json" ] || { echo "No catalog.json in $SRC — run build_catalog.py first."; exit 1; }

echo "Uploading audio (immutable, long cache)…"
rclone copy "$SRC" "$REMOTE:$BUCKET" \
  --exclude "catalog.json" \
  --header-upload "Cache-Control: public, max-age=31536000, immutable" \
  --transfers 16 --checkers 16 --progress

echo "Uploading catalog.json (short cache, always revalidate)…"
rclone copy "$SRC/catalog.json" "$REMOTE:$BUCKET" \
  --header-upload "Cache-Control: public, max-age=300" --progress

echo "Done. catalog.json + $(find "$SRC" -name '*.mp3' | wc -l | tr -d ' ') mp3 files live on $REMOTE:$BUCKET"
