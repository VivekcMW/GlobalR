# Store Privacy Labels — Global Radio

Formal answers for the **Apple App Privacy "nutrition label"** (App Store
Connect → App Privacy) and the **Google Play Data safety form**
(Play Console → App content → Data safety). Derived from the actual data
practices in the app (Firebase Auth/Analytics/Crashlytics/Messaging,
local-first preferences, no ad SDKs).

---

## 1. Apple App Privacy (App Store Connect)

### Data Used to Track You
**None.** The app does not track users across other companies' apps or
websites and contains no advertising SDKs. Do **not** declare tracking;
no ATT prompt is needed.

### Data Linked to You
Only applies when the user signs in (sign-in is optional).

| Data Type | Category | Purpose | Linked | Tracking |
|---|---|---|---|---|
| Email Address | Contact Info | App Functionality (account) | Yes | No |
| Name | Contact Info | App Functionality (account, from Google/Apple sign-in) | Yes | No |
| User ID | Identifiers | App Functionality (account, sync) | Yes | No |

### Data Not Linked to You

| Data Type | Category | Purpose | Linked | Tracking |
|---|---|---|---|---|
| Product Interaction | Usage Data | Analytics, App Functionality (personalised radio sequencing) | No | No |
| Crash Data | Diagnostics | App Functionality (Crashlytics) | No | No |
| Performance Data | Diagnostics | App Functionality | No | No |
| Other Usage Data (language + interest preferences, listening history) | Usage Data | App Functionality (personalisation) | No | No |

### Not Collected
Location, Contacts, Photos/Videos, Audio Data (mic is used only for local
voice search; audio never leaves the device), Health & Fitness, Financial
Info, Browsing History, Search History (kept on-device only), Sensitive Info.

> Note on microphone: the voice-search feature uses the OS speech
> recognizer. Apple's label taxonomy counts "Audio Data" only if collected —
> we do not transmit or store recordings, so it is *not* declared, but
> `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription`
> strings must remain accurate in Info.plist.

---

## 2. Google Play Data safety

**Overview answers**
- Does your app collect or share any of the required user data types? **Yes**
- Is all of the user data collected by your app encrypted in transit? **Yes**
- Do you provide a way for users to request that their data is deleted? **Yes**
  (in-app account deletion in Settings + support@globalradio.app)

**Data types collected**

| Data type | Collected | Shared | Optional | Purpose |
|---|---|---|---|---|
| Personal info → Email address | Yes | No | Yes (only if user signs in) | Account management |
| Personal info → Name | Yes | No | Yes | Account management |
| Personal info → User IDs | Yes | No | Yes | Account management, personalisation |
| App activity → App interactions | Yes | No | No | Analytics, personalisation |
| App activity → Other user-generated content (saved items, interests) | Yes | No | No | App functionality |
| App info & performance → Crash logs | Yes | No | No | Analytics |
| App info & performance → Diagnostics | Yes | No | No | Analytics |

**Not collected:** Location, Financial info, Health & fitness, Photos &
videos, Audio (voice search is processed on-device), Contacts, Calendar,
SMS/Call logs, Browsing history, Installed apps, Device IDs for ads.

**Security practices**
- Data encrypted in transit: **Yes** (HTTPS/TLS everywhere)
- Users can request deletion: **Yes**
- Independent security review: No
- Committed to Play Families policy: N/A (not enrolled in Designed for
  Families; rated Everyone)

---

## 3. Cross-check against the app

| Practice | Where in code |
|---|---|
| Optional sign-in (Google/Apple) | `lib/features/auth/` — app fully usable anonymously |
| Preferences stored locally first | `flutter_secure_storage` / local store providers |
| Analytics events | Firebase Analytics — no ad IDs, no third-party sharing |
| Crash reporting | Firebase Crashlytics |
| Push notifications | Firebase Messaging (token is a User ID under Apple taxonomy — covered above) |
| Voice search | `speech_to_text` on-device; no audio uploaded |
| No ads / no tracking SDKs | `pubspec.yaml` contains no ad or attribution SDKs |

Keep this file in sync with [docs/PRIVACY.md](../PRIVACY.md) and the
Privacy Practices section of
[docs/app-store-listing.md](../app-store-listing.md).

Last reviewed: 2026-07-04
