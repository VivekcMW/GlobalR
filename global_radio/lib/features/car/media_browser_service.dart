import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/offline_content_service.dart';
import '../../data/local/local_store.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../shared/providers/providers.dart';

/// Media browser structure for Android Auto / Apple CarPlay.
/// Defines the hierarchy of browsable content.

/// Media browser root IDs.
class MediaBrowserIds {
  static const String root = 'ROOT';
  static const String recentlyPlayed = 'RECENTLY_PLAYED';
  static const String categories = 'CATEGORIES';
  static const String languages = 'LANGUAGES';
  static const String morningShow = 'MORNING_SHOW';
  static const String favorites = 'FAVORITES';
  static const String downloads = 'DOWNLOADS';

  // Category prefixes
  static const String categoryPrefix = 'CAT_';
  static const String languagePrefix = 'LANG_';
  static const String itemPrefix = 'ITEM_';
}

/// A browsable media item for car interfaces.
class BrowsableItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final bool playable;
  final String? parentId;

  const BrowsableItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.artworkUrl,
    this.playable = false,
    this.parentId,
  });

  /// Convert to MediaItem for audio_service.
  MediaItem toMediaItem() {
    return MediaItem(
      id: id,
      title: title,
      artist: subtitle,
      artUri: artworkUrl != null ? Uri.parse(artworkUrl!) : null,
      playable: playable,
      displayTitle: title,
      displaySubtitle: subtitle,
    );
  }
}

/// Service for providing media browser content to Android Auto / CarPlay.
class MediaBrowserService {
  final LocalStore _localStore;
  final CatalogRepository _catalogRepository;
  final OfflineContentService _offlineContentService;

  MediaBrowserService({
    required LocalStore localStore,
    required CatalogRepository catalogRepository,
    required OfflineContentService offlineContentService,
  })  : _localStore = localStore,
        _catalogRepository = catalogRepository,
        _offlineContentService = offlineContentService;
  /// Get root items for the media browser.
  List<BrowsableItem> getRootItems() {
    return [
      const BrowsableItem(
        id: MediaBrowserIds.morningShow,
        title: 'Good Morning India',
        subtitle: 'Your personalized daily mix',
        playable: true,
      ),
      const BrowsableItem(
        id: MediaBrowserIds.recentlyPlayed,
        title: 'Recently Played',
        subtitle: 'Continue where you left off',
      ),
      const BrowsableItem(
        id: MediaBrowserIds.categories,
        title: 'Categories',
        subtitle: 'Browse by type',
      ),
      const BrowsableItem(
        id: MediaBrowserIds.languages,
        title: 'Languages',
        subtitle: 'Browse by language',
      ),
      const BrowsableItem(
        id: MediaBrowserIds.favorites,
        title: 'Favorites',
        subtitle: 'Your liked content',
      ),
      const BrowsableItem(
        id: MediaBrowserIds.downloads,
        title: 'Downloads',
        subtitle: 'Available offline',
      ),
    ];
  }

  /// Get category items.
  List<BrowsableItem> getCategoryItems() {
    final categories = [
      ('devotional', 'Devotional', '🙏'),
      ('kids_stories', 'Kids Stories', '📚'),
      ('news', 'News', '📰'),
      ('podcast', 'Podcasts', '🎙️'),
      ('music', 'Music', '🎵'),
      ('comedy', 'Comedy', '😂'),
      ('stories', 'Stories', '📖'),
      ('astrology', 'Astrology', '⭐'),
      ('motivational', 'Motivational', '💪'),
    ];

    return categories.map((cat) {
      return BrowsableItem(
        id: '${MediaBrowserIds.categoryPrefix}${cat.$1}',
        title: cat.$2,
        subtitle: cat.$3,
        parentId: MediaBrowserIds.categories,
      );
    }).toList();
  }

  /// Get language items.
  List<BrowsableItem> getLanguageItems() {
    final languages = [
      ('hindi', 'Hindi', 'हिंदी'),
      ('english', 'English', 'English'),
      ('tamil', 'Tamil', 'தமிழ்'),
      ('telugu', 'Telugu', 'తెలుగు'),
      ('kannada', 'Kannada', 'ಕನ್ನಡ'),
      ('malayalam', 'Malayalam', 'മലയാളം'),
      ('marathi', 'Marathi', 'मराठी'),
      ('gujarati', 'Gujarati', 'ગુજરાતી'),
      ('bengali', 'Bengali', 'বাংলা'),
      ('punjabi', 'Punjabi', 'ਪੰਜਾਬੀ'),
      ('urdu', 'Urdu', 'اردو'),
      ('odia', 'Odia', 'ଓଡ଼ିଆ'),
      ('assamese', 'Assamese', 'অসমীয়া'),
    ];

    return languages.map((lang) {
      return BrowsableItem(
        id: '${MediaBrowserIds.languagePrefix}${lang.$1}',
        title: lang.$2,
        subtitle: lang.$3,
        parentId: MediaBrowserIds.languages,
      );
    }).toList();
  }

