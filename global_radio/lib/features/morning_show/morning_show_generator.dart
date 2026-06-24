import '../../data/models/catalog_item.dart';

/// Time-of-day segments for personalized content.
enum DaySegment {
  earlyMorning, // 4-6 AM
  morning,      // 6-10 AM
  lateMorning,  // 10-12 PM
  afternoon,    // 12-4 PM
  evening,      // 4-7 PM
  night,        // 7-10 PM
  lateNight,    // 10 PM - 4 AM
}

/// A sequenced show with multiple segments.
class SequencedShow {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<ShowSegment> segments;
  final Duration estimatedDuration;
  final DateTime generatedAt;

  const SequencedShow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.segments,
    required this.estimatedDuration,
    required this.generatedAt,
  });

  List<CatalogItem> get allItems => segments.expand((s) => s.items).toList();

  int get totalItems => allItems.length;
}

/// A segment within a sequenced show.
class ShowSegment {
  final String id;
  final String title;
  final String interest;
  final List<CatalogItem> items;
  final Duration duration;

  const ShowSegment({
    required this.id,
    required this.title,
    required this.interest,
    required this.items,
    required this.duration,
  });
}

/// Generates the "Good Morning India" daily smart mix.
class MorningShowGenerator {
  static const _showId = 'good_morning_india';
  
  /// Morning show segment configuration.
  static const _morningSegments = [
    _SegmentConfig(
      id: 'devotion',
      title: 'Morning Prayer',
      interest: 'devotion',
      itemCount: 1,
      maxDuration: Duration(minutes: 5),
    ),
    _SegmentConfig(
      id: 'astrology',
      title: "Today's Horoscope",
      interest: 'astrology',
      itemCount: 1,
      maxDuration: Duration(minutes: 3),
    ),
    _SegmentConfig(
      id: 'news',
      title: 'Morning Headlines',
      interest: 'news',
      itemCount: 1,
      maxDuration: Duration(minutes: 2),
    ),
    _SegmentConfig(
      id: 'motivation',
      title: 'Morning Motivation',
      interest: 'moral',
      itemCount: 1,
      maxDuration: Duration(minutes: 5),
    ),
  ];

  /// Evening show segment configuration.
  static const _eveningSegments = [
    _SegmentConfig(
      id: 'devotion',
      title: 'Evening Prayer',
      interest: 'devotion',
      itemCount: 1,
      maxDuration: Duration(minutes: 5),
    ),
    _SegmentConfig(
      id: 'news',
      title: 'Evening Headlines',
      interest: 'news',
      itemCount: 1,
      maxDuration: Duration(minutes: 2),
    ),
    _SegmentConfig(
      id: 'story',
      title: 'Story Time',
      interest: 'moral',
      itemCount: 2,
      maxDuration: Duration(minutes: 10),
    ),
  ];

  /// Night show segment configuration (for kids).
  static const _nightSegments = [
    _SegmentConfig(
      id: 'kids',
      title: 'Bedtime Story',
      interest: 'kids',
      itemCount: 1,
      maxDuration: Duration(minutes: 8),
    ),
    _SegmentConfig(
      id: 'devotion',
      title: 'Night Prayer',
      interest: 'devotion',
      itemCount: 1,
      maxDuration: Duration(minutes: 3),
    ),
  ];

  final List<CatalogItem> catalog;
  final String language;
  final Set<String> userInterests;
  final String? userSign; // For astrology personalization
  final DateTime now;

