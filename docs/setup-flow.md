# Setup Flow — Global Radio (India Interest Radio)

Step-wise setup flow for building the **Global Radio** Flutter app (iOS + Android, lightweight, data-frugal, no streaming backend).

---

## Phase 1 — Local Environment & Tooling
1. **Install Flutter SDK** (stable channel, 3.x) and verify with `flutter doctor`
2. **Install Dart** (bundled with Flutter)
3. **Install Android Studio** → SDK, emulator, NDK
4. **Install Xcode** (macOS, for iOS simulator + signing)
5. **Install VS Code Flutter/Dart extensions** (or use Android Studio)
6. **Install Firebase CLI** (`npm install -g firebase-tools`) + `flutterfire` CLI

---

## Phase 2 — Project Scaffold
7. `flutter create global_radio --org com.globalradio --platforms ios,android`
8. Set minimum SDK targets: **Android API 23+**, **iOS 13+**
9. Add all core dependencies to `pubspec.yaml`:
   - `just_audio`, `audio_service` — audio engine + background
   - `flutter_riverpod` — state management
   - `isar` + `isar_flutter_libs` — local DB
   - `dio` + `flutter_cache_manager` — HTTP + audio pre-fetch
   - `firebase_core`, `firebase_auth`, `cloud_firestore` — backend
   - `firebase_messaging` — push notifications
   - `google_fonts` (Noto Sans) — typography
   - `flutter_localizations` + `intl` — i18n (22 languages)
   - `razorpay_flutter` (web/Android) + `in_app_purchase` (store IAP)

---

## Phase 3 — Firebase Setup
10. Create Firebase project (`globalradio-prod`)
11. Run `flutterfire configure` → generates `firebase_options.dart`
12. Enable **Firebase Auth** (email, Google, phone OTP)
13. Enable **Firestore** (user profile, prefs, favorites)
14. Enable **FCM** (push notifications)
15. Set Firestore security rules (users can read/write only their own doc)

---

## Phase 4 — CDN / Storage Setup
16. Create **Cloudflare R2** bucket (`globalradio-cdn`) — zero egress cost
17. Define folder structure: `/{lang}/{voiceId}/{itemId}.mp3`
18. Upload seed `catalog.json` (initial MVP items)
19. Set public read access + cache headers

---

## Phase 5 — App Architecture & Folder Structure
20. Create folder structure:
    ```
    lib/
      core/          # constants, theme, router
      data/          # catalog repo, Isar models, Firebase services
      radio_engine/  # filter, scorer, sequencer (pure Dart)
      audio/         # audio service wrapper, queue manager
      features/      # onboarding, home, player, library, settings
      shared/        # widgets, providers
    ```
21. Implement **Material 3 theme** (dark-first, saffron/indigo tokens)
22. Set up **GoRouter** for navigation

---

## Phase 6 — Core Engine
23. Implement `CatalogRepository` (fetch + cache `catalog.json` via `dio`)
24. Implement **Isar schema** (UserPrefs, PlayHistory, Favorites, CatalogItem)
25. Implement **Radio Engine** (filter → score → sequence → queue)
26. Wire `audio_service` + `just_audio` for background playback + lock-screen controls
27. Implement voice URL builder + fallback logic

---

## Phase 7 — Screens
28. **Onboarding** — language picker → interest selector → name (no account required)
29. **Home** — interest cards + "Play Radio" button
30. **Player** — lock-screen style, waveform pulse, skip/fav
31. **Library** — saved/favorited items
32. **Settings** — language, voice preset, subscription status

---

## Phase 8 — Monetization
33. Implement **`in_app_purchase`** for iOS/Android subscription (Rs 99/yr)
34. Implement **Razorpay UPI AutoPay** on web checkout page (max margin)
35. Gate premium features: extra voice presets, no ads, high-quality voice

---

## Phase 9 — Daily Astrology Pipeline
36. Set up **Cloud Function** (Node.js/Python cron, 00:30 IST)
37. Skyfield + JPL ephemeris → generate text → translate → TTS → upload to R2
38. Append `daily` entries to `catalog.json` → send FCM

---

## Phase 10 — QA, Build & Release
39. Run on Android emulator + iOS simulator
40. Localisation QA for each Tier-1 language (Noto Sans rendering check)
41. `flutter build appbundle` (Android) + `flutter build ipa` (iOS)
42. Submit to **Google Play** (internal track) + **App Store** (TestFlight)
