# iOS Release Setup Guide

This guide covers the steps needed to prepare your iOS app for App Store release.

## Prerequisites

1. Apple Developer Program membership ($99/year)
2. Xcode with command line tools installed
3. Access to Apple Developer Portal

## Step 1: Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Click Identifiers → + to create new App ID
4. Select "App IDs" and "App"
5. Set Bundle ID: `com.globalradio.global_radio`
6. Enable required capabilities:
   - Push Notifications
   - Sign in with Apple
   - In-App Purchase
   - Associated Domains (for deep linking)

## Step 2: Create Certificates

### Distribution Certificate
1. In Keychain Access, create a Certificate Signing Request (CSR)
2. In Apple Developer Portal → Certificates → +
3. Select "Apple Distribution"
4. Upload your CSR
5. Download and double-click to install

### Push Notification Certificate (optional, for FCM)
1. In Identifiers, select your App ID
2. Configure Push Notifications
3. Create and download the certificate

## Step 3: Create Provisioning Profile

1. Go to Profiles → +
2. Select "App Store Connect"
3. Select your App ID
4. Select your distribution certificate
5. Name it: `Global Radio App Store`
6. Download and double-click to install

## Step 4: Configure Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. In Signing & Capabilities:
   - Uncheck "Automatically manage signing"
   - Select your Team
   - Select the provisioning profile you created
4. Add required capabilities:
   - Background Modes → Audio, AirPlay, and Picture in Picture
   - Push Notifications
   - Sign in with Apple
   - In-App Purchase
   - Associated Domains

## Step 5: Update Info.plist

Ensure these keys are set in `ios/Runner/Info.plist`:

```xml
<!-- Background audio -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<!-- Microphone for voice search -->
<key>NSMicrophoneUsageDescription</key>
<string>Global Radio needs microphone access for voice search</string>

<!-- Speech recognition -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>Global Radio needs speech recognition for voice commands</string>
```

## Step 6: Build for Release

```bash
# Build iOS release
flutter build ipa

# Or with specific configuration
flutter build ipa --release --dart-define=USE_FIREBASE_AUTH=true --dart-define=USE_ANALYTICS=true
```

## Step 7: Upload to App Store Connect

### Using Xcode
1. Open `build/ios/archive/Runner.xcarchive` in Xcode Organizer
2. Click "Distribute App"
3. Select "App Store Connect"
4. Follow the upload wizard

### Using Transporter
1. Open Transporter app
2. Drag the `.ipa` file from `build/ios/ipa/`
3. Sign in and upload

## Step 8: App Store Connect Setup

1. Create new app in App Store Connect
2. Fill in app information
3. Upload screenshots (see App Store Screenshots task)
4. Submit for review

## Fastlane (Optional)

For automated builds, install fastlane:

```bash
cd ios
bundle init
echo "gem 'fastlane'" >> Gemfile
bundle install
bundle exec fastlane init
```

Create `ios/fastlane/Fastfile`:
```ruby
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_testflight
  end
end
```

## Troubleshooting

### "No signing certificate found"
- Ensure your distribution certificate is installed in Keychain
- Check certificate hasn't expired

### "Provisioning profile doesn't include signing certificate"
- Recreate the provisioning profile with your current certificate

### "Missing entitlements"
- Add required capabilities in Xcode
- Regenerate provisioning profile after adding capabilities

### "Push notifications not working"
- Verify APNs certificate is configured in Firebase Console
- Check `GoogleService-Info.plist` is properly configured

## Pre-Submission Checklist

```
[ ] Apple Developer membership active
[ ] App ID created with bundle identifier: com.globalradio.global_radio
[ ] Distribution certificate installed in Keychain
[ ] Provisioning profile created and downloaded
[ ] Capabilities enabled in Xcode:
    [ ] Push Notifications
    [ ] Sign in with Apple
    [ ] In-App Purchase
    [ ] Background Modes (audio, fetch, remote-notification)
    [ ] Associated Domains (for deep linking)
[ ] Info.plist contains all required usage descriptions
[ ] GoogleService-Info.plist added to Runner folder
[ ] ExportOptions.plist configured correctly
[ ] App icon added to Assets.xcassets
[ ] Launch screen configured
[ ] flutter build ipa completes without errors
[ ] TestFlight build uploaded and tested
```

## Quick Commands Reference

```bash
# Clean build
flutter clean && flutter pub get

# Build release IPA
flutter build ipa --release

# Build with all features enabled
flutter build ipa --release \
  --dart-define=USE_FIREBASE_AUTH=true \
  --dart-define=USE_ANALYTICS=true \
  --dart-define=USE_CRASHLYTICS=true

# Open Xcode workspace
open ios/Runner.xcworkspace

# Archive from command line (requires configured signing)
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  archive
```
