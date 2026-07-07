/// Engagement local notifications: streak-rescue, personal daily nudge and
/// the day-2 hook. All scheduling respects quiet hours (22:00–07:00) and is
/// modeled on [AlarmService] (flutter_local_notifications + timezone).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Push-guardrail helpers (pure, unit-tested).
class QuietHours {
  /// Bedtime window in which no engagement notification may fire.
  static const start = 22; // 22:00 inclusive
  static const end = 7; // until 07:00 exclusive

  static bool isQuiet(int hour) => hour >= start || hour < end;

  /// Clamp an (hour, minute) pair out of the quiet window: anything inside
  /// 22:00–07:00 moves to 07:30.
  static (int, int) clamp(int hour, int minute) {
    if (!isQuiet(hour)) return (hour, minute);
    return (7, 30);
  }
}

/// Schedules the engagement nudges. One instance per app run.
class EngagementNotificationService {
  static const streakRescueId = 7101;
  static const personalNudgeId = 7102;
  static const day2HookId = 7103;

  static const _channel = AndroidNotificationDetails(
    'engagement',
    'Reminders',
    channelDescription: 'Streak reminders and daily listening nudges',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

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
      debugPrint('EngagementNotifications init failed: $e');
      return false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

  /// One-shot rescue at the next 19:00: fires only if the user has not
  /// listened by then (we cancel + reschedule on every completed listen).
  Future<void> scheduleStreakRescue(int currentStreak) async {
    if (!await _ensureInitialized()) return;
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    // Always aim at *tomorrow* 19:00 — today's listen already happened.
    next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: streakRescueId,
      title: 'Your $currentStreak-day streak is at risk 🔥',
      body: 'One story keeps it alive. Just a few minutes before midnight.',
      scheduledDate: next,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'streak_rescue',
    );
  }

  Future<void> cancelStreakRescue() async {
    if (!await _ensureInitialized()) return;
    await _plugin.cancel(id: streakRescueId);
  }

  /// Daily nudge 15 minutes before the learned habitual hour, clamped out of
  /// quiet hours.
  Future<void> schedulePersonalNudge(int habitHour) async {
    if (!await _ensureInitialized()) return;
    var hour = habitHour - 1;
    var minute = 45; // habitHour − 15 min
    if (hour < 0) hour = 23;
    final (h, m) = QuietHours.clamp(hour, minute);
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: personalNudgeId,
      title: 'Your radio time 🎧',
      body: 'Fresh stories and your daily brief are ready.',
      scheduledDate: next,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'personal_nudge',
    );
  }

  Future<void> cancelPersonalNudge() async {
    if (!await _ensureInitialized()) return;
    await _plugin.cancel(id: personalNudgeId);
  }

  /// One-shot the morning after onboarding: bring them back for day 2.
  Future<void> scheduleDay2Hook() async {
    if (!await _ensureInitialized()) return;
    final now = tz.TZDateTime.now(tz.local);
    final tomorrow = now.add(const Duration(days: 1));
    final (h, m) = QuietHours.clamp(7, 30);
    final next =
        tz.TZDateTime(tz.local, tomorrow.year, tomorrow.month, tomorrow.day, h, m);
    await _plugin.zonedSchedule(
      id: day2HookId,
      title: 'Your morning brief is ready 🌅',
      body: 'News, your rashi and a fresh story — all in one tap.',
      scheduledDate: next,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'day2_hook',
    );
  }

  Future<void> cancelAll() async {
    if (!await _ensureInitialized()) return;
    await _plugin.cancel(id: streakRescueId);
    await _plugin.cancel(id: personalNudgeId);
    await _plugin.cancel(id: day2HookId);
  }
}

final engagementNotificationServiceProvider =
    Provider<EngagementNotificationService>(
        (ref) => EngagementNotificationService());
