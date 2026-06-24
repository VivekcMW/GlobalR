# Release Keystore Setup

This directory should contain your release keystore file. **Never commit keystore files to version control.**

## Quick Setup (Recommended)

Run the automated setup script:

```bash
bash tools/setup_android_keystore.sh
```

This script will:
1. Generate a new keystore at `keystore/release.keystore`
2. Create `android/key.properties` with your credentials
3. Configure everything for release builds

## Manual Setup

### Generate a New Keystore

Run this command to generate a new keystore:

```bash
keytool -genkey -v -keystore release.keystore -alias global_radio -keyalg RSA -keysize 2048 -validity 10000
```

You'll be prompted for:
- Keystore password
- Key password  
- Your name, organization, location details

### Configure the Build

1. Copy `android/key.properties.template` to `android/key.properties`
2. Fill in your keystore passwords and path
3. Never commit `key.properties` to version control

## Backup Your Keystore

**CRITICAL:** Losing your keystore means you cannot update your app on the Play Store.

- Store a backup in a secure, offline location
- Document the passwords in a password manager
- Consider using Play App Signing for additional safety

## Play App Signing

For added security, enroll in Google Play App Signing:
1. Go to Play Console → App → Setup → App integrity
2. Follow the enrollment process
3. Upload your upload key (this keystore)
4. Google will manage the actual signing key

## Play App Signing

For production apps, enable Play App Signing in the Google Play Console:
1. Go to Release > Setup > App signing
2. Follow the enrollment steps
3. Upload your app signing key

This allows Google to re-sign your app and provides recovery options if you lose your upload key.
