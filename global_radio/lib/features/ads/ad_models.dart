/// Ad system models for audio advertising.
/// Supports VAST-based ads with pre-roll and mid-roll slots.

/// Position where an ad can be inserted.
enum AdSlotType {
  preRoll,  // Before first content item
  midRoll,  // Between content items
}

/// Skip behavior for an ad.
enum AdSkipPolicy {
  nonSkippable,       // Must watch entire ad
  skippableAfter5s,   // Can skip after 5 seconds
  alwaysSkippable,    // Can skip immediately (rare)
}

/// Parsed ad creative from VAST response.
class AdCreative {
  final String id;
  final String title;
  final String mediaUrl;
  final Duration duration;
  final AdSkipPolicy skipPolicy;
  final Duration? skipOffset; // When skip becomes available
  final String? impressionUrl; // Fire on ad start
  final String? completeUrl;   // Fire on 100% completion
  final String? clickThroughUrl; // Landing page
  final String? clickTrackingUrl; // Fire on click
  final String? skipTrackingUrl; // Fire on skip
  final String? errorUrl; // Fire on error
  final bool isOfflineAd; // Bundled for offline packs

  const AdCreative({
    required this.id,
    required this.title,
    required this.mediaUrl,
    required this.duration,
    this.skipPolicy = AdSkipPolicy.skippableAfter5s,
    this.skipOffset = const Duration(seconds: 5),
    this.impressionUrl,
    this.completeUrl,
    this.clickThroughUrl,
    this.clickTrackingUrl,
    this.skipTrackingUrl,
    this.errorUrl,
    this.isOfflineAd = false,
  });

  /// Creates a test/fallback ad for development or offline use.
  factory AdCreative.fallback({bool isOffline = false}) => AdCreative(
        id: 'fallback_ad_001',
        title: 'Global Radio Premium',
        mediaUrl: isOffline
            ? 'assets/audio/ads/offline_promo.mp3'
            : 'https://storage.googleapis.com/gvabox/media/samples/audio_ad_sample.mp3',
        duration: const Duration(seconds: 15),
        skipPolicy: AdSkipPolicy.skippableAfter5s,
        skipOffset: const Duration(seconds: 5),
        isOfflineAd: isOffline,
      );

  /// Creates from VAST parsed data.
  factory AdCreative.fromVast({
    required String id,
    required String mediaUrl,
    required Duration duration,
    String? title,
    String? impressionUrl,
    String? completeUrl,
    String? clickThroughUrl,
    String? clickTrackingUrl,
    int skipOffsetSeconds = 5,
  }) =>
      AdCreative(
        id: id,
        title: title ?? 'Advertisement',
        mediaUrl: mediaUrl,
        duration: duration,
        skipPolicy: skipOffsetSeconds > 0
            ? AdSkipPolicy.skippableAfter5s
            : AdSkipPolicy.nonSkippable,
        skipOffset: Duration(seconds: skipOffsetSeconds),
        impressionUrl: impressionUrl,
        completeUrl: completeUrl,
        clickThroughUrl: clickThroughUrl,
        clickTrackingUrl: clickTrackingUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'mediaUrl': mediaUrl,
        'durationMs': duration.inMilliseconds,
        'skipPolicy': skipPolicy.name,
        'skipOffsetMs': skipOffset?.inMilliseconds,
        'impressionUrl': impressionUrl,
        'completeUrl': completeUrl,
        'clickThroughUrl': clickThroughUrl,
        'isOfflineAd': isOfflineAd,
      };

  factory AdCreative.fromJson(Map<String, dynamic> json) => AdCreative(
        id: json['id'] as String,
        title: json['title'] as String,
        mediaUrl: json['mediaUrl'] as String,
        duration: Duration(milliseconds: json['durationMs'] as int),
        skipPolicy: AdSkipPolicy.values.firstWhere(
          (e) => e.name == json['skipPolicy'],
          orElse: () => AdSkipPolicy.skippableAfter5s,
        ),
        skipOffset: json['skipOffsetMs'] != null
            ? Duration(milliseconds: json['skipOffsetMs'] as int)
            : null,
        impressionUrl: json['impressionUrl'] as String?,
        completeUrl: json['completeUrl'] as String?,
        clickThroughUrl: json['clickThroughUrl'] as String?,
        isOfflineAd: json['isOfflineAd'] as bool? ?? false,
      );
}

