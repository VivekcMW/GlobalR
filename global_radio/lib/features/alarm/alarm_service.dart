/// Smart alarm: wake up to your Morning Brief.
///
/// Schedules a daily local notification at the user's chosen time that
/// invites them to start the Morning Brief station. Uses
/// flutter_local_notifications + timezone for exact daily scheduling.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/providers/providers.dart';

/// Persisted alarm settings.
class AlarmSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const AlarmSettings({
    this.enabled = false,
    this.hour = 7,
    this.minute = 0,
  });

  AlarmSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return AlarmSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() =>
      {'enabled': enabled, 'hour': hour, 'minute': minute};

  factory AlarmSettings.fromJson(Map<dynamic, dynamic> json) => AlarmSettings(
        enabled: json['enabled'] as bool? ?? false,
        hour: json['hour'] as int? ?? 7,
        minute: json['minute'] as int? ?? 0,
      );

  String get timeLabel {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h12:${minute.toString().padLeft(2, '0')} $ampm';
  }
}

/// Schedules the daily wake-up notification.
class AlarmService {
  static const _notificationId = 7001;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    try {
      tz_data.initializeTimeZones();
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings: initSettings);
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('AlarmService init failed: $e');
      return false;
    }
  }

  /// Request notification permissions (iOS prompt / Android 13+ runtime).
  Future<bool> requestPermissions() async {
    if (!await _ensureInitialized()) return false;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Schedule (or reschedule) the daily alarm notification.
  Future<void> scheduleDaily(int hour, int minute) async {
    if (!await _ensureInitialized()) return;

    final now = tz.TZDateTime.now(tz.local);
    var next =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Good morning! 🌅',
      body: 'Your Morning Brief is ready — news, horoscope and more.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_alarm',
          'Smart Alarm',
          channelDescription: 'Daily wake-up with your Morning Brief',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'morning_brief',
    );
  }

  /// Cancel the daily alarm notification.
  Future<void> cancel() async {
    if (!await _ensureInitialized()) return;
    await _plugin.cancel(id: _notificationId);
  }
}

final alarmServiceProvider = Provider<AlarmService>((ref) => AlarmService());

/// Alarm settings, persisted in local storage.
class AlarmSettingsController extends Notifier<AlarmSettings> {
  static const _key = 'smart_alarm';

  @override
  AlarmSettings build() {
    final saved =
        ref.read(localStoreProvider).getSetting<Map<dynamic, dynamic>>(_key);
    return saved != null ? AlarmSettings.fromJson(saved) : const AlarmSettings();
  }

  Future<void> setEnabled(bool enabled) async {
    final service = ref.read(alarmServiceProvider);
    if (enabled) {
      final granted = await service.requestPermissions();
      if (!granted) return;
      await service.scheduleDaily(state.hour, state.minute);
    } else {
      await service.cancel();
    }
    state = state.copyWith(enabled: enabled);
    await _persist();
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    if (state.enabled) {
      await ref.read(alarmServiceProvider).scheduleDaily(hour, minute);
    }
    await _persist();
  }

  Future<void> _persist() =>
      ref.read(localStoreProvider).putSetting(_key, state.toJson());
}

final alarmSettingsProvider =
    NotifierProvider<AlarmSettingsController, AlarmSettings>(
        AlarmSettingsController.new);
