import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Daily-astrology push: the engagement hook that pairs with the server-side
/// `tools/astrology_cron.py --notify` → `notify_fcm.py`. The cron publishes the
/// day's readings and pushes to FCM topics; the client subscribes to the topics
/// that match the user's profile so the right people get nudged.
///
/// Topics (must match notify_fcm.py):
///   daily_astrology     broadcast — anyone who wants the daily nudge
///   astro_{language}    per-language (e.g. astro_hindi)
///
/// Like auth, this is gated (`AppConfig.usePush`) so default builds run with no
/// backend: [NoopPushService] is used and nothing touches Firebase.
abstract class PushService {
  /// Request permission + register listeners. Safe to call once at startup.
  Future<void> init();

  /// Subscribe to the topics implied by the user's profile and unsubscribe from
  /// any that no longer apply. Call on startup and whenever the profile's
  /// languages/interests change.
  Future<void> syncTopics({
    required List<String> languages,
    required List<String> interests,
  });
}

/// Default no-op used when push is disabled. Keeps the app fully functional
/// with zero backend.
class NoopPushService implements PushService {
  @override
  Future<void> init() async {}

  @override
  Future<void> syncTopics({
    required List<String> languages,
    required List<String> interests,
  }) async {}
}

/// Real FCM implementation. Active only when built with `--dart-define=USE_PUSH=true`
/// AND Firebase is configured (see tools/setup_firebase.sh). Subscribes to the
/// broadcast topic + one topic per chosen language when astrology is an interest.
class FcmPushService implements PushService {
  FcmPushService();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Set<String> _subscribed = <String>{};

  static const String broadcastTopic = 'daily_astrology';

  @override
  Future<void> init() async {
    await _fcm.requestPermission();
    // Foreground messages: the OS doesn't show a tray notification, so surface
    // them here. (Backgrounded/terminated delivery is handled by the OS + the
    // top-level background handler registered in main().)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) {
        debugPrint('[push] foreground: ${n.title} — ${n.body}');
      }
    });
  }

  /// Topics the profile should be subscribed to right now.
  Set<String> _desiredTopics(List<String> languages, List<String> interests) {
    if (!interests.contains('astrology')) return <String>{};
    return {
      broadcastTopic,
      for (final lang in languages) 'astro_$lang',
    };
  }

  @override
  Future<void> syncTopics({
    required List<String> languages,
    required List<String> interests,
  }) async {
    final desired = _desiredTopics(languages, interests);
    // Subscribe to new topics.
    for (final topic in desired.difference(_subscribed)) {
      await _fcm.subscribeToTopic(topic);
    }
    // Unsubscribe from topics that no longer apply (e.g. language removed).
    for (final topic in _subscribed.difference(desired)) {
      await _fcm.unsubscribeFromTopic(topic);
    }
    _subscribed
      ..clear()
      ..addAll(desired);
  }
}
