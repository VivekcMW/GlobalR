import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/catalog_item.dart';
import '../../shared/providers/providers.dart';
import '../festivals/festival_provider.dart';
import '../morning_show/morning_show_provider.dart';
import '../streaks/streaks_service.dart';

export '../festivals/festival_provider.dart' show Festival;
export '../morning_show/morning_show_provider.dart'
    show SequencedShow, DaySegment;
export '../streaks/streaks_service.dart' show ListeningStats;

/// Aggregated content for the Today tab.
class TodayContent {
  final List<CatalogItem> dailyAstrology;
  final List<CatalogItem> dailyStories;
  final List<Festival> todaysFestivals;
  final SequencedShow? morningShow;
  final int currentStreak;
  final bool hasListenedToday;
  final String greeting;
  final String dateFormatted;

  const TodayContent({
    required this.dailyAstrology,
    required this.dailyStories,
    required this.todaysFestivals,
    this.morningShow,
    required this.currentStreak,
    required this.hasListenedToday,
    required this.greeting,
    required this.dateFormatted,
  });

  bool get hasAstrology => dailyAstrology.isNotEmpty;
  bool get hasFestivals => todaysFestivals.isNotEmpty;
  bool get hasMorningShow => morningShow != null;
  bool get hasStreak => currentStreak > 0;
}

/// Provider for today's aggregated content.
final todayContentProvider = Provider<TodayContent>((ref) {
  final catalogAsync = ref.watch(catalogProvider);
  final profile = ref.watch(profileProvider);
  final festivals = ref.watch(relevantFestivalsProvider);
  final morningShow = ref.watch(dailyShowProvider);
  final stats = ref.watch(listeningStatsProvider);
  final segment = ref.watch(daySegmentProvider);

  final catalog = catalogAsync.valueOrNull;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Filter daily astrology items for today
  final dailyAstrology = catalog?.items.where((item) {
        if (!item.isDaily) return false;
        if (!item.interests.contains('astrology')) return false;
        if (!profile.languages.contains(item.language)) return false;
        final itemDate = item.date ?? item.publishedDate;
        if (itemDate == null) return false;
        return itemDate.year == today.year &&
            itemDate.month == today.month &&
            itemDate.day == today.day;
      }).toList() ??
      [];

  // Filter daily stories for today
  final dailyStories = catalog?.items.where((item) {
        if (!item.isDaily) return false;
        if (item.interests.contains('astrology')) return false;
        if (!profile.languages.contains(item.language)) return false;
        final itemDate = item.date ?? item.publishedDate;
        if (itemDate == null) return false;
        return itemDate.year == today.year &&
            itemDate.month == today.month &&
            itemDate.day == today.day;
      }).toList() ??
      [];

  // Today's festivals only
  final todaysFestivals = festivals.where((f) => f.isToday).toList();

  // Generate greeting based on time of day
  final greeting = switch (segment) {
    DaySegment.earlyMorning || DaySegment.morning => 'Good Morning',
    DaySegment.lateMorning || DaySegment.afternoon => 'Good Afternoon',
    DaySegment.evening => 'Good Evening',
    DaySegment.night || DaySegment.lateNight => 'Good Night',
  };

  // Format date
  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final dateFormatted =
      '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

  return TodayContent(
    dailyAstrology: dailyAstrology,
    dailyStories: dailyStories,
    todaysFestivals: todaysFestivals,
    morningShow: morningShow,
    currentStreak: stats.currentStreak,
    hasListenedToday: stats.hasListenedToday,
    greeting: greeting,
    dateFormatted: dateFormatted,
  );
});

/// Zodiac signs for astrology selection.
class ZodiacSign {
  final String id;
  final String name;
  final String nameHindi;
  final String icon;
  final DateTime startDate;
  final DateTime endDate;

  ZodiacSign({
    required this.id,
    required this.name,
    required this.nameHindi,
    required this.icon,
    required this.startDate,
    required this.endDate,
  });

  bool isCurrentSign(DateTime date) {
    final thisYear = DateTime(2024, date.month, date.day);
    final start = DateTime(2024, startDate.month, startDate.day);
    final end = DateTime(2024, endDate.month, endDate.day);

    if (start.isAfter(end)) {
      // Sign spans year boundary (e.g., Capricorn: Dec 22 - Jan 19)
      return thisYear.isAfter(start) ||
          thisYear.isBefore(end) ||
          thisYear.isAtSameMomentAs(start) ||
          thisYear.isAtSameMomentAs(end);
    }
    return (thisYear.isAfter(start) || thisYear.isAtSameMomentAs(start)) &&
        (thisYear.isBefore(end) || thisYear.isAtSameMomentAs(end));
  }
}