/// Represents a scheduled ad slot in the playback queue.
class AdSlot {
  final AdSlotType type;
  final int insertAfterIndex; // -1 for pre-roll, N for after item N
  final AdCreative? creative; // null until loaded

  const AdSlot({
    required this.type,
    required this.insertAfterIndex,
    this.creative,
  });

  AdSlot withCreative(AdCreative c) => AdSlot(
        type: type,
        insertAfterIndex: insertAfterIndex,
        creative: c,
      );

  bool get isPreRoll => type == AdSlotType.preRoll;
  bool get isMidRoll => type == AdSlotType.midRoll;
  bool get isLoaded => creative != null;
}

/// Ad playback state for UI.
class AdPlaybackState {
  final AdCreative? currentAd;
  final Duration position;
  final bool canSkip;
  final Duration? skipAvailableIn; // Time until skip enabled

  const AdPlaybackState({
    this.currentAd,
    this.position = Duration.zero,
    this.canSkip = false,
    this.skipAvailableIn,
  });

  AdPlaybackState copyWith({
    AdCreative? currentAd,
    Duration? position,
    bool? canSkip,
    Duration? skipAvailableIn,
    bool clearAd = false,
  }) =>
      AdPlaybackState(
        currentAd: clearAd ? null : (currentAd ?? this.currentAd),
        position: position ?? this.position,
        canSkip: canSkip ?? this.canSkip,
        skipAvailableIn: skipAvailableIn,
      );
}

/// VAST response wrapper for parsed ad data.
class VastResponse {
  final String adId;
  final String? adTitle;
  final List<String> mediaFiles; // Multiple bitrates/formats
  final Duration duration;
  final List<String> impressionUrls;
  final String? clickThrough;
  final Map<String, List<String>> trackingEvents; // event -> urls
  final int skipOffsetSeconds;
  final String? errorUrl;

  const VastResponse({
    required this.adId,
    this.adTitle,
    required this.mediaFiles,
    required this.duration,
    this.impressionUrls = const [],
    this.clickThrough,
    this.trackingEvents = const {},
    this.skipOffsetSeconds = 5,
    this.errorUrl,
  });

  /// Convert to AdCreative, selecting best media file.
  AdCreative toCreative() {
    // Prefer MP3, then any audio, then first available
    final audioUrl = mediaFiles.firstWhere(
      (url) => url.contains('.mp3'),
      orElse: () => mediaFiles.firstWhere(
        (url) => url.contains('audio'),
        orElse: () => mediaFiles.isNotEmpty ? mediaFiles.first : '',
      ),
    );

    return AdCreative(
      id: adId,
      title: adTitle ?? 'Advertisement',
      mediaUrl: audioUrl,
      duration: duration,
      skipPolicy: skipOffsetSeconds > 0
          ? AdSkipPolicy.skippableAfter5s
          : AdSkipPolicy.nonSkippable,
      skipOffset: Duration(seconds: skipOffsetSeconds),
      impressionUrl: impressionUrls.isNotEmpty ? impressionUrls.first : null,
      completeUrl: trackingEvents['complete']?.firstOrNull,
      clickThroughUrl: clickThrough,
      clickTrackingUrl: trackingEvents['click']?.firstOrNull,
      skipTrackingUrl: trackingEvents['skip']?.firstOrNull,
      errorUrl: errorUrl,
    );
  }
}

/// Configuration for ad behavior.
class AdConfig {
  /// Maximum ads per listening session.
  final int maxAdsPerSession;

  /// Minimum content items between mid-roll ads.
  final int minItemsBetweenAds;

  /// Enable pre-roll on first play of session.
  final bool enablePreRoll;

  /// Enable mid-roll ads between content.
  final bool enableMidRoll;

  /// Skip offset in seconds (0 = non-skippable).
  final int skipOffsetSeconds;

  /// Timeout for VAST fetch.
  final Duration vastTimeout;

  /// Fallback to bundled ad on network failure.
  final bool useFallbackOnError;

  const AdConfig({
    this.maxAdsPerSession = 3,
    this.minItemsBetweenAds = 4,
    this.enablePreRoll = true,
    this.enableMidRoll = true,
    this.skipOffsetSeconds = 5,
    this.vastTimeout = const Duration(seconds: 5),
    this.useFallbackOnError = true,
  });

  static const AdConfig defaults = AdConfig();
}
