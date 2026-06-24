import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';

/// A festival or event definition.
class Festival {
  final String id;
  final String name;
  final Map<String, String> namesRegional;
  final List<DateTime> dates;
  final String type;
  final List<String> religions;
  final List<String> regions;
  final List<String> contentTags;
  final String icon;

  const Festival({
    required this.id,
    required this.name,
    required this.namesRegional,
    required this.dates,
    required this.type,
    required this.religions,
    required this.regions,
    required this.contentTags,
    required this.icon,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      id: json['id'] as String,
      name: json['name'] as String,
      namesRegional: Map<String, String>.from(json['names_regional'] ?? {}),
      dates: (json['dates'] as List<dynamic>)
          .map((d) => DateTime.parse(d as String))
          .toList(),
      type: json['type'] as String,
      religions: List<String>.from(json['religions'] ?? []),
      regions: List<String>.from(json['regions'] ?? []),
      contentTags: List<String>.from(json['content_tags'] ?? []),
      icon: json['icon'] as String? ?? '🎉',
    );
  }

  /// Get localized name for a language, fallback to default name.
  String localizedName(String language) {
    return namesRegional[language] ?? name;
  }

  /// Get the next upcoming date from now.
  DateTime? get nextDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final date in dates) {
      if (date.isAfter(today) || _isSameDay(date, today)) {
        return date;
      }
    }
    return null;
  }

  /// Check if festival is today.
  bool get isToday {
    final now = DateTime.now();
    return dates.any((d) => _isSameDay(d, now));
  }

  /// Check if festival is within the next N days.
  bool isWithinDays(int days) {
    final next = nextDate;
    if (next == null) return false;

    final now = DateTime.now();
    final diff = next.difference(now).inDays;
    return diff >= 0 && diff <= days;
  }

  /// Days until next occurrence.
  int? get daysUntil {
    final next = nextDate;
    if (next == null) return null;

    final now = DateTime.now();
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Festival calendar data.
class FestivalCalendar {
  final List<Festival> festivals;
  final int showDaysBefore;
  final int showDaysAfter;
  final bool autoQueueSpecialContent;
  final bool notificationsEnabled;

  const FestivalCalendar({
    required this.festivals,
    this.showDaysBefore = 3,
    this.showDaysAfter = 1,
    this.autoQueueSpecialContent = true,
    this.notificationsEnabled = true,
  });

  factory FestivalCalendar.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};

    return FestivalCalendar(
      festivals: (json['festivals'] as List<dynamic>)
          .map((f) => Festival.fromJson(f as Map<String, dynamic>))
          .toList(),
      showDaysBefore: settings['show_days_before'] as int? ?? 3,
      showDaysAfter: settings['show_days_after'] as int? ?? 1,
      autoQueueSpecialContent:
          settings['auto_queue_special_content'] as bool? ?? true,
      notificationsEnabled: settings['notifications_enabled'] as bool? ?? true,
    );
  }

  /// Get festivals happening today.
  List<Festival> get todaysFestivals {
    return festivals.where((f) => f.isToday).toList();
  }

  /// Get upcoming festivals within the next N days.
  List<Festival> upcomingFestivals(int days) {
    final upcoming =
        festivals.where((f) => f.isWithinDays(days) && !f.isToday).toList();

    // Sort by date
    upcoming.sort((a, b) {
      final aDate = a.nextDate;
      final bDate = b.nextDate;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    return upcoming;
  }

  /// Get festivals relevant to a user's profile.
  List<Festival> festivalsForProfile({
    String? language,
    String? region,
    List<String>? religions,
  }) {
    return festivals.where((f) {
      // Check region
      if (region != null &&
          !f.regions.contains('all') &&
          !f.regions.contains(region)) {
        return false;
      }

      // Check religion preference (optional filter)
      if (religions != null &&
          religions.isNotEmpty &&
          !f.religions.contains('all')) {
        final hasMatch = religions.any((r) => f.religions.contains(r));
        if (!hasMatch) return false;
      }

      return true;
    }).toList();
  }
}

/// Provider for the festival calendar.
final festivalCalendarProvider = FutureProvider<FestivalCalendar>((ref) async {
  try {
    final jsonString =
        await rootBundle.loadString('assets/catalog/festivals.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return FestivalCalendar.fromJson(json);
  } catch (e) {
    // Return empty calendar on error
    return const FestivalCalendar(festivals: []);
  }
});

/// Provider for today's festivals.
final todaysFestivalsProvider = Provider<List<Festival>>((ref) {
  final calendarAsync = ref.watch(festivalCalendarProvider);
  return calendarAsync.maybeWhen(
    data: (cal) => cal.todaysFestivals,
    orElse: () => [],
  );
});

/// Provider for upcoming festivals (next 7 days).
final upcomingFestivalsProvider = Provider<List<Festival>>((ref) {
  final calendarAsync = ref.watch(festivalCalendarProvider);
  return calendarAsync.maybeWhen(
    data: (cal) => cal.upcomingFestivals(7),
    orElse: () => [],
  );
});

/// Provider for festivals relevant to current user profile.
final relevantFestivalsProvider = Provider<List<Festival>>((ref) {
  final calendarAsync = ref.watch(festivalCalendarProvider);
  final profile = ref.watch(profileProvider);

  return calendarAsync.maybeWhen(
    data: (cal) {
      // Use first language from profile's languages list
      final language = profile.languages.isNotEmpty ? profile.languages.first : null;
      if (language == null) return cal.upcomingFestivals(7);

      return cal.festivalsForProfile(
        language: language,
        region: null, // Region not yet implemented in profile
      );
    },
    orElse: () => [],
  );
});

/// Check if there's a special festival today.
final hasFestivalTodayProvider = Provider<bool>((ref) {
  return ref.watch(todaysFestivalsProvider).isNotEmpty;
});

/// Provider for content tags to boost based on upcoming festivals.
final festivalContentTagsProvider = Provider<List<String>>((ref) {
  final today = ref.watch(todaysFestivalsProvider);
  final upcoming = ref.watch(upcomingFestivalsProvider);

  final tags = <String>{};

  // Add today's festival tags (highest priority)
  for (final f in today) {
    tags.addAll(f.contentTags);
  }

  // Add upcoming festival tags (for 1-2 days out only)
  for (final f in upcoming) {
    final days = f.daysUntil ?? 999;
    if (days <= 2) {
      tags.addAll(f.contentTags);
    }
  }

  return tags.toList();
});
