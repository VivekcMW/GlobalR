// Generated from Firebase Console config files (project: globalir).
// Android values come from android/app/google-services.json.
// iOS values come from ios/Runner/GoogleService-Info.plist.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_PYKUZbMMIPkg-Bu6lJoBUXct1yHFv68',
    appId: '1:229658503186:android:12392305ba819ff482d0cb',
    messagingSenderId: '229658503186',
    projectId: 'globalir',
    storageBucket: 'globalir.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCaJUYdzOhi4gSgAKgTFNzs_hE6m90HpKU',
    appId: '1:229658503186:ios:f364506b5850ae8682d0cb',
    messagingSenderId: '229658503186',
    projectId: 'globalir',
    storageBucket: 'globalir.firebasestorage.app',
    iosBundleId: 'com.globalradio.globalRadio',
  );
}