  MorningShowGenerator({
    required this.catalog,
    required this.language,
    required this.userInterests,
    this.userSign,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  /// Get the current day segment.
  DaySegment get currentSegment {
    final hour = now.hour;
    if (hour >= 4 && hour < 6) return DaySegment.earlyMorning;
    if (hour >= 6 && hour < 10) return DaySegment.morning;
    if (hour >= 10 && hour < 12) return DaySegment.lateMorning;
    if (hour >= 12 && hour < 16) return DaySegment.afternoon;
    if (hour >= 16 && hour < 19) return DaySegment.evening;
    if (hour >= 19 && hour < 22) return DaySegment.night;
    return DaySegment.lateNight;
  }

  /// Generate the appropriate show for the current time.
  SequencedShow generateShow() {
    switch (currentSegment) {
      case DaySegment.earlyMorning:
      case DaySegment.morning:
        return _generateMorningShow();
      case DaySegment.lateMorning:
      case DaySegment.afternoon:
        return _generateAfternoonShow();
      case DaySegment.evening:
        return _generateEveningShow();
      case DaySegment.night:
      case DaySegment.lateNight:
        return _generateNightShow();
    }
  }

  /// Generate the signature "Good Morning India" show.
  SequencedShow _generateMorningShow() {
    final segments = <ShowSegment>[];
    var totalDuration = Duration.zero;

    for (final config in _morningSegments) {
      final segment = _buildSegment(config);
      if (segment != null) {
        segments.add(segment);
        totalDuration += segment.duration;
      }
    }

    return SequencedShow(
      id: '${_showId}_morning_${_dateKey()}',
      title: 'Good Morning India',
      subtitle: _getGreeting(),
      icon: '🌅',
      segments: segments,
      estimatedDuration: totalDuration,
      generatedAt: now,
    );
  }

  SequencedShow _generateAfternoonShow() {
    final segments = <ShowSegment>[];
    var totalDuration = Duration.zero;

    // Lighter afternoon mix
    const configs = [
      _SegmentConfig(
        id: 'news',
        title: 'Afternoon Update',
        interest: 'news',
        itemCount: 1,
        maxDuration: Duration(minutes: 2),
      ),
      _SegmentConfig(
        id: 'story',
        title: 'Story Break',
        interest: 'moral',
        itemCount: 1,
        maxDuration: Duration(minutes: 5),
      ),
    ];

    for (final config in configs) {
      final segment = _buildSegment(config);
      if (segment != null) {
        segments.add(segment);
        totalDuration += segment.duration;
      }
    }

    return SequencedShow(
      id: '${_showId}_afternoon_${_dateKey()}',
      title: 'Afternoon Break',
      subtitle: 'Take a moment to listen',
      icon: '☀️',
      segments: segments,
      estimatedDuration: totalDuration,
      generatedAt: now,
    );
  }

  SequencedShow _generateEveningShow() {
    final segments = <ShowSegment>[];
    var totalDuration = Duration.zero;

    for (final config in _eveningSegments) {
      final segment = _buildSegment(config);
      if (segment != null) {
        segments.add(segment);
        totalDuration += segment.duration;
      }
    }

    return SequencedShow(
      id: '${_showId}_evening_${_dateKey()}',
      title: 'Good Evening India',
      subtitle: 'Unwind with us',
      icon: '🌆',
      segments: segments,
      estimatedDuration: totalDuration,
      generatedAt: now,
    );
  }

  SequencedShow _generateNightShow() {
    final segments = <ShowSegment>[];
    var totalDuration = Duration.zero;

    for (final config in _nightSegments) {
      final segment = _buildSegment(config);
      if (segment != null) {
        segments.add(segment);
        totalDuration += segment.duration;
      }
    }

    return SequencedShow(
      id: '${_showId}_night_${_dateKey()}',
      title: 'Good Night India',
      subtitle: 'Sleep well',
      icon: '🌙',
      segments: segments,
      estimatedDuration: totalDuration,
      generatedAt: now,
    );
  }

  ShowSegment? _buildSegment(_SegmentConfig config) {
    var candidates = catalog.where((item) {
      // Match language
      if (item.language != language) return false;
      // Match interest
      if (item.primaryInterest != config.interest) return false;
      // For astrology, prefer user's sign
      if (config.interest == 'astrology' && userSign != null) {
        if (!item.title.toLowerCase().contains(userSign!.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    // Fallback: if no exact match, relax sign constraint
    if (candidates.isEmpty && config.interest == 'astrology') {
      candidates = catalog.where((item) {
        return item.language == language &&
            item.primaryInterest == config.interest;
      }).toList();
    }

    if (candidates.isEmpty) return null;

    // Prefer today's content for news/astrology
    final today = DateTime(now.year, now.month, now.day);
    final todayItems = candidates.where((item) {
      final published = item.publishedDate;
      if (published == null) return false;
      return published.year == today.year &&
          published.month == today.month &&
          published.day == today.day;
    }).toList();

    if (todayItems.isNotEmpty) {
      candidates = todayItems;
    }

    // Shuffle and take required count
    candidates.shuffle();
    final selected = candidates.take(config.itemCount).toList();

    if (selected.isEmpty) return null;

    final segmentDuration = selected.fold<Duration>(
      Duration.zero,
      (sum, item) => sum + Duration(seconds: item.durationSec),
    );

    return ShowSegment(
      id: config.id,
      title: config.title,
      interest: config.interest,
      items: selected,
      duration: segmentDuration,
    );
  }

  String _dateKey() => '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

  String _getGreeting() {
    final hour = now.hour;
    if (hour < 12) return 'Start your day with peace';
    if (hour < 17) return 'A midday moment of calm';
    if (hour < 21) return 'Relax and unwind';
    return 'Peaceful dreams await';
  }
}

class _SegmentConfig {
  final String id;
  final String title;
  final String interest;
  final int itemCount;
  final Duration maxDuration;

  const _SegmentConfig({
    required this.id,
    required this.title,
    required this.interest,
    required this.itemCount,
    required this.maxDuration,
  });
}