  /// Get children for a parent ID.
  Future<List<BrowsableItem>> getChildren(String parentId) async {
    switch (parentId) {
      case MediaBrowserIds.root:
        return getRootItems();

      case MediaBrowserIds.categories:
        return getCategoryItems();

      case MediaBrowserIds.languages:
        return getLanguageItems();

      case MediaBrowserIds.recentlyPlayed:
        return _getRecentlyPlayedItems();

      case MediaBrowserIds.favorites:
        return _getFavoriteItems();

      case MediaBrowserIds.downloads:
        return _getDownloadedItems();

      default:
        // Check if it's a category or language
        if (parentId.startsWith(MediaBrowserIds.categoryPrefix)) {
          final category =
              parentId.substring(MediaBrowserIds.categoryPrefix.length);
          return _getItemsForCategory(category);
        }
        if (parentId.startsWith(MediaBrowserIds.languagePrefix)) {
          final language =
              parentId.substring(MediaBrowserIds.languagePrefix.length);
          return _getItemsForLanguage(language);
        }
        return [];
    }
  }

  /// Get recently played items.
  Future<List<BrowsableItem>> _getRecentlyPlayedItems() async {
    final catalog = await _catalogRepository.loadInitial();
    final items = _localStore.recentlyPlayed();

    return items.map((signal) {
      final matches = catalog.items.where((e) => e.id == signal.itemId);
      final catalogItem = matches.isNotEmpty ? matches.first : null;

      return BrowsableItem(
        id: '${MediaBrowserIds.itemPrefix}${signal.itemId}',
        title: catalogItem?.title ?? 'Unknown Item',
        subtitle: catalogItem != null
            ? '${catalogItem.primaryInterest} · ${catalogItem.language}'
            : 'Unknown',
        playable: true,
        parentId: MediaBrowserIds.recentlyPlayed,
      );
    }).toList();
  }

  /// Get favorite items.
  Future<List<BrowsableItem>> _getFavoriteItems() async {
    final catalog = await _catalogRepository.loadInitial();
    final items = _localStore.favorites();

    return items.map((signal) {
      final matches = catalog.items.where((e) => e.id == signal.itemId);
      final catalogItem = matches.isNotEmpty ? matches.first : null;

      return BrowsableItem(
        id: '${MediaBrowserIds.itemPrefix}${signal.itemId}',
        title: catalogItem?.title ?? 'Unknown Item',
        subtitle: catalogItem != null
            ? '${catalogItem.primaryInterest} · ${catalogItem.language}'
            : 'Unknown',
        playable: true,
        parentId: MediaBrowserIds.favorites,
      );
    }).toList();
  }

  /// Get downloaded items.
  Future<List<BrowsableItem>> _getDownloadedItems() async {
    final items = _offlineContentService.downloadedContent;

    return items.map((item) {
      return BrowsableItem(
        id: '${MediaBrowserIds.itemPrefix}${item.id}',
        title: item.title,
        subtitle: '${item.interest} · Downloaded',
        playable: true,
        parentId: MediaBrowserIds.downloads,
      );
    }).toList();
  }

  /// Get items for a specific category.
  Future<List<BrowsableItem>> _getItemsForCategory(String category) async {
    final catalog = await _catalogRepository.loadInitial();
    final items = catalog.items.where((e) => e.interests.contains(category)).toList();

    return items.map((item) {
      return BrowsableItem(
        id: '${MediaBrowserIds.itemPrefix}${item.id}',
        title: item.title,
        subtitle: item.language,
        playable: true,
        parentId: '${MediaBrowserIds.categoryPrefix}$category',
      );
    }).toList();
  }

  /// Get items for a specific language.
  Future<List<BrowsableItem>> _getItemsForLanguage(String language) async {
    final catalog = await _catalogRepository.loadInitial();
    final items = catalog.items.where((e) => e.language == language).toList();

    return items.map((item) {
      return BrowsableItem(
        id: '${MediaBrowserIds.itemPrefix}${item.id}',
        title: item.title,
        subtitle: item.primaryInterest,
        playable: true,
        parentId: '${MediaBrowserIds.languagePrefix}$language',
      );
    }).toList();
  }
}

/// Provider for media browser service.
final mediaBrowserServiceProvider = Provider<MediaBrowserService>((ref) {
  return MediaBrowserService(
    localStore: ref.read(localStoreProvider),
    catalogRepository: ref.read(catalogRepositoryProvider),
    offlineContentService: ref.read(offlineContentServiceProvider),
  );
});

/// Extension to add media browser support to the audio handler.
mixin MediaBrowserMixin {
  MediaBrowserService get mediaBrowserService;

  /// Get browsable children for Android Auto / CarPlay.
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    final items = await mediaBrowserService.getChildren(parentMediaId);
    return items.map((item) => item.toMediaItem()).toList();
  }

  /// Handle item selection from car interface.
  Future<void> onMediaItemSelected(String mediaId) async {
    // Handle playback based on the selected item ID
    if (mediaId == MediaBrowserIds.morningShow) {
      // Start morning show playback
    } else if (mediaId.startsWith(MediaBrowserIds.itemPrefix)) {
      // Play specific item
    }
  }
}
