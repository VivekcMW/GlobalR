# Changelog

All notable changes to Global Radio are documented in this file.

## 2026-07-08

### Added
- **Server-side purchase verification.** New `functions/verifyPurchase` Cloud Function checks Google Play / App Store purchases against the store before granting premium — previously the client granted itself premium locally the instant the purchase sheet opened, with no server check at all.
- **Firestore security rules** (`firestore.rules`): `isPremium` and related entitlement fields on `users/{uid}` can now only be written by the verification Cloud Function; `requests` and `referrals` collections got their first rules (previously unrestricted).
- **`tools/setup_gcp_backend.sh`**: one-command, idempotent setup for a new Firebase/GCP project — adds Firebase, creates the Firestore database (free tier, no billing account needed), publishes `firestore.rules`, and (once billing is enabled) deploys `verifyPurchase` and provisions its service account and Apple shared secret. Chained after `tools/setup_firebase.sh` so handing this project to someone else is a two-script setup.
- Real pack downloads (`pack_downloader.dart`) from Cloud Storage, replacing the simulated progress loop.
- Real read-along transcript sync (`read_along_provider.dart`) — fetches and parses VTT captions instead of a stub.
- Real Android Auto / CarPlay media browsing wired to the actual catalog and offline content (`media_browser_service.dart`), replacing the placeholder hierarchy.
- Real Firebase Remote Config wiring (`remote_config_service.dart`) alongside the debug-defaults fallback.

### Changed
- `payment_service.dart`: `purchaseInApp()` now only starts the store flow and throws on failure instead of returning a misleading bool; entitlement arrives asynchronously via server verification, exposed through `premiumUpdates` and the Firestore-backed `premiumSyncProvider`.
- `voting_service.dart` and `share_service.dart` reworked around live Firestore reads/writes.
- `user_db_service.dart` adds `watchPremiumStatus()`, a live stream that is now the single source of truth for premium status app-wide (`ProfileController.applyRemoteEntitlement`), replacing the old client-writable `setPremium()`.

### Fixed
- **Google Sign-In hanging indefinitely.** Root cause: the Firebase project's Firestore database had never been created, so every post-login profile fetch retried forever against a `NOT_FOUND` database. Created the database (`gcloud`/Firestore Admin API, free tier) — this also unblocks voting and referrals, which hit the same missing database.
- Removed the dead `DevAuthService` mock now that `FirebaseAuthService` is the only auth backend in use.
- `rate_limiter.dart`: certificate pinning TODO resolved to an explicit deny (was silently returning `false` behind a stale comment).

### Security
- Closed a client-side premium spoofing bug: `settings_screen.dart` was granting premium the instant `buyNonConsumable()` returned (which only means the purchase dialog opened, not that payment completed), with no server check and no Firestore rule stopping a client from writing `isPremium: true` directly.
