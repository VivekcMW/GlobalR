/// Crash reporting abstraction.
///
/// Uses Firebase Crashlytics when enabled (--dart-define=USE_CRASHLYTICS=true),
/// otherwise logs to console. All uncaught exceptions and Flutter errors are
/// routed through this service.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Abstract crash reporting interface.
abstract class CrashService {
  /// Initialize the crash service.
  Future<void> init();

  /// Record a non-fatal error with optional stack trace.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Log a message for context in crash reports.
  Future<void> log(String message);

  /// Set user identifier for crash reports.
  Future<void> setUserId(String userId);

  /// Set custom key-value pairs for crash reports.
  Future<void> setCustomKey(String key, dynamic value);
}

/// Debug implementation that logs to console.
class DebugCrashService implements CrashService {
  @override
  Future<void> init() async {
    debugPrint('[CrashService] Debug crash service initialized');
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    debugPrint('[CrashService] ${fatal ? "FATAL" : "ERROR"}: $exception');
    if (reason != null) debugPrint('[CrashService] Reason: $reason');
    if (stack != null) debugPrint('[CrashService] Stack:\n$stack');
  }

  @override
  Future<void> log(String message) async {
    debugPrint('[CrashService] Log: $message');
  }

  @override
  Future<void> setUserId(String userId) async {
    debugPrint('[CrashService] User ID: $userId');
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    debugPrint('[CrashService] Custom key: $key = $value');
  }
}
