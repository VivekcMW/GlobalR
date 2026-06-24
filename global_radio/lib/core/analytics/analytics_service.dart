import 'analytics_events.dart';

/// Abstract analytics service interface.
/// 
/// Implementations can use Firebase Analytics, PostHog, Amplitude, etc.
/// The app uses a single instance via Riverpod provider.
abstract class AnalyticsService {
  /// Initialize the analytics service (call once at app start).
  Future<void> initialize();

  /// Log a typed analytics event.
  Future<void> logEvent(AnalyticsEvent event);

  /// Set a user property that persists across events.
  Future<void> setUserProperty(String name, String? value);

  /// Set the user ID for cross-device tracking.
  Future<void> setUserId(String? userId);

  /// Log the current screen for screen flow analysis.
  Future<void> setCurrentScreen(String screenName, {String? screenClass});

  /// Enable or disable analytics collection (for GDPR compliance).
  Future<void> setAnalyticsCollectionEnabled(bool enabled);
}

/// No-op analytics service for development or when analytics is disabled.
class NoopAnalyticsService implements AnalyticsService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCurrentScreen(String screenName, {String? screenClass}) async {}

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}
}

/// Debug analytics service that prints events to console.
class DebugAnalyticsService implements AnalyticsService {
  @override
  Future<void> initialize() async {
    print('[Analytics] Initialized (debug mode)');
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    print('[Analytics] ${event.name}: ${event.parameters}');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    print('[Analytics] User property: $name = $value');
  }

  @override
  Future<void> setUserId(String? userId) async {
    print('[Analytics] User ID: $userId');
  }

  @override
  Future<void> setCurrentScreen(String screenName, {String? screenClass}) async {
    print('[Analytics] Screen: $screenName ($screenClass)');
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    print('[Analytics] Collection enabled: $enabled');
  }
}
