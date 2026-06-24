#!/usr/bin/env bash
#
# Phase B enablement — wires the app to a REAL Firebase backend for
# Google + Apple + Phone-OTP sign-in. The app code is already done; this script
# walks the credentialed, account-bound steps that only you can do.
#
# Run from the global_radio/ directory:  bash tools/setup_firebase.sh
#
set -euo pipefail
BLUE='\033[1;34m'; YELLOW='\033[1;33m'; GREEN='\033[1;32m'; NC='\033[0m'
step() { echo -e "\n${BLUE}==> $1${NC}"; }
todo() { echo -e "${YELLOW}   MANUAL: $1${NC}"; }

step "0. Prerequisites (one-time)"
echo "   - A Google account (for Firebase)."
echo "   - For Apple sign-in on iOS: an Apple Developer account (\$99/yr)."
command -v firebase >/dev/null || { echo "Installing firebase-tools..."; npm install -g firebase-tools; }
command -v flutterfire >/dev/null || { echo "Installing flutterfire..."; dart pub global activate flutterfire_cli; }
export PATH="$PATH":"$HOME/.pub-cache/bin"

step "1. Sign in to Firebase (opens a browser)"
firebase login

step "2. Create / pick a Firebase project + generate config"
echo "   flutterfire will create lib/firebase_options.dart and the native files"
echo "   (google-services.json, GoogleService-Info.plist), replacing the stubs."
flutterfire configure \
  --platforms=android,ios \
  --ios-bundle-id=com.globalradio.globalRadio \
  --android-package-name=com.globalradio.global_radio

step "3. Enable sign-in providers in the Firebase console"
todo "Authentication → Sign-in method → enable: Phone, Google, Apple."
todo "Phone: add a TEST number (e.g. +91 99999 99999 / code 123456) for dev."

step "4. Google Sign-In — native bits"
todo "Android: add your debug SHA-1 to the Firebase Android app, then re-run"
echo "          flutterfire configure to refresh google-services.json:"
echo "            cd android && ./gradlew signingReport   # copy the debug SHA-1"
todo "iOS: open ios/Runner/GoogleService-Info.plist, copy REVERSED_CLIENT_ID,"
echo "          and add it as a URL scheme: Xcode → Runner → Info → URL Types,"
echo "          or add CFBundleURLTypes to ios/Runner/Info.plist."

step "5. Apple Sign-In (iOS) — needs Apple Developer account"
todo "Xcode → Runner target → Signing & Capabilities → + Sign in with Apple."
echo "          (A template lives at ios/Runner/Runner.entitlements.)"
todo "Firebase console → Apple provider → fill Service ID / Team ID / key."

step "6. Build with the real backend enabled"
echo "   Run on a device/simulator with the flag ON:"
echo -e "${GREEN}     flutter run --dart-define=USE_FIREBASE_AUTH=true${NC}"
echo "   (Default builds omit the flag and keep using the local dev auth.)"

echo -e "\n${GREEN}Done. Phone/Google work on simulators once configured; Apple sign-in"
echo -e "is best verified on a real device.${NC}"
