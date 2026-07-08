#!/usr/bin/env bash
#
# Deploys the content pipeline's output (tools/build_catalog.py) to Firebase:
#   - audio files -> Firebase Storage (as a public, CDN-style bucket)
#   - catalog.json -> Firestore `catalog_items` collection
#
# Replaces the old Cloudflare R2 plan (tools/deploy_r2.sh) — this project
# already has a Firebase project configured, so it needs no separate CDN
# account. Requires:
#   - gcloud authenticated as an identity with Storage Admin + Firestore
#     write access on the target project (gcloud auth login)
#   - gsutil (ships with the Google Cloud SDK)
#   - node (for the Firestore writer)
#   - cdn_dist/ already built (python tools/build_catalog.py)
#
# Usage:
#   bash tools/deploy_content.sh <gcp-project-id> [bucket-name]
#
# If bucket-name is omitted, defaults to <project-id>.firebasestorage.app
# (the standard Firebase Storage default bucket naming).

set -euo pipefail
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; NC='\033[0m'
step() { echo -e "\n${BLUE}==> $1${NC}"; }
ok()   { echo -e "${GREEN}   $1${NC}"; }
fail() { echo -e "${RED}   ERROR: $1${NC}"; exit 1; }

PROJECT_ID="${1:-}"
BUCKET="${2:-${PROJECT_ID}.firebasestorage.app}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CDN_DIST="$SCRIPT_DIR/../cdn_dist"

[ -n "$PROJECT_ID" ] || fail "Usage: bash tools/deploy_content.sh <gcp-project-id> [bucket-name]"
[ -d "$CDN_DIST" ] || fail "$CDN_DIST not found — run tools/build_catalog.py first."
[ -f "$CDN_DIST/catalog.json" ] || fail "$CDN_DIST/catalog.json not found — run tools/build_catalog.py first."
command -v gsutil >/dev/null 2>&1 || fail "gsutil not found (install the Google Cloud SDK)."
command -v node >/dev/null 2>&1 || fail "node not found."

gcloud config set project "$PROJECT_ID" >/dev/null

step "1. Upload audio files to gs://$BUCKET/audio/"
LANG_DIRS=$(find "$CDN_DIST" -mindepth 1 -maxdepth 1 -type d)
[ -n "$LANG_DIRS" ] || fail "No language directories found under $CDN_DIST."
for dir in $LANG_DIRS; do
  gsutil -m cp -r "$dir" "gs://$BUCKET/audio/"
done
ok "Audio uploaded."

step "2. Make gs://$BUCKET publicly readable (CDN-style, like the audio it serves)"
gsutil iam ch allUsers:objectViewer "gs://$BUCKET" \
  || echo "   (non-fatal — bucket may already be public, or you may need Storage Admin on $PROJECT_ID)"
ok "Bucket read access configured."

step "3. Write catalog items to Firestore (project: $PROJECT_ID)"
node "$SCRIPT_DIR/write_catalog_to_firestore.js" --project="$PROJECT_ID" --catalog="$CDN_DIST/catalog.json"

CDN_URL="https://storage.googleapis.com/$BUCKET/audio"
echo
ok "Done. Build the app pointing at this content with:"
echo "     flutter build apk --release --dart-define=DEMO_AUDIO=false \\"
echo "       --dart-define=CDN_BASE=$CDN_URL \\"
echo "       --dart-define=USE_FIRESTORE_CATALOG=true"
