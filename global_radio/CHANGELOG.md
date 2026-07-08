# Changelog

All notable changes to Global Radio are documented in this file.

## 2026-07-08

### Added
- **Server-side purchase verification.** New `functions/verifyPurchase` Cloud Function checks Google Play / App Store purchases against the store before granting premium — previously the client granted itself premium locally the instant the purchase sheet opened, with no server check at all.
- **Firestore security rules** (`firestore.rules`): `isPremium` and related entitlement fields on `users/{uid}` can now only be written by the verification Cloud Function; `requests` and `referrals` collections got their first rules (previously unrestricted).
- **`tools/setup_gcp_backend.sh`**: one-command, idempotent setup for a Firebase/GCP project — adds Firebase, creates the Firestore database (free tier, no billing account needed), publishes `firestore.rules`, and (once billing is enabled) deploys `verifyPurchase` and provisions its service account and Apple shared secret. Chained after `tools/setup_firebase.sh` so handing this project to someone else is a two-script setup.
- Real Android Auto / CarPlay media browsing wired to the actual catalog and offline content (`media_browser_service.dart`), replacing the placeholder hierarchy.
- Engagement features, home-screen widgets, ads improvements, additional l10n, CI workflows, and the marketing landing site (merged from a parallel work stream — see `docs/engagement-strategy.md` and `docs/ads-placement-strategy.md`).

### Changed
- `payment_service.dart`: `purchaseInApp()` now only starts the store flow and throws on failure instead of returning a misleading bool; entitlement arrives asynchronously via server verification, exposed through `premiumUpdates` and the Firestore-backed `premiumSyncProvider`.
- `user_db_service.dart` adds `watchPremiumStatus()`, a live stream that is now the single source of truth for premium status app-wide (`ProfileController.applyRemoteEntitlement`), replacing the old client-writable `setPremium()`.
- The app now targets Firebase project `globalradio-1f547` (Android + iOS both configured) rather than the `globalir` project used earlier in the day — `globalir` was a placeholder used while these fixes were built and verified; `globalradio-1f547` is the real one going forward. `.firebaserc`, `google-services.json`, and `firebase_options.dart` all point at it now.

### Fixed
- **Google Sign-In hanging indefinitely.** Root cause: the Firebase project's Firestore database had never been created, so every post-login profile fetch retried forever against a `NOT_FOUND` database. Same root cause blocked voting and referrals. Fixed on the (now superseded) `globalir` project as a proof of the fix — **still needs to be applied to `globalradio-1f547`** by running `tools/setup_gcp_backend.sh` with an account that has access to it (see Known Issues).
- Removed the dead `DevAuthService` mock now that `FirebaseAuthService` is the only auth backend in use.
- `rate_limiter.dart`: certificate pinning now does real SHA-256 fingerprint comparison instead of unconditionally denying every certificate.
- `share_widgets.dart`: `AsyncValue.valueOrNull` doesn't exist in the `riverpod` 3.x this project now pins — replaced with `.value`, which is nullable-safe in 3.x (`valueOrNull` was the 2.x name for the same thing).

### Security
- Closed a client-side premium spoofing bug: `settings_screen.dart` was granting premium the instant `buyNonConsumable()` returned (which only means the purchase dialog opened, not that payment completed), with no server check and no Firestore rule stopping a client from writing `isPremium: true` directly.

### Known issues / follow-ups
- **Backend not yet provisioned on the real project.** `tools/setup_gcp_backend.sh` needs to be run against `globalradio-1f547` by someone with GCP access to it (the account used today, `prince11jose@gmail.com`, does not have access). Until then, Google Sign-In on this project will hang the same way it did before today's fix, and `verifyPurchase` isn't deployed.
- **Referral "gift premium" is now local-only.** `referral_screen.dart` used to flip `isPremium` straight to Firestore; since that field is now server-write-only, redeeming a referral gift updates the local profile only (via `applyRemoteEntitlement`) and won't sync across devices or survive an unrelated profile save overwriting it from the Firestore listener. Needs a small server-side grant path (e.g. a callable function) if referral-granted premium should persist for real — out of scope for today's purchase-verification fix.
- Voting (`voting_service.dart`) was intentionally reverted to local-only storage (no Firestore) in the parallel work stream merged today; the `requests` collection rule in `firestore.rules` is currently unused until/unless that's revisited.
