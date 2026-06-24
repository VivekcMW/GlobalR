import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Listening statistics and streak data.
class ListeningStats {
  final int currentStreak;
  final int longestStreak;
  final int totalMinutesListened;
  final int totalItemsPlayed;
  final DateTime? lastListenedDate;
  final Map<String, int> minutesByCategory;
  final Map<String, int> minutesByLanguage;
  final List<String> topCategories;
  final int weeklyMinutes;
  final int monthlyMinutes;

  const ListeningStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalMinutesListened = 0,
    this.totalItemsPlayed = 0,
    this.lastListenedDate,
    this.minutesByCategory = const {},
    this.minutesByLanguage = const {},
    this.topCategories = const [],
    this.weeklyMinutes = 0,
    this.monthlyMinutes = 0,
  });

  ListeningStats copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalMinutesListened,
    int? totalItemsPlayed,
    DateTime? lastListenedDate,
    Map<String, int>? minutesByCategory,
    Map<String, int>? minutesByLanguage,
    List<String>? topCategories,
    int? weeklyMinutes,
    int? monthlyMinutes,
  }) {
    return ListeningStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalMinutesListened: totalMinutesListened ?? this.totalMinutesListened,
      totalItemsPlayed: totalItemsPlayed ?? this.totalItemsPlayed,
      lastListenedDate: lastListenedDate ?? this.lastListenedDate,
      minutesByCategory: minutesByCategory ?? this.minutesByCategory,
      minutesByLanguage: minutesByLanguage ?? this.minutesByLanguage,
      topCategories: topCategories ?? this.topCategories,
      weeklyMinutes: weeklyMinutes ?? this.weeklyMinutes,
      monthlyMinutes: monthlyMinutes ?? this.monthlyMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalMinutesListened': totalMinutesListened,
        'totalItemsPlayed': totalItemsPlayed,
        'lastListenedDate': lastListenedDate?.toIso8601String(),
        'minutesByCategory': minutesByCategory,
        'minutesByLanguage': minutesByLanguage,
        'topCategories': topCategories,
        'weeklyMinutes': weeklyMinutes,
        'monthlyMinutes': monthlyMinutes,
      };

  factory ListeningStats.fromJson(Map<String, dynamic> json) {
    return ListeningStats(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalMinutesListened: json['totalMinutesListened'] as int? ?? 0,
      totalItemsPlayed: json['totalItemsPlayed'] as int? ?? 0,
      lastListenedDate: json['lastListenedDate'] != null
          ? DateTime.parse(json['lastListenedDate'] as String)
          : null,
      minutesByCategory:
          Map<String, int>.from(json['minutesByCategory'] ?? {}),
      minutesByLanguage:
          Map<String, int>.from(json['minutesByLanguage'] ?? {}),
      topCategories: List<String>.from(json['topCategories'] ?? []),
      weeklyMinutes: json['weeklyMinutes'] as int? ?? 0,
      monthlyMinutes: json['monthlyMinutes'] as int? ?? 0,
    );
  }

  /// Get hours and minutes from total minutes.
  (int hours, int minutes) get totalTime {
    final hours = totalMinutesListened ~/ 60;
    final minutes = totalMinutesListened % 60;
    return (hours, minutes);
  }

  /// Check if user has listened today.
  bool get hasListenedToday {
    if (lastListenedDate == null) return false;
    final now = DateTime.now();
    return _isSameDay(lastListenedDate!, now);
  }

  /// Check if streak is at risk (didn't listen yesterday).
  bool get isStreakAtRisk {
    if (lastListenedDate == null || currentStreak == 0) return false;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return !_isSameDay(lastListenedDate!, now) &&
        !_isSameDay(lastListenedDate!, yesterday);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Daily listening session record.
class DailySession {
  final DateTime date;
  final int minutesListened;
  final int itemsPlayed;
  final List<String> categories;

  const DailySession({
    required this.date,
    required this.minutesListened,
    required this.itemsPlayed,
    required this.categories,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minutesListened': minutesListened,
        'itemsPlayed': itemsPlayed,
        'categories': categories,
      };

  factory DailySession.fromJson(Map<String, dynamic> json) {
    return DailySession(
      date: DateTime.parse(json['date'] as String),
      minutesListened: json['minutesListened'] as int,
      itemsPlayed: json['itemsPlayed'] as int,
      categories: List<String>.from(json['categories'] ?? []),
    );
  }
}

/// Service for tracking listening streaks and stats.
class StreaksService {
  static const _boxName = 'listening_stats';
  static const _statsKey = 'stats';
  static const _sessionsKey = 'sessions';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Load current stats.
  ListeningStats loadStats() {
    final json = _box?.get(_statsKey) as Map?;
    if (json == null) return const ListeningStats();
    return ListeningStats.fromJson(Map<String, dynamic>.from(json));
  }

  /// Save stats.
  Future<void> saveStats(ListeningStats stats) async {
    await _box?.put(_statsKey, stats.toJson());
  }

  /// Load recent sessions (last 30 days).
  List<DailySession> loadRecentSessions() {
    final list = _box?.get(_sessionsKey) as List?;
    if (list == null) return [];

    return list
        .map((e) => DailySession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Record listening activity.
  Future<ListeningStats> recordListening({
    required int minutes,
    required String category,
    required String language,
  }) async {
    var stats = loadStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Update streak
    int newStreak = stats.currentStreak;
    if (stats.lastListenedDate == null) {
      newStreak = 1;
    } else {
      final lastDate = stats.lastListenedDate!;
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);

      if (ListeningStats._isSameDay(lastDay, yesterday)) {
        // Continued streak
        newStreak = stats.currentStreak + 1;
      } else if (!ListeningStats._isSameDay(lastDay, today)) {
        // Streak broken
        newStreak = 1;
      }
      // Same day - no change
    }

    // Update category minutes
    final newCategoryMinutes = Map<String, int>.from(stats.minutesByCategory);
    newCategoryMinutes[category] = (newCategoryMinutes[category] ?? 0) + minutes;

    // Update language minutes
    final newLangMinutes = Map<String, int>.from(stats.minutesByLanguage);
    newLangMinutes[language] = (newLangMinutes[language] ?? 0) + minutes;

    // Calculate top categories
    final sortedCategories = newCategoryMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories =
        sortedCategories.take(5).map((e) => e.key).toList();

    // Update stats
    stats = stats.copyWith(
      currentStreak: newStreak,
      longestStreak:
          newStreak > stats.longestStreak ? newStreak : stats.longestStreak,
      totalMinutesListened: stats.totalMinutesListened + minutes,
      totalItemsPlayed: stats.totalItemsPlayed + 1,
      lastListenedDate: now,
      minutesByCategory: newCategoryMinutes,
      minutesByLanguage: newLangMinutes,
      topCategories: topCategories,
    );

    await saveStats(stats);

    // Update daily session
    await _updateDailySession(
      minutes: minutes,
      category: category,
    );

    return stats;
  }

  Future<void> _updateDailySession({
    required int minutes,
    required String category,
  }) async {
    final sessions = loadRecentSessions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find today's session
    final todayIndex = sessions.indexWhere(
      (s) => ListeningStats._isSameDay(s.date, today),
    );

    if (todayIndex >= 0) {
      // Update existing session
      final existing = sessions[todayIndex];
      final categories = Set<String>.from(existing.categories)..add(category);
      sessions[todayIndex] = DailySession(
        date: today,
        minutesListened: existing.minutesListened + minutes,
        itemsPlayed: existing.itemsPlayed + 1,
        categories: categories.toList(),
      );
    } else {
      // Add new session
      sessions.add(DailySession(
        date: today,
        minutesListened: minutes,
        itemsPlayed: 1,
        categories: [category],
      ));
    }

    // Keep only last 30 days
    final cutoff = DateTime(now.year, now.month, now.day - 30);
    sessions.removeWhere((s) => s.date.isBefore(cutoff));

    // Save
    await _box?.put(_sessionsKey, sessions.map((s) => s.toJson()).toList());
  }

  /// Get weekly wrap data.
  Map<String, dynamic> getWeeklyWrap() {
    final sessions = loadRecentSessions();
    final stats = loadStats();
    final now = DateTime.now();
    final weekAgo = DateTime(now.year, now.month, now.day - 7);

    final weekSessions = sessions.where((s) => s.date.isAfter(weekAgo)).toList();

    final totalMinutes =
        weekSessions.fold<int>(0, (sum, s) => sum + s.minutesListened);
    final totalItems =
        weekSessions.fold<int>(0, (sum, s) => sum + s.itemsPlayed);

    // Most listened category this week
    final categoryMinutes = <String, int>{};
    for (final session in weekSessions) {
      for (final cat in session.categories) {
        categoryMinutes[cat] = (categoryMinutes[cat] ?? 0) +
            (session.minutesListened ~/ session.categories.length);
      }
    }

    String? topCategory;
    if (categoryMinutes.isNotEmpty) {
      final sorted = categoryMinutes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sorted.first.key;
    }

    return {
      'totalMinutes': totalMinutes,
      'totalItems': totalItems,
      'daysListened': weekSessions.length,
      'topCategory': topCategory,
      'currentStreak': stats.currentStreak,
      'longestStreak': stats.longestStreak,
    };
  }
}

/// Provider for the streaks service.
final streaksServiceProvider = Provider<StreaksService>((ref) {
  final service = StreaksService();
  service.init();
  return service;
});

/// Provider for current listening stats.
final listeningStatsProvider =
    StateNotifierProvider<ListeningStatsNotifier, ListeningStats>((ref) {
  final service = ref.watch(streaksServiceProvider);
  return ListeningStatsNotifier(service);
});

class ListeningStatsNotifier extends StateNotifier<ListeningStats> {
  final StreaksService _service;

  ListeningStatsNotifier(this._service) : super(const ListeningStats()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    await _service.init();
    state = _service.loadStats();
  }

  Future<void> recordListening({
    required int minutes,
    required String category,
    required String language,
  }) async {
    state = await _service.recordListening(
      minutes: minutes,
      category: category,
      language: language,
    );
  }
}

/// Provider for current streak.
final currentStreakProvider = Provider<int>((ref) {
  return ref.watch(listeningStatsProvider).currentStreak;
});

/// Provider for weekly wrap data.
final weeklyWrapProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(streaksServiceProvider);
  return service.getWeeklyWrap();
});

/// Provider for streak status message.
final streakStatusProvider = Provider<String>((ref) {
  final stats = ref.watch(listeningStatsProvider);

  if (stats.currentStreak == 0) {
    return 'Start your streak today!';
  } else if (stats.hasListenedToday) {
    return '${stats.currentStreak} day streak 🔥';
  } else if (stats.isStreakAtRisk) {
    return 'Streak at risk! Listen now';
  } else {
    return '${stats.currentStreak} days - keep going!';
  }
});
