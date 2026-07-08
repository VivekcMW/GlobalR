/// Weekly listening goal: listen on N of the last 7 days (default 5, tunable
/// via `engage_weekly_goal_days`). Pure computation over the streaks session
/// history — no new storage.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/remote_config_service.dart';
import '../streaks/streaks_service.dart';

class WeeklyGoal {
  /// Count distinct listening days within the last 7 calendar days
  /// (including today).
  static int daysListened(List<DateTime> sessionDates, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 6));
    final days = <String>{};
    for (final d in sessionDates) {
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(windowStart) && !day.isAfter(today)) {
        days.add('${day.year}-${day.month}-${day.day}');
      }
    }
    return days.length;
  }
}

class WeeklyGoalState {
  final int daysListened;
  final int goalDays;

  const WeeklyGoalState({required this.daysListened, required this.goalDays});

  bool get met => daysListened >= goalDays;
  double get progress =>
      goalDays == 0 ? 1 : (daysListened / goalDays).clamp(0.0, 1.0);
}

final weeklyGoalProvider = Provider<WeeklyGoalState>((ref) {
  // Re-compute whenever stats change (i.e. after every completed listen).
  ref.watch(listeningStatsProvider);
  final goalDays = ref.watch(remoteConfigProvider).engageWeeklyGoalDays;
  final sessions = ref.watch(streaksServiceProvider).loadRecentSessions();
  return WeeklyGoalState(
    daysListened: WeeklyGoal.daysListened(
        sessions.map((s) => s.date).toList(), DateTime.now()),
    goalDays: goalDays,
  );
});
