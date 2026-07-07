# Firebase Integration Guide

The application codebase is fully wired up to use real Firebase services (Firestore, Auth, Analytics, etc.), replacing all local mocks. However, to run the app with these live services, you must provide your own Firebase project configuration files.

Follow these steps to connect the app to your Firebase project:

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and follow the on-screen instructions (you can use your existing `globalir` GCP project if it has billing enabled).
3. Ensure you enable the following services in the Firebase console:
   - **Firestore Database** (Create in production or test mode)
   - **Authentication** (Enable Email/Password, Google, etc. as needed)

## 2. Obtain `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

Instead of manually downloading and placing these files, the easiest way is to use the `flutterfire` CLI which automatically registers your apps and generates the necessary configuration files.

### Install the CLI Tools

If you haven't already, install the Firebase and FlutterFire CLIs:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase (opens a browser window)
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

### Configure the Project

Run the following command from the root of the `global_radio` directory:

```bash
flutterfire configure
```

The CLI will prompt you to:
1. Select your Firebase project (e.g., `globalir`).
2. Select the platforms you want to configure (Android, iOS).

**What this command does:**
- It automatically downloads `google-services.json` and places it in `android/app/`.
- It automatically downloads `GoogleService-Info.plist` and places it in `ios/Runner/`.
- It overwrites the stub `lib/firebase_options.dart` with your actual live Firebase credentials.

## 3. Run the App with Firebase Enabled

By default, the app is configured to compile without Firebase to allow for offline development. To compile and run the app using your new live Firebase configuration, you must pass the compiler flags to enable it:

```bash
flutter run --dart-define=USE_FIREBASE_AUTH=true --dart-define=USE_PUSH=true
```

### Note on Apple Sign-In & Phone Auth
If you are using Apple Sign-In or Phone Auth, ensure you have configured the appropriate Developer Team IDs and SHA-1/SHA-256 fingerprint certificates in the Firebase Console under Project Settings.

## 4. Backend: Firestore database, security rules, and premium verification

Steps 1-3 above only create the client-side config (`google-services.json`,
auth providers). The app also needs a Firestore database, its security
rules, and — if you're selling the premium subscription — a Cloud Function
that verifies purchases server-side. All of this is scripted:

```bash
bash tools/setup_gcp_backend.sh
```

It will ask for:
- **Your Firebase/GCP project ID** (defaults to whatever `flutterfire configure` just wrote to `.firebaserc`)
- **A Firestore region** (defaults to `us-central1`)
- **Your App Store Connect shared secret**, if you want iOS purchases verified (optional — you can skip and add it later; press Enter to skip)

You will need to be signed in to the `gcloud` CLI (`gcloud auth login`) —
the script will prompt for it if you're not.

What it does, and why each piece matters:
1. Adds Firebase to the GCP project and creates the Firestore database (free tier — no billing account needed for this part).
2. Publishes `firestore.rules`, which locks the premium-entitlement fields (`isPremium`, `premiumExpiresAt`, etc.) so only the server can ever set them — without this, anyone could grant themselves premium from the app.
3. If billing is enabled on the project, deploys the `verifyPurchase` Cloud Function (`functions/`), which checks purchases against the Google Play Developer API / Apple's receipt-verification endpoint before granting premium. If billing isn't enabled yet, the script tells you the console link to enable it and skips this step — just re-run the script afterward to finish.

The script is safe to re-run any time (e.g. after enabling billing) — every step checks whether it's already done first.

**Two steps have no CLI/API equivalent and must be done by hand, one time:**
- **Play Console**: Setup → API access → link this GCP project, then grant the `play-billing-verifier` service account (created by the script) "View financial data" + "Manage orders and subscriptions".
- **Apple**: if you skipped the shared secret prompt, get it from App Store Connect → your app → In-App Purchases → App-Specific Shared Secret, then re-run the script.
