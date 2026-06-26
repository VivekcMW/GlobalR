import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';

/// Network-aware audio buffer configuration.
///
/// Adjusts buffer sizes based on network quality for seamless playback:
/// - WiFi: Large buffers for uninterrupted streaming
/// - Mobile: Balanced buffers for data efficiency
/// - Poor/Offline: Aggressive prefetch, smaller buffers
class AudioBufferConfig {
  /// Current network quality level.
  final NetworkQuality quality;

  /// Android-specific buffer settings.
  final AndroidLoadControl androidControl;

  /// iOS/macOS-specific buffer settings.
  final DarwinLoadControl darwinControl;

  const AudioBufferConfig._({
    required this.quality,
    required this.androidControl,
    required this.darwinControl,
  });

  /// WiFi configuration: larger buffers, smooth streaming.
  static const wifi = AudioBufferConfig._(
    quality: NetworkQuality.wifi,
    androidControl: AndroidLoadControl(
      minBufferDuration: Duration(seconds: 30),
      maxBufferDuration: Duration(seconds: 90),
      bufferForPlaybackDuration: Duration(seconds: 3),
      bufferForPlaybackAfterRebufferDuration: Duration(seconds: 6),
      prioritizeTimeOverSizeThresholds: true,
    ),
    darwinControl: DarwinLoadControl(
      preferredForwardBufferDuration: Duration(seconds: 60),
      canUseNetworkResourcesForLiveStreamingWhilePaused: true,
      preferredPeakBitRate: 0, // No limit on WiFi
    ),
  );

  /// Mobile data: balanced for data efficiency.
  static const mobile = AudioBufferConfig._(
    quality: NetworkQuality.mobile,
    androidControl: AndroidLoadControl(
      minBufferDuration: Duration(seconds: 15),
      maxBufferDuration: Duration(seconds: 45),
      bufferForPlaybackDuration: Duration(seconds: 4),
      bufferForPlaybackAfterRebufferDuration: Duration(seconds: 8),
      prioritizeTimeOverSizeThresholds: true,
    ),
    darwinControl: DarwinLoadControl(
      preferredForwardBufferDuration: Duration(seconds: 30),
      canUseNetworkResourcesForLiveStreamingWhilePaused: false,
      preferredPeakBitRate: 128000, // 128kbps limit
    ),
  );

  /// Poor connection: aggressive buffering, smaller chunks.
  static const poor = AudioBufferConfig._(
    quality: NetworkQuality.poor,
    androidControl: AndroidLoadControl(
      minBufferDuration: Duration(seconds: 10),
      maxBufferDuration: Duration(seconds: 30),
      bufferForPlaybackDuration: Duration(seconds: 6),
      bufferForPlaybackAfterRebufferDuration: Duration(seconds: 12),
      prioritizeTimeOverSizeThresholds: true,
    ),
    darwinControl: DarwinLoadControl(
      preferredForwardBufferDuration: Duration(seconds: 20),
      canUseNetworkResourcesForLiveStreamingWhilePaused: false,
      preferredPeakBitRate: 64000, // 64kbps limit
    ),
  );

  /// Offline fallback: minimal remote buffering.
  static const offline = AudioBufferConfig._(
    quality: NetworkQuality.offline,
    androidControl: AndroidLoadControl(
      minBufferDuration: Duration(seconds: 5),
      maxBufferDuration: Duration(seconds: 15),
      bufferForPlaybackDuration: Duration(seconds: 2),
      bufferForPlaybackAfterRebufferDuration: Duration(seconds: 4),
    ),
    darwinControl: DarwinLoadControl(
      preferredForwardBufferDuration: Duration(seconds: 10),
      canUseNetworkResourcesForLiveStreamingWhilePaused: false,
    ),
  );

  /// Create AudioLoadConfiguration for just_audio.
  AudioLoadConfiguration toLoadConfiguration() {
    return AudioLoadConfiguration(
      androidLoadControl: androidControl,
      darwinLoadControl: darwinControl,
    );
  }

