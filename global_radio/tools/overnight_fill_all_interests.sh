#!/bin/bash
# One-shot overnight job: scrape + translate + promote + build audio + build
# images for every currently-empty interest, then deploy to the interim CDN.
set -uo pipefail
cd "$(dirname "$0")"
VENV_PY="./.venv/Scripts/python.exe"
export PYTHONIOENCODING=utf-8

EMPTY_INTERESTS="mantras yoga science technology biography comedy drama music poetry fiction cooking travel relationships business sports politics culture festivals"

echo "=== [1/7] Scraping all empty interests: $EMPTY_INTERESTS ==="
for interest in $EMPTY_INTERESTS; do
  query=$("$VENV_PY" -c "from harvest_top_interests import INTEREST_QUERIES; print(INTEREST_QUERIES.get('$interest', '$interest story'))")
  echo "--- $interest -> query: $query ---"
  "$VENV_PY" ingest_public_sources.py --source wikisource --language english \
    --query "$query" --interest "$interest" --limit 8 || echo "[degraded] $interest scrape failed, continuing"
done

echo "=== [2/7] Translating every new draft to all 10 languages ==="
"$VENV_PY" translate_fanout.py --all || echo "[degraded] translate fanout failed, continuing"

echo "=== [3/7] Auto-promoting drafts into the live catalog (no review) ==="
"$VENV_PY" auto_promote_drafts.py

echo "=== [4/7] Rebuilding catalog + rendering audio for new items ==="
"$VENV_PY" build_catalog.py --out ../cdn_dist

echo "=== [5/7] Fetching real photos for non-fiction content (Wikipedia/Commons) ==="
"$VENV_PY" fetch_commons_images.py --out ../cdn_dist || echo "[degraded] commons fetch failed, continuing"

echo "=== [6/7] Generating AI images for whatever still needs one (fiction + non-fiction misses) ==="
"$VENV_PY" build_story_images.py --panels 4 --out ../cdn_dist

echo "=== [7/7] Deploying to the interim CDN repo (prince11jose/globalradio-cdn-content) ==="
DEPLOY_DIR="/tmp/globalradio-cdn-content-deploy"
rm -rf "$DEPLOY_DIR"
git clone git@github.com:prince11jose/globalradio-cdn-content.git "$DEPLOY_DIR"
cp -r ../cdn_dist/. "$DEPLOY_DIR/"
cd "$DEPLOY_DIR"
git add -A
if git diff --cached --quiet; then
  echo "nothing new to deploy"
else
  git commit -m "Add content for previously-empty interests + story illustration strips"
  git push origin main
fi

echo "=== ALL DONE ==="
