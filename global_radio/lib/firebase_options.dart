// PLACEHOLDER — replaced by `flutterfire configure`.
//
// Until you run that command (see tools/setup_firebase.sh), this stub throws a
// clear error if Firebase is enabled without configuration. The app default
// (USE_FIREBASE_AUTH=false) never touches this file.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
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
}