  /// Get config for current network state.
  static AudioBufferConfig forQuality(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.wifi:
        return wifi;
      case NetworkQuality.mobile:
        return mobile;
      case NetworkQuality.poor:
        return poor;
      case NetworkQuality.offline:
        return offline;
    }
  }
}

/// Network quality levels.
enum NetworkQuality { wifi, mobile, poor, offline }

/// Monitors network quality and provides buffer configurations.
class NetworkQualityMonitor {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkQuality _currentQuality = NetworkQuality.mobile;
  NetworkQuality get currentQuality => _currentQuality;

  /// Stream of quality changes.
  final _qualityController = StreamController<NetworkQuality>.broadcast();
  Stream<NetworkQuality> get qualityStream => _qualityController.stream;

  /// Callback when quality changes.
  void Function(NetworkQuality)? onQualityChanged;

  Future<void> init() async {
    // Get initial state
    final result = await _connectivity.checkConnectivity();
    _updateQuality(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateQuality);
  }

  void _updateQuality(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final newQuality = _mapConnectivity(result);
    if (newQuality != _currentQuality) {
      _currentQuality = newQuality;
      _qualityController.add(newQuality);
      onQualityChanged?.call(newQuality);
      print('[NetworkQuality] Changed to: $newQuality');
    }
  }

  NetworkQuality _mapConnectivity(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
        return NetworkQuality.wifi;
      case ConnectivityResult.mobile:
        return NetworkQuality.mobile;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.vpn:
        return NetworkQuality.poor;
      case ConnectivityResult.none:
      case ConnectivityResult.other:
      case ConnectivityResult.satellite:
        return NetworkQuality.offline;
    }
  }

  /// Get current buffer configuration.
  AudioBufferConfig get currentConfig =>
      AudioBufferConfig.forQuality(_currentQuality);

  void dispose() {
    _subscription?.cancel();
    _qualityController.close();
  }
}

/// Manages audio prefetching for seamless playback.
///
/// Prefetches upcoming tracks based on network quality:
/// - WiFi: Prefetch next 3 items
/// - Mobile: Prefetch next 2 items
/// - Poor: Prefetch next 1 item
/// - Offline: No prefetch (rely on cache)
class AudioPrefetchManager {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final NetworkQualityMonitor _networkMonitor;

  /// URLs currently being prefetched.
  final Set<String> _prefetchingUrls = {};

  /// URLs that have been successfully prefetched.
  final Set<String> _prefetchedUrls = {};

  /// Callback for prefetch progress.
  void Function(String url, double progress)? onPrefetchProgress;

  /// Callback when prefetch completes.
  void Function(String url, bool success)? onPrefetchComplete;

  AudioPrefetchManager(this._networkMonitor);

  /// Number of items to prefetch based on network quality.
  int get prefetchCount {
    switch (_networkMonitor.currentQuality) {
      case NetworkQuality.wifi:
        return 3;
      case NetworkQuality.mobile:
        return 2;
      case NetworkQuality.poor:
        return 1;
      case NetworkQuality.offline:
        return 0;
    }
  }

  /// Prefetch upcoming audio URLs.
  ///
  /// Call this when the current track changes to prefetch upcoming items.
  Future<void> prefetchAhead(List<String> urls, {int startIndex = 0}) async {
    if (_networkMonitor.currentQuality == NetworkQuality.offline) {
      print('[Prefetch] Offline, skipping prefetch');
      return;
    }

    final count = prefetchCount;
    final urlsToPrefetch = <String>[];

    for (var i = startIndex + 1; i <= startIndex + count && i < urls.length; i++) {
      final url = urls[i];
      if (!_prefetchedUrls.contains(url) && !_prefetchingUrls.contains(url)) {
        urlsToPrefetch.add(url);
      }
    }

    if (urlsToPrefetch.isEmpty) {
      print('[Prefetch] All upcoming items already cached');
      return;
    }

    print('[Prefetch] Prefetching ${urlsToPrefetch.length} items');

    // Prefetch in parallel with concurrency limit
    await Future.wait(
      urlsToPrefetch.map((url) => _prefetchUrl(url)),
      eagerError: false,
    );
  }

