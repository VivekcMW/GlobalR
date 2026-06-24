# Global Radio — Project Setup

Flutter (iOS + Android) "interest radio": an on-device radio engine sequences a
static catalog of legally-safe audio into a continuous, personalized stream. No
streaming backend. See `../docs/` for the full product/tech/legal specs.

## What's in this scaffold (runs today, no accounts needed)

| Area | Status | Where |
|---|---|---|
| Flutter app shell + Material 3 dark-first theme (saffron/indigo, Noto Sans) | ✅ | `lib/core/theme.dart` |
| Navigation (GoRouter shell + onboarding/player routes) | ✅ | `lib/core/router.dart` |
| On-device **radio engine** (filter → score → sequence, cold start, re-rank) | ✅ pure Dart, unit-tested | `lib/radio_engine/` |
| Catalog model + repository (CDN → cache → bundled-seed fallback) | ✅ | `lib/data/` |
| Local storage (Hive, no codegen — profile, signals, catalog cache) | ✅ | `lib/data/local/local_store.dart` |
| Background audio (`just_audio` + `audio_service`, lock-screen) | ✅ wired | `lib/audio/audio_handler.dart` |
| 5 screens: Onboarding, Home, Player, Library, Settings | ✅ | `lib/features/` |
| Voice presets + URL builder w/ fallback | ✅ | `lib/core/constants.dart`, `CatalogItem.audioUrlFor` |
| Premium gating (free vs premium voices, upsell) | ✅ via stub | `lib/data/services/payment_service.dart` |
| Seed `catalog.json` (legally-safe sample items) | ✅ | `assets/catalog/catalog.json` |

The app **runs end-to-end now**: onboard → radio builds a queue → mini-player +
full player → favorites/library → settings.

**The real streaming path is now proven** (no DEMO_AUDIO): the `tools/` content
pipeline generates real neural-voice MP3s + a real `catalog.json` (40 library
items + 120 daily astrology items across 10 languages), served from an R2
emulator, and `test/streaming/cdn_streaming_path_test.dart` streams them over
ranged HTTP. See **`tools/README.md`**. With DEMO_AUDIO on (default) it still
plays bundled demo clips so sound works with zero setup.

## Run it

```bash
cd global_radio
flutter pub get
flutter run                 # pick a device (DEMO_AUDIO=true by default)
flutter test                # radio engine unit tests
flutter analyze             # clean
```

Run the **real streaming path** against the local CDN emulator:

```bash
# 1. generate real audio + catalog (see tools/README.md)
python tools/build_catalog.py && python tools/astrology_cron.py
# 2. serve it (R2 emulator with CORS + 206 ranges)
python tools/serve_cdn.py --dir cdn_dist --port 8787
# 3. prove it
flutter test test/streaming/cdn_streaming_path_test.dart \
  --dart-define=DEMO_AUDIO=false \
  --dart-define=CDN_BASE=http://localhost:8787 \
  --dart-define=CATALOG_URL=http://localhost:8787/catalog.json
```

Point at a real CDN/catalog without code changes via dart-defines:

```bash
flutter run \
  --dart-define=DEMO_AUDIO=false \
  --dart-define=CDN_BASE=https://cdn.yourdomain.com \
  --dart-define=CATALOG_URL=https://cdn.yourdomain.com/catalog.json
```

## Cloud wiring (needs external accounts — intentionally stubbed)

These are abstracted behind interfaces so the app builds and runs without them.
Enable when you have the accounts:

### 1. Firebase Auth — Google + Apple + Phone OTP  ✅ code-complete (Phase B)
The full sign-in feature is built and wired behind `AuthService`:
- `firebase_core/firebase_auth/google_sign_in/sign_in_with_apple` are in `pubspec.yaml`.
- `FirebaseAuthService implements AuthService` (`lib/data/services/firebase_auth_service.dart`).
- `main.dart` inits Firebase and the provider swaps Dev→Firebase, both gated on
  `AppConfig.useFirebaseAuth` (default off). Native targets bumped (iOS 15, Android minSdk 23).

By **default the app uses `DevAuthService`** (no backend; OTP dev code `123456`), so it
runs with zero setup. To turn on the real backend, run the guided script — it does the
account-bound steps (`firebase login`, `flutterfire configure`, SHA-1, Apple capability):

```bash
bash tools/setup_firebase.sh
flutter run --dart-define=USE_FIREBASE_AUTH=true
```

You provide: a Firebase project (Google account) and — for Apple sign-in — an Apple
Developer account. Profile/Firestore **sync** is still additive/optional on top of this.

### 2. Cloudflare R2 (catalog.json + MP3s, zero egress)  ✅ pipeline ready
- Bucket layout: `/{lang}/{voiceId}/{itemId}.mp3` (see `AppConfig.cdnBase`)
- Generate real content + catalog locally: `python tools/build_catalog.py`
- One-command upload: `./tools/deploy_r2.sh r2 globalradio-cdn cdn_dist`
- You provide: an R2 bucket + API token + public domain (rclone remote). See `tools/README.md`.

### 3. Payments (docs/design-and-payments-spec.md)
- In-app: add `in_app_purchase`, implement `StorePaymentService implements PaymentService`
- Web (best margin): Razorpay UPI AutoPay on a checkout page
- Entitlement validated server-side (Cloud Function) → Firestore → cached on device

### 4. Daily astrology pipeline (cron)  ✅ implemented
- `tools/astrology_cron.py`: Skyfield (real Moon phase, JPL DE421) → original
  per-sign reading → edge-tts per language → MP3s → append `type:"daily"` items
  to `catalog.json` (idempotent, prunes old days). FCM push is the remaining hook.
- Cron 00:30 IST: `30 19 * * * cd /path/global_radio && tools/.venv/bin/python tools/astrology_cron.py --out cdn_dist && ./tools/deploy_r2.sh`
- Free voices cover 10/13 Tier-1 languages; Odia/Punjabi/Assamese need the paid
  Azure key (`tools/content/voices.json → needs_paid_tts`). See `docs/technical-build-spec.md` §6.

## Architecture

```
lib/
  core/          constants, theme, router
  data/
    models/      CatalogItem, UserProfile, ItemSignals
    local/       LocalStore (Hive)
    repositories/CatalogRepository (dio + cache + bundled fallback)
    services/    AuthService, PaymentService (interfaces + local stubs)
  radio_engine/  RadioEngine (pure Dart — the core IP)
  audio/         GlobalRadioAudioHandler (audio_service + just_audio)
  features/      onboarding, home, player, library, settings
  shared/        providers (Riverpod), widgets (mini-player, nav shell)
```

Data flow: `RadioEngine` builds the queue from profile + catalog + local signals
→ `RadioController` (Riverpod) drives `GlobalRadioAudioHandler` → playback events
update signals → engine re-ranks the queue tail.

## Legal note
Every catalog item carries an `attribution` string and must map to one of the 4
safe zones in `docs/legal-safe-launch-checklist.md` (public domain / CC BY /
own / licensed). The seed catalog uses public-domain + CC BY samples only.
```
