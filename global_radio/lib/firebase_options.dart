// PLACEHOLDER — replaced by `flutterfire configure`.
//
// Until you run that command (see tools/setup_firebase.sh), this stub throws a
// clear error if Firebase is enabled without configuration. The app default
// (USE_FIREBASE_AUTH=false) never touches this file.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase is not configured yet.\n'
        'Run `flutterfire configure` (see tools/setup_firebase.sh) to generate '
        'real options here, then build with --dart-define=USE_FIREBASE_AUTH=true.',
      );
}
