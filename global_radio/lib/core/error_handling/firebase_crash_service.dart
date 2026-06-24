/// Firebase Crashlytics implementation of CrashService.
///
/// Active only when USE_CRASHLYTICS=true. Requires Firebase to be configured.
library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'crash_service.dart';

/// Firebase Crashlytics implementation.
class FirebaseCrashService implements CrashService {
  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  Future<void> init() async {
    // Enable crashlytics collection
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  @override
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  @override
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }
}
