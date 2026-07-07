/// Engagement glue: called from the radio controller and onboarding to keep
/// the streak-rescue / personal-nudge notifications and milestone
/// celebrations in sync with actual listening.
///
/// Guardrails enforced here:
///  * nothing fires while Kids Mode is on,
///  * every mechanic sits behind its own Remote Config kill switch,
///  * all local notifications respect quiet hours (see [QuietHours]).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/config/remote_config_service.dart';
import '../../shared/providers/providers.dart';
import '../kids_mode/kids_mode_provider.dart';
import '../streaks/streaks_service.dart';
import 'engagement_notifications.dart';
import 'habit_clock.dart';
import 'milestones.dart';

class EngagementController {
  EngagementController(this.ref);
  final Ref ref;

  bool get _blocked => ref.read(kidsModeProvider);
  RemoteConfig get _rc => ref.read(remoteConfigProvider);

  void _log(String kind, String action) {
    ref
        .read(analyticsServiceProvider)
        .logEvent(EngagementNudgeEvent(kind: kind, action: action))
        .catchError((_) {});
  }

  /// A listening session started: learn the habitual hour and (re)schedule
  /// the personal nudge just before it.
  Future<void> onSessionStart() async {
    if (_blocked) return;
    try {
      final clock = ref.read(habitClockProvider);
      await clock.recordSessionStart(DateTime.now());
      if (!_rc.engagePersonalPushEnabled) return;
      final habitHour = clock.habitHour;
      if (habitHour == null) return;
      await ref
          .read(engagementNotificationServiceProvider)
          .schedulePersonalNudge(habitHour);
      _log('personal_nudge', 'scheduled');
    } catch (e) {
      debugPrint('Engagement onSessionStart failed: $e');
    }
  }

  /// An item finished playing: today is safe, so move the streak rescue to
  /// tomorrow 19:00 and check for a newly crossed milestone.
  Future<void> onItemListened() async {
    if (_blocked) return;
    try {
      final stats = ref.read(listeningStatsProvider);
      if (_rc.engageStreakRescueEnabled && stats.currentStreak > 0) {
        await ref
            .read(engagementNotificationServiceProvider)
            .scheduleStreakRescue(stats.currentStreak);
        _log('streak_rescue', 'scheduled');
      }
      if (_rc.engageMilestonesEnabled) {
        final store = ref.read(localStoreProvider);
        final last = store.getSetting<int>(Milestones.storeKey) ?? 0;
        final crossed = Milestones.newlyCrossed(last, stats.currentStreak);
        if (crossed != null) {
          ref.read(pendingMilestoneProvider.notifier).state = crossed;
        }
      }
    } catch (e) {
      debugPrint('Engagement onItemListened failed: $e');
    }
  }

  /// Onboarding just finished: pull them back tomorrow morning.
  Future<void> onOnboardingComplete() async {
    if (_blocked) return;
    if (!_rc.engagePersonalPushEnabled) return;
    try {
      await ref.read(engagementNotificationServiceProvider).scheduleDay2Hook();
      _log('day2_hook', 'scheduled');
    } catch (e) {
      debugPrint('Engagement day-2 hook failed: $e');
    }
  }
}

final engagementControllerProvider =
    Provider<EngagementController>((ref) => EngagementController(ref));