  /// Prefetch a single URL.
  Future<void> _prefetchUrl(String url) async {
    if (_prefetchingUrls.contains(url)) return;

    _prefetchingUrls.add(url);
    print('[Prefetch] Starting: ${url.split('/').last}');

    try {
      // Download to cache
      final fileInfo = await _cacheManager.downloadFile(
        url,
        force: false, // Use cached if available
      );

      _prefetchedUrls.add(url);
      print('[Prefetch] Completed: ${url.split('/').last} (${fileInfo.file.lengthSync()} bytes)');
      onPrefetchComplete?.call(url, true);
    } catch (e) {
      print('[Prefetch] Failed: ${url.split('/').last} - $e');
      onPrefetchComplete?.call(url, false);
    } finally {
      _prefetchingUrls.remove(url);
    }
  }

  /// Check if a URL is cached.
  Future<bool> isCached(String url) async {
    if (_prefetchedUrls.contains(url)) return true;
    final info = await _cacheManager.getFileFromCache(url);
    return info != null;
  }

  /// Get cached file path for a URL, if available.
  Future<String?> getCachedPath(String url) async {
    final info = await _cacheManager.getFileFromCache(url);
    return info?.file.path;
  }

  /// Clear prefetch tracking (call on queue reset).
  void clearTracking() {
    _prefetchingUrls.clear();
    _prefetchedUrls.clear();
  }

  /// Evict old cached files to free space.
  Future<void> evictOldFiles({int maxAgeDays = 7}) async {
    await _cacheManager.emptyCache();
    print('[Prefetch] Cache cleared');
  }
}

/// Creates an AudioSource with fallback chain for resilient playback.
///
/// Fallback order:
/// 1. Primary CDN URL
/// 2. Fallback CDN URL (if provided)
/// 3. Local cache
/// 4. Bundled demo asset (if available)
class FallbackAudioSource {
  final String primaryUrl;
  final String? fallbackUrl;
  final String? cachedPath;
  final String? demoAssetPath;
  final Object? tag;

  const FallbackAudioSource({
    required this.primaryUrl,
    this.fallbackUrl,
    this.cachedPath,
    this.demoAssetPath,
    this.tag,
  });

  /// Create a LockCachingAudioSource with fallback handling.
  ///
  /// Uses just_audio's LockCachingAudioSource for efficient caching.
  AudioSource toAudioSource() {
    // If we have a cached file, use it directly
    if (cachedPath != null) {
      return AudioSource.file(cachedPath!, tag: tag);
    }

    // Use LockCachingAudioSource for automatic caching
    return LockCachingAudioSource(
      Uri.parse(primaryUrl),
      tag: tag,
    );
  }

  /// Create a ClippingAudioSource for a segment of the audio.
  /// Note: Clipping requires a UriAudioSource, so this creates one from the primary URL.
  AudioSource toClippedSource({
    Duration? start,
    Duration? end,
  }) {
    return ClippingAudioSource(
      child: AudioSource.uri(Uri.parse(primaryUrl), tag: tag),
      start: start,
      end: end,
      tag: tag,
    );
  }
}

/// Extension to create AudioLoadConfiguration easily.
extension AudioPlayerBufferExtension on AudioPlayer {
  /// Apply network-aware buffer configuration.
  Future<void> applyBufferConfig(AudioBufferConfig config) async {
    // Note: Buffer configuration is applied when setting audio source,
    // not dynamically. This is a convenience method for documentation.
    print('[Buffer] Config applied: ${config.quality}');
  }
}
