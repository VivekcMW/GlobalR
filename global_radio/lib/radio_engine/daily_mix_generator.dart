import 'dart:math';

import '../data/models/catalog_item.dart';
import '../data/models/item_signals.dart';
import '../data/models/user_profile.dart';

/// A personalized "Daily Mix" playlist with a name and reason.
class DailyMix {
  final String name;
  final String reason;
  final List<CatalogItem> items;
  final DateTime generatedAt;

  const DailyMix({
    required this.name,
    required this.reason,
    required this.items,
    required this.generatedAt,
  });

  bool get isEmpty => items.isEmpty;
  int get length => items.length;
}

/// Time-of-day context for mix generation.
enum TimeOfDay {
  morning, // 5am - 11am
  afternoon, // 11am - 5pm
  evening, // 5pm - 9pm
  night, // 9pm - 5am
}

/// Generates personalized daily mixes based on user profile, time, and history.
class DailyMixGenerator {
  final Random _random = Random();

  /// Generate a personalized daily mix for the user.
  DailyMix generate({
    required UserProfile profile,
    required Catalog catalog,
    required Map<String, ItemSignals> signals,
    required DateTime now,
    int maxItems = 10,
  }) {
    final timeOfDay = _getTimeOfDay(now);
    final pool = _filterPool(catalog.items, profile, signals);
    
    if (pool.isEmpty) {
      return DailyMix(
        name: 'Your Mix',
        reason: 'No content available for your preferences',
        items: const [],
        generatedAt: now,
      );
    }

    // Build mix based on time of day
    final (name, reason, interests) = _getMixStrategy(timeOfDay, profile);
    
    // Score and rank items
    final ranked = _rankItems(pool, profile, signals, interests, now);
    
    // Select diverse items
    final selected = _selectDiverse(ranked, maxItems, profile.interests);

    return DailyMix(
      name: name,
      reason: reason,
      items: selected,
      generatedAt: now,
    );
  }

  /// Generate a quick mix for a specific interest.
  DailyMix generateForInterest({
    required String interest,
    required UserProfile profile,
    required Catalog catalog,
    required Map<String, ItemSignals> signals,
    required DateTime now,
    int maxItems = 10,
  }) {
    final pool = catalog.items
        .where((it) =>
            profile.languages.contains(it.language) &&
            it.interests.contains(interest) &&
            it.reachable)
        .toList();

    final ranked = _rankItems(pool, profile, signals, [interest], now);
    final selected = ranked.take(maxItems).toList();

    final interestLabel = _interestLabels[interest] ?? interest;
    
    return DailyMix(
      name: '$interestLabel Mix',
      reason: 'Your favorite $interestLabel content',
      items: selected,
      generatedAt: now,
    );
  }

  /// Generate a "favorites" mix from favorited items.
  DailyMix generateFavorites({
    required UserProfile profile,
    required Catalog catalog,
    required Map<String, ItemSignals> signals,
    required DateTime now,
    int maxItems = 15,
  }) {
    final favorited = signals.entries
        .where((e) => e.value.favorited)
        .map((e) => e.key)
        .toSet();

    final items = catalog.items
        .where((it) =>
            favorited.contains(it.id) &&
            profile.languages.contains(it.language))
        .toList();

    // Shuffle favorites for variety
    items.shuffle(_random);

    return DailyMix(
      name: 'Your Favorites',
      reason: '${items.length} items you love',
      items: items.take(maxItems).toList(),
      generatedAt: now,
    );
  }