/// All zodiac signs.
final zodiacSigns = [
  ZodiacSign(
    id: 'aries',
    name: 'Aries',
    nameHindi: 'मेष',
    icon: '♈',
    startDate: DateTime(2024, 3, 21),
    endDate: DateTime(2024, 4, 19),
  ),
  ZodiacSign(
    id: 'taurus',
    name: 'Taurus',
    nameHindi: 'वृषभ',
    icon: '♉',
    startDate: DateTime(2024, 4, 20),
    endDate: DateTime(2024, 5, 20),
  ),
  ZodiacSign(
    id: 'gemini',
    name: 'Gemini',
    nameHindi: 'मिथुन',
    icon: '♊',
    startDate: DateTime(2024, 5, 21),
    endDate: DateTime(2024, 6, 20),
  ),
  ZodiacSign(
    id: 'cancer',
    name: 'Cancer',
    nameHindi: 'कर्क',
    icon: '♋',
    startDate: DateTime(2024, 6, 21),
    endDate: DateTime(2024, 7, 22),
  ),
  ZodiacSign(
    id: 'leo',
    name: 'Leo',
    nameHindi: 'सिंह',
    icon: '♌',
    startDate: DateTime(2024, 7, 23),
    endDate: DateTime(2024, 8, 22),
  ),
  ZodiacSign(
    id: 'virgo',
    name: 'Virgo',
    nameHindi: 'कन्या',
    icon: '♍',
    startDate: DateTime(2024, 8, 23),
    endDate: DateTime(2024, 9, 22),
  ),
  ZodiacSign(
    id: 'libra',
    name: 'Libra',
    nameHindi: 'तुला',
    icon: '♎',
    startDate: DateTime(2024, 9, 23),
    endDate: DateTime(2024, 10, 22),
  ),
  ZodiacSign(
    id: 'scorpio',
    name: 'Scorpio',
    nameHindi: 'वृश्चिक',
    icon: '♏',
    startDate: DateTime(2024, 10, 23),
    endDate: DateTime(2024, 11, 21),
  ),
  ZodiacSign(
    id: 'sagittarius',
    name: 'Sagittarius',
    nameHindi: 'धनु',
    icon: '♐',
    startDate: DateTime(2024, 11, 22),
    endDate: DateTime(2024, 12, 21),
  ),
  ZodiacSign(
    id: 'capricorn',
    name: 'Capricorn',
    nameHindi: 'मकर',
    icon: '♑',
    startDate: DateTime(2024, 12, 22),
    endDate: DateTime(2024, 1, 19),
  ),
  ZodiacSign(
    id: 'aquarius',
    name: 'Aquarius',
    nameHindi: 'कुंभ',
    icon: '♒',
    startDate: DateTime(2024, 1, 20),
    endDate: DateTime(2024, 2, 18),
  ),
  ZodiacSign(
    id: 'pisces',
    name: 'Pisces',
    nameHindi: 'मीन',
    icon: '♓',
    startDate: DateTime(2024, 2, 19),
    endDate: DateTime(2024, 3, 20),
  ),
];

/// Provider for selected zodiac sign.
final selectedSignProvider = StateProvider<ZodiacSign?>((ref) {
  // Auto-detect sign based on current date
  final now = DateTime.now();
  for (final sign in zodiacSigns) {
    if (sign.isCurrentSign(now)) {
      return sign;
    }
  }
  return null;
});

/// Provider for astrology content for selected sign.
final signAstrologyProvider = Provider<CatalogItem?>((ref) {
  final content = ref.watch(todayContentProvider);
  final selectedSign = ref.watch(selectedSignProvider);

  if (selectedSign == null || content.dailyAstrology.isEmpty) return null;

  // Find astrology content matching the selected sign
  return content.dailyAstrology.cast<CatalogItem?>().firstWhere(
        (item) => item?.sign?.toLowerCase() == selectedSign.id.toLowerCase(),
        orElse: () => content.dailyAstrology.firstOrNull,
      );
});
