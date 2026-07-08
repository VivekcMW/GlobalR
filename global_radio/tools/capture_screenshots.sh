#!/usr/bin/env bash
# Guided store-screenshot capture from the booted iOS simulator.
#
# Usage:
#   1. Launch the app in the simulator (flutter run).
#   2. Run this script from anywhere: ./tools/capture_screenshots.sh
#   3. Navigate to each screen when prompted, then press Enter to capture.
#
# Output: docs/store-assets/screenshots/*.png (1206x2622 on iPhone 16 Pro,
# accepted by App Store Connect for the 6.3" display tier).

set -euo pipefail

UDID="${SIM_UDID:-booted}"
OUT="$(cd "$(dirname "$0")/../.." && pwd)/docs/store-assets/screenshots"
mkdir -p "$OUT"

shots=(
  "01-onboarding-language|Onboarding: language selection grid (delete + reinstall app, or Settings > reset onboarding)"
  "02-onboarding-interests|Onboarding: interest selection screen"
  "03-home|Home tab: 'Your radio is ready' hero + station list"
  "04-now-playing|Player: full-screen Now Playing with the diya disc animating"
  "05-library|Saved tab: downloaded/saved items"
  "06-settings|You tab / Settings: language, voice, text size options"
)

echo "Capturing to: $OUT"
echo "Simulator: $UDID"
echo

for entry in "${shots[@]}"; do
  name="${entry%%|*}"
  desc="${entry#*|}"
  printf '>> %s\n   %s\n   Navigate there, then press Enter (or s + Enter to skip)... ' "$name" "$desc"
  read -r answer
  if [[ "$answer" == "s" ]]; then
    echo "   skipped"
    continue
  fi
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png"
  echo "   saved $name.png"
done

echo
echo "Done. Files in $OUT:"
ls -la "$OUT"