  TimeOfDay _getTimeOfDay(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 11) return TimeOfDay.morning;
    if (hour >= 11 && hour < 17) return TimeOfDay.afternoon;
    if (hour >= 17 && hour < 21) return TimeOfDay.evening;
    return TimeOfDay.night;
  }

  (String name, String reason, List<String> interests) _getMixStrategy(
    TimeOfDay timeOfDay,
    UserProfile profile,
  ) {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        // Morning: devotion + astrology focus
        if (profile.interests.contains('devotion') ||
            profile.interests.contains('astrology')) {
          return (
            'Morning Inspiration',
            'Start your day with positivity',
            ['devotion', 'astrology'],
          );
        }
        return (
          'Good Morning',
          'Fresh content to start your day',
          profile.interests,
        );

      case TimeOfDay.afternoon:
        // Afternoon: balanced mix
        return (
          'Afternoon Mix',
          'Perfect for your afternoon',
          profile.interests,
        );

      case TimeOfDay.evening:
        // Evening: stories + moral focus
        if (profile.interests.contains('kids') ||
            profile.interests.contains('moral')) {
          return (
            'Evening Stories',
            'Wind down with great stories',
            ['kids', 'moral'],
          );
        }
        return (
          'Evening Relaxation',
          'Unwind with your favorites',
          profile.interests,
        );

      case TimeOfDay.night:
        // Night: calm content for bedtime
        return (
          'Bedtime Stories',
          'Peaceful content for sleep',
          ['devotion', 'moral', 'kids'],
        );
    }
  }

  List<CatalogItem> _filterPool(
    List<CatalogItem> catalog,
    UserProfile profile,
    Map<String, ItemSignals> signals,
  ) {
    final langs = profile.languages.toSet();
    final interests = profile.interests.toSet();

    return catalog
        .where((it) =>
            langs.contains(it.language) &&
            it.interests.any(interests.contains) &&
            it.reachable)
        .toList();
  }

  List<CatalogItem> _rankItems(
    List<CatalogItem> pool,
    UserProfile profile,
    Map<String, ItemSignals> signals,
    List<String> priorityInterests,
    DateTime now,
  ) {
    final prioritySet = priorityInterests.toSet();

    // Score each item
    final scored = pool.map((item) {
      double score = 0;

      // Priority interest boost
      if (item.interests.any(prioritySet.contains)) {
        score += 0.3;
      }

      // Freshness (today's daily content gets big boost)
      if (item.isDaily && item.date != null && _isSameDay(item.date!, now)) {
        score += 0.4;
      }

      // Popularity
      score += (item.popularity / 100.0) * 0.2;

      // Favorites boost
      final s = signals[item.id];
      if (s?.favorited == true) {
        score += 0.15;
      }

      // Recency penalty (avoid recently played)
      if (s?.lastPlayedAt != null) {
        final hoursSince = now.difference(s!.lastPlayedAt!).inHours;
        if (hoursSince < 24) {
          score -= 0.3 * (1 - hoursSince / 24);
        }
      }

      // Small random factor for variety
      score += _random.nextDouble() * 0.1;

      return (item, score);
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.$2.compareTo(a.$2));

    return scored.map((e) => e.$1).toList();
  }

  /// Select diverse items ensuring coverage of different interests.
  List<CatalogItem> _selectDiverse(
    List<CatalogItem> ranked,
    int maxItems,
    List<String> userInterests,
  ) {
    final selected = <CatalogItem>[];
    final interestCounts = <String, int>{};

    // Initialize counts
    for (final interest in userInterests) {
      interestCounts[interest] = 0;
    }

    for (final item in ranked) {
      if (selected.length >= maxItems) break;

      // Check if we should include this item for diversity
      final itemInterest = item.primaryInterest;
      final currentCount = interestCounts[itemInterest] ?? 0;
      final maxPerInterest = (maxItems / userInterests.length).ceil() + 1;

      if (currentCount < maxPerInterest) {
        selected.add(item);
        interestCounts[itemInterest] = currentCount + 1;
      }
    }

    // If we didn't fill the quota, add remaining top items
    if (selected.length < maxItems) {
      for (final item in ranked) {
        if (selected.length >= maxItems) break;
        if (!selected.contains(item)) {
          selected.add(item);
        }
      }
    }

    return selected;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static const _interestLabels = {
    'kids': 'Kids',
    'moral': 'Moral Stories',
    'devotion': 'Devotion',
    'astrology': 'Astrology',
  };
}
