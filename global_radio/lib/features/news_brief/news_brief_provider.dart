import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/catalog_item.dart';
import '../../shared/providers/providers.dart';

/// Configuration for regional news briefs.
class NewsBriefConfig {
  /// Maximum duration for a news brief in seconds.
  static const maxDurationSeconds = 120; // 2 minutes

  /// How often to insert news briefs (in minutes from last news).
  static const insertionIntervalMinutes = 60; // Top of each hour

  /// Languages with available news sources.
  static const supportedLanguages = [
    'hindi',
    'english',
    'tamil',
    'telugu',
    'kannada',
    'malayalam',
    'marathi',
    'gujarati',
    'bengali',
    'urdu',
    'punjabi',
    'odia',
    'assamese',
  ];
}

/// Service for managing regional news briefs.
class NewsBriefService {
  final List<CatalogItem> catalog;
  final String language;

  NewsBriefService({
    required this.catalog,
    required this.language,
  });

  /// Get the latest news brief for the user's language.
  CatalogItem? getLatestNewsBrief() {
    final newsItems = catalog.where((item) {
      return item.primaryInterest == 'news' &&
          item.language == language &&
          item.durationSec <= NewsBriefConfig.maxDurationSeconds;
    }).toList();

    if (newsItems.isEmpty) return null;

    // Sort by published date, newest first
    newsItems.sort((a, b) {
      final aDate = a.publishedDate ?? DateTime(2000);
      final bDate = b.publishedDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return newsItems.first;
  }

  /// Get today's news briefs.
  List<CatalogItem> getTodaysNewsBriefs() {
    final today = DateTime.now();
    
    return catalog.where((item) {
      if (item.primaryInterest != 'news') return false;
      if (item.language != language) return false;
      
      final published = item.publishedDate;
      if (published == null) return false;
      
      return published.year == today.year &&
          published.month == today.month &&
          published.day == today.day;
    }).toList();
  }

  /// Check if we should insert a news brief based on last news time.
  bool shouldInsertNews(DateTime? lastNewsPlayedAt) {
    if (lastNewsPlayedAt == null) return true;

    final minutesSinceLastNews =
        DateTime.now().difference(lastNewsPlayedAt).inMinutes;

    return minutesSinceLastNews >= NewsBriefConfig.insertionIntervalMinutes;
  }

  /// Check if it's a "top of the hour" moment (good time for news).
  bool isTopOfHour() {
    final now = DateTime.now();
    return now.minute < 5; // Within first 5 minutes of hour
  }
}

/// Provider for news brief service.
final newsBriefServiceProvider = Provider<NewsBriefService?>((ref) {
  final catalogAsync = ref.watch(catalogProvider);
  final profile = ref.watch(profileProvider);
  
  final catalog = catalogAsync.valueOrNull;
  if (catalog == null) return null;
  
  return NewsBriefService(
    catalog: catalog.items,
    language: profile.languages.isNotEmpty ? profile.languages.first : 'english',
  );
});

/// Provider for the latest news brief.
final latestNewsBriefProvider = Provider<CatalogItem?>((ref) {
  final service = ref.watch(newsBriefServiceProvider);
  return service?.getLatestNewsBrief();
});

/// Provider for today's news briefs.
final todaysNewsBriefsProvider = Provider<List<CatalogItem>>((ref) {
  final service = ref.watch(newsBriefServiceProvider);
  return service?.getTodaysNewsBriefs() ?? [];
});

/// State for tracking news playback.
class NewsPlaybackState {
  final DateTime? lastPlayedAt;
  final String? lastPlayedItemId;
  final int playCount;

  const NewsPlaybackState({
    this.lastPlayedAt,
    this.lastPlayedItemId,
    this.playCount = 0,
  });

  NewsPlaybackState copyWith({
    DateTime? lastPlayedAt,
    String? lastPlayedItemId,
    int? playCount,
  }) {
    return NewsPlaybackState(
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      lastPlayedItemId: lastPlayedItemId ?? this.lastPlayedItemId,
      playCount: playCount ?? this.playCount,
    );
  }
}

/// Notifier for news playback state.
class NewsPlaybackNotifier extends StateNotifier<NewsPlaybackState> {
  NewsPlaybackNotifier() : super(const NewsPlaybackState());

  void markNewsPlayed(String itemId) {
    state = state.copyWith(
      lastPlayedAt: DateTime.now(),
      lastPlayedItemId: itemId,
      playCount: state.playCount + 1,
    );
  }

  bool shouldInsertNews() {
    if (state.lastPlayedAt == null) return true;
    
    final minutesSince = DateTime.now().difference(state.lastPlayedAt!).inMinutes;
    return minutesSince >= NewsBriefConfig.insertionIntervalMinutes;
  }
}

final newsPlaybackProvider =
    StateNotifierProvider<NewsPlaybackNotifier, NewsPlaybackState>((ref) {
  return NewsPlaybackNotifier();
});

/// Provider to check if news should be inserted now.
final shouldInsertNewsProvider = Provider<bool>((ref) {
  final newsState = ref.watch(newsPlaybackProvider);
  final service = ref.read(newsBriefServiceProvider);
  
  return service?.shouldInsertNews(newsState.lastPlayedAt) ?? false;
});
