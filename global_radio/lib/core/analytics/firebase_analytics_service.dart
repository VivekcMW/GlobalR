import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';

/// Firebase Analytics implementation.
/// 
/// Requires firebase_analytics package and Firebase configuration.
/// Active only when USE_ANALYTICS=true build flag is set.
class FirebaseAnalyticsService implements AnalyticsService {
  late final FirebaseAnalytics _analytics;
  late final FirebaseAnalyticsObserver _observer;

  /// Navigation observer for automatic screen tracking with GoRouter.
  FirebaseAnalyticsObserver get observer => _observer;

  @override
  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    // Firebase event names must be alphanumeric with underscores
    final name = event.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    
    // Firebase parameters must be strings, ints, or doubles
    final params = <String, Object>{};
    for (final entry in event.parameters.entries) {
      final value = entry.value;
      if (value is String || value is int || value is double || value is bool) {
        params[entry.key] = value;
      } else {
        params[entry.key] = value.toString();
      }
    }

    await _analytics.logEvent(name: name, parameters: params);
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  @override
  Future<void> setCurrentScreen(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }
}
