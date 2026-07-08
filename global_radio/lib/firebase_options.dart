// Generated from Firebase Console config files (project: globalradio-1f547).
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
    apiKey: 'AIzaSyCWMGy3yTybmGKOwHcdjF7_wjm9pD3K1fY',
    appId: '1:716603335285:android:8810928357fc4fbe9e4e3c',
    messagingSenderId: '716603335285',
    projectId: 'globalradio-1f547',
    storageBucket: 'globalradio-1f547.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA78HCbEsfTY-BCPav1A6pKT80pu7kFAng',
    appId: '1:716603335285:ios:d4ff60940cd8feac9e4e3c',
    messagingSenderId: '716603335285',
    projectId: 'globalradio-1f547',
    storageBucket: 'globalradio-1f547.firebasestorage.app',
    iosBundleId: 'com.globalradio.globalRadio',
  );
}
