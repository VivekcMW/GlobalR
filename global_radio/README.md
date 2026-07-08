# Global Radio

A personalized "interest radio" for India — an on-device radio engine sequences
a catalog of legally-safe audio (kids' stories, moral stories, devotion, daily
astrology, and more) into a continuous, narrated listening stream across iOS +
Android, in 22 languages + English.

- **Product & architecture docs:** [`../docs/`](../docs/)
- **Local setup, running, architecture:** [`SETUP.md`](./SETUP.md)
- **Firebase / GCP backend setup (Firestore, purchase verification):** [`FIREBASE_README.md`](./FIREBASE_README.md)
- **Content pipeline (stories + neural-voice TTS):** [`tools/README.md`](./tools/README.md)
- **What changed and when:** [`CHANGELOG.md`](./CHANGELOG.md)

## Quick start

```bash
flutter pub get
flutter run                 # DEMO_AUDIO=true by default — plays bundled clips, no backend needed
flutter test
flutter analyze
```

To run against real content and a real backend, see the dart-define flags in
[`lib/core/constants.dart`](./lib/core/constants.dart) (`DEMO_AUDIO`,
`USE_FIREBASE_AUTH`, `USE_ANALYTICS`, etc.) and [`SETUP.md`](./SETUP.md)'s
"Cloud wiring" section.

## Releases (CI/CD)

Pushing a version tag (`vX.Y.Z`) builds and publishes signed release
binaries on GitHub's own runners — no local build required:

| Workflow | Trigger | Produces |
|---|---|---|
| [`.github/workflows/android-release.yml`](../.github/workflows/android-release.yml) | tag `v*`, or manual dispatch | Signed release APK, attached to a GitHub Release |
| [`.github/workflows/ios-build.yml`](../.github/workflows/ios-build.yml) | every push (unsigned compile check); tag `v*` or manual dispatch (signed) | Signed `.ipa` artifact, optional TestFlight upload |
| [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | every push/PR | `flutter analyze` + `flutter test` |

```bash
git tag -a v1.0.2 -m "..."
git push origin v1.0.2
```

Both release workflows read signing material from repo secrets (Settings →
Secrets and variables → Actions) — see the comment block above the
`build-signed` job in `ios-build.yml` for exactly which secrets are needed and
how to generate them, and [`ios/RELEASE_SETUP.md`](./ios/RELEASE_SETUP.md) for
the full Apple-side walkthrough. Android's signing secrets are generated with
[`tools/setup_android_keystore.sh`](./tools/setup_android_keystore.sh).

Both release builds currently point at a **free interim CDN** for real
narrated audio (`raw.githubusercontent.com`, not demo clips) — see
[`tools/FUTURE_FIREBASE_SETUP.md`](./tools/FUTURE_FIREBASE_SETUP.md) for the
plan to migrate to Firebase Storage + Firestore once billing/access are
sorted on the real project.

## Legal note

Content sourcing follows the license rules in
[`../docs/legal-safe-launch-checklist.md`](../docs/legal-safe-launch-checklist.md) —
public domain, CC BY, or commissioned originals only.
