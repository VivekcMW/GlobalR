import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import '../data/models/catalog_item.dart';
import '../features/ads/ad_models.dart';
import 'audio_buffer_config.dart';

/// Background audio handler: wraps just_audio behind audio_service so playback
/// continues in the background with lock-screen controls (docs tech-spec §1).
///
/// Builds a gapless queue and prefetches lazily. Voice resolution + URL
/// building happens before items reach here (via [CatalogItem.audioUrlFor]).
///
/// Supports ad insertion (pre-roll, mid-roll) with skip-after-5s behavior.
///
/// **Buffering improvements:**
/// - Network-aware buffer sizing (WiFi vs mobile vs poor)
/// - Automatic prefetch of next 2-3 items
/// - Graceful fallback chain: CDN → cache → demo asset
class GlobalRadioAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  late final AudioPlayer _player;

  /// Network quality monitor for adaptive buffering.
  final NetworkQualityMonitor _networkMonitor = NetworkQualityMonitor();

  /// Prefetch manager for seamless playback.
  late final AudioPrefetchManager _prefetchManager;

  /// Tracks which queue indices are ads (for UI and skip prevention).
  final Set<int> _adIndices = {};

  /// Callback when ad playback starts (for UI notification).
  void Function(AdCreative ad)? onAdStart;

  /// Callback when ad playback completes (for state update).
  void Function(String adId)? onAdComplete;

  /// Callback when ad is skipped.
  void Function(String adId, Duration position)? onAdSkip;

  /// Callback when an error occurs during playback.
  void Function(Object error)? onError;

  /// The concatenating source for dynamic ad insertion.
  ConcatenatingAudioSource? _concatenatingSource;

  /// Whether the audio source is ready to play.
  bool _isReady = false;
  
  /// Whether the audio session is configured.
  bool _sessionConfigured = false;

  /// Current queue URLs for prefetching.
  List<String> _queueUrls = [];

  GlobalRadioAudioHandler() {
    // Initialize player synchronously first
    _initPlayerSync();
    _prefetchManager = AudioPrefetchManager(_networkMonitor);
    
    // Initialize network monitoring
    _networkMonitor.init();
    _networkMonitor.onQualityChanged = _onNetworkQualityChanged;
    
    // Configure audio session asynchronously
    _configureAudioSession();
  }

  void _initPlayerSync() {
    // Create player with initial buffer config
    final config = _networkMonitor.currentConfig;
    _player = AudioPlayer(
      audioLoadConfiguration: config.toLoadConfiguration(),
    );
    
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.currentIndexStream.listen(_onIndexChanged);
    
    // Listen for player state changes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready && !_isReady) {
        _isReady = true;
        print('[AudioHandler] Audio source ready, starting playback');
      }
    });
    
    // Listen for playback completion to auto-advance
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        print('[AudioHandler] Playback completed');
      }
    });

    // Listen for buffering state changes
    _player.bufferedPositionStream.listen((buffered) {
      final duration = _player.duration;
      if (duration != null && duration.inSeconds > 0) {
        final bufferedPercent = (buffered.inSeconds / duration.inSeconds * 100).round();
        if (bufferedPercent % 25 == 0) {
          print('[AudioHandler] Buffered: $bufferedPercent%');
        }
      }
    });
  }

  Future<void> _configureAudioSession() async {
    // Configure audio session for iOS/Android
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    _sessionConfigured = true;
    print('[AudioHandler] Audio session configured');
  }
  
  /// Wait for audio session to be configured
  Future<void> _ensureSessionConfigured() async {
    // Wait up to 5 seconds for session to be configured
    for (var i = 0; i < 50 && !_sessionConfigured; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!_sessionConfigured) {
      print('[AudioHandler] Warning: Audio session not configured yet');
    }
  }

  /// Handle network quality changes.
  void _onNetworkQualityChanged(NetworkQuality quality) {
    print('[AudioHandler] Network quality changed: $quality');
    // Note: Buffer config changes require recreating the player,
    // which is disruptive. Instead, we adjust prefetch behavior.
    // Prefetch more aggressively on good connections.
    // Skip prefetch in demo mode since we use bundled assets
    if (!AppConfig.demoAudio) {
      _triggerPrefetch();
    }
  }

  /// Trigger prefetch of upcoming items.
  Future<void> _triggerPrefetch() async {
    // Don't prefetch in demo mode
    if (AppConfig.demoAudio) return;
    
    final currentIndex = _player.currentIndex ?? 0;
    if (_queueUrls.isNotEmpty) {
      await _prefetchManager.prefetchAhead(_queueUrls, startIndex: currentIndex);
    }
  }
  
  /// Copy asset to a temporary file for reliable playback on iOS.
  /// Returns the file path.
  Future<String> _copyAssetToTempFile(String assetPath) async {
    // Get temp directory
    final tempDir = await getTemporaryDirectory();
    
    // Create a unique filename based on the asset path
    final fileName = assetPath.replaceAll('/', '_').replaceAll(' ', '_');
    final tempFile = File('${tempDir.path}/demo_audio_$fileName');
    
    // Only copy if file doesn't exist
    if (!await tempFile.exists()) {
      print('[AudioHandler] Copying asset to temp: $assetPath -> ${tempFile.path}');
      final data = await rootBundle.load(assetPath);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      print('[AudioHandler] Asset copied successfully');
    } else {
      print('[AudioHandler] Using cached temp file: ${tempFile.path}');
    }
    
    return tempFile.path;
  }

  /// Whether the player is currently playing.
  bool get playing => _player.playing;

  /// Stream of playing state changes.
  Stream<bool> get playingStream => _player.playingStream;

  /// Stream of player state for UI reactivity.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream of processing state for loading indicators.
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;

  /// Whether the player is ready to play.
  bool get isReady => _isReady && _player.processingState == ProcessingState.ready;

  /// Whether the player is loading/buffering.
  bool get isLoading => _player.processingState == ProcessingState.loading || 
                        _player.processingState == ProcessingState.buffering;

  /// Handle track changes, including ad detection and prefetching.
  void _onIndexChanged(int? index) {
    final q = queue.value;
    if (index != null && index < q.length) {
      mediaItem.add(q[index]);

      // Check if this is an ad
      if (_adIndices.contains(index)) {
        final item = q[index];
        final adData = item.extras?['adData'] as Map<String, dynamic>?;
        if (adData != null && onAdStart != null) {
          onAdStart!(AdCreative.fromJson(adData));
        }
      }

      // Trigger prefetch for upcoming items (seamless playback)
      _triggerPrefetch();
    }
  }

  /// Convert engine output (CatalogItem queue) into a playable source.
  /// Returns true if the source was set successfully, false otherwise.
  ///
  /// **Seamless playback features:**
  /// - Gapless queue via ConcatenatingAudioSource
  /// - Network-aware buffering configuration
  /// - Automatic prefetch of next 2-3 items
  /// - Fallback chain: CDN → LockCaching → Demo asset
  Future<bool> setRadioQueue(
    List<CatalogItem> items, {
    required String preferredVoice,
    int initialIndex = 0,
    AdCreative? preRollAd,
  }) async {
    // Ensure audio session is configured before loading audio
    await _ensureSessionConfigured();
    
    // Activate audio session before loading
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      print('[AudioHandler] Audio session activated for loading');
    } catch (e) {
      print('[AudioHandler] Warning: Could not activate audio session: $e');
    }
    
    _adIndices.clear();
    _isReady = false;
    _queueUrls.clear();
    _prefetchManager.clearTracking();

    print('[AudioHandler] setRadioQueue called with ${items.length} items, preferredVoice: $preferredVoice');
    
    if (items.isEmpty) {
      print('[AudioHandler] ERROR: Empty queue provided');
      return false;
    }

    final mediaItems = <MediaItem>[];
    final sources = <AudioSource>[];
    var queueIndex = 0;

    // Insert pre-roll ad if provided
    if (preRollAd != null) {
      final adMediaItem = _createAdMediaItem(preRollAd);
      mediaItems.add(adMediaItem);
      sources.add(_createAdAudioSource(preRollAd, adMediaItem));
      _adIndices.add(queueIndex);
      _queueUrls.add(preRollAd.mediaUrl); // Track for prefetch
      queueIndex++;
    }

    // Add content items with fallback chain
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final audioUrl = it.audioUrlFor(preferredVoice);
      final m = MediaItem(
        id: audioUrl,
        title: it.title,
        album: it.interests.join(', '),
        duration: Duration(seconds: it.durationSec),
        artUri: null,
        extras: {'itemId': it.id, 'type': it.type, 'isAd': false},
      );
      mediaItems.add(m);
      _queueUrls.add(audioUrl);

      if (AppConfig.demoAudio) {
        // Demo mode: use bundled assets
        // Copy to temp file for more reliable playback on iOS
        final assetPath = it.demoAssetFor(preferredVoice);
        print('[AudioHandler] Loading demo asset: $assetPath for item: ${it.id}, language: ${it.language}, voice: ${it.resolvedVoice(preferredVoice)}');
        
        try {
          // Copy asset to temp file for reliable iOS playback
          final tempFilePath = await _copyAssetToTempFile(assetPath);
          sources.add(AudioSource.file(tempFilePath, tag: m));
          print('[AudioHandler] Using temp file: $tempFilePath');
        } catch (e) {
          print('[AudioHandler] ERROR copying asset: $assetPath - $e');
          // Fallback to direct asset loading
          sources.add(AudioSource.asset(assetPath, tag: m));
        }
      } else {
        // Production mode: use LockCachingAudioSource for efficient caching
        // This caches audio as it streams, enabling offline replay
        final cachedPath = await _prefetchManager.getCachedPath(audioUrl);
        if (cachedPath != null) {
          // Use cached file directly for instant playback
          print('[AudioHandler] Using cached file for: ${it.id}');
          sources.add(AudioSource.file(cachedPath, tag: m));
        } else {
          // Stream with caching
          sources.add(LockCachingAudioSource(Uri.parse(audioUrl), tag: m));
        }
      }
      queueIndex++;
    }

    queue.add(mediaItems);

    _concatenatingSource = ConcatenatingAudioSource(
      children: sources,
      // Don't use lazy preparation for demo mode - assets are local
      useLazyPreparation: !AppConfig.demoAudio,
    );

    // Adjust initial index for pre-roll ad
    final adjustedIndex = preRollAd != null ? 0 : initialIndex;

    try {
      print('[AudioHandler] Setting audio source with ${mediaItems.length} items, starting at index $adjustedIndex');
      print('[AudioHandler] Demo mode: ${AppConfig.demoAudio}');
      print('[AudioHandler] Sources count: ${sources.length}');
      
      await _player.setAudioSource(
        _concatenatingSource!,
        initialIndex: adjustedIndex.clamp(0, mediaItems.isEmpty ? 0 : mediaItems.length - 1),
      );
      
      print('[AudioHandler] Audio source set successfully');
      print('[AudioHandler] Player duration: ${_player.duration}');
      print('[AudioHandler] Player processing state: ${_player.processingState}');
      _isReady = true;

      // Trigger initial prefetch (skipped in demo mode)
      _triggerPrefetch();

      return true;
    } catch (e, stack) {
      print('[AudioHandler] ERROR setting audio source: $e');
      print('[AudioHandler] Stack: $stack');
      onError?.call(e);
      return false;
    }
  }

  /// Insert a mid-roll ad after the specified content index.
  /// Returns the new queue index of the ad.
  Future<int?> insertMidRollAd(AdCreative ad, {required int afterContentIndex}) async {
    if (_concatenatingSource == null) return null;

    // Calculate actual queue index (accounting for existing ads)
    var queueIndex = afterContentIndex + 1;
    for (final adIdx in _adIndices) {
      if (adIdx <= afterContentIndex) queueIndex++;
    }

    // Clamp to valid range
    if (queueIndex > queue.value.length) {
      queueIndex = queue.value.length;
    }

    final adMediaItem = _createAdMediaItem(ad);
    final adSource = _createAdAudioSource(ad, adMediaItem);

    // Update queue
    final currentQueue = List<MediaItem>.from(queue.value);
    currentQueue.insert(queueIndex, adMediaItem);
    queue.add(currentQueue);

    // Update ad indices
    _adIndices.add(queueIndex);

    // Insert into audio source
    await _concatenatingSource!.insert(queueIndex, adSource);

    return queueIndex;
  }

  /// Create a MediaItem for an ad.
  MediaItem _createAdMediaItem(AdCreative ad) {
    return MediaItem(
      id: ad.mediaUrl,
      title: ad.title,
      album: 'Advertisement',
      duration: ad.duration,
      artUri: null,
      extras: {
        'isAd': true,
        'adId': ad.id,
        'adData': ad.toJson(),
        'skipPolicy': ad.skipPolicy.name,
        'skipOffsetMs': ad.skipOffset?.inMilliseconds,
      },
    );
  }

  /// Create an AudioSource for an ad.
  AudioSource _createAdAudioSource(AdCreative ad, MediaItem mediaItem) {
    if (ad.isOfflineAd) {
      return AudioSource.asset(ad.mediaUrl, tag: mediaItem);
    }
    return AudioSource.uri(Uri.parse(ad.mediaUrl), tag: mediaItem);
  }

  /// Check if the current item is an ad.
  bool get isCurrentItemAd {
    final index = _player.currentIndex;
    return index != null && _adIndices.contains(index);
  }

  /// Get current ad info if playing an ad.
  AdCreative? get currentAd {
    if (!isCurrentItemAd) return null;
    final item = mediaItem.value;
    final adData = item?.extras?['adData'] as Map<String, dynamic>?;
    return adData != null ? AdCreative.fromJson(adData) : null;
  }

  /// Skip the current ad (if allowed).
  Future<bool> skipCurrentAd() async {
    if (!isCurrentItemAd) return false;

    final ad = currentAd;
    if (ad == null) return false;

    // Check skip policy
    if (ad.skipPolicy == AdSkipPolicy.nonSkippable) {
      return false;
    }

    // Check skip offset
    if (ad.skipPolicy == AdSkipPolicy.skippableAfter5s) {
      if (ad.skipOffset != null && _player.position < ad.skipOffset!) {
        return false;
      }
    }

    // Fire skip callback
    onAdSkip?.call(ad.id, _player.position);

    // Skip to next
    await skipToNext();
    return true;
  }

  /// itemId of the currently playing media, if any (for signal logging).
  String? get currentItemId => mediaItem.value?.extras?['itemId'] as String?;

  Stream<Duration> get positionStream => _player.positionStream;
  bool get isPlaying => _player.playing;
  double get speed => _player.speed;
  Stream<double> get speedStream => _player.speedStream;

  /// Set playback speed (0.5x - 2.0x).
  Future<void> setSpeed(double speed) => _player.setSpeed(speed.clamp(0.5, 2.0));

  @override
  Future<void> play() async {
    try {
      print('[AudioHandler] Play requested, isReady: $_isReady, processingState: ${_player.processingState}');
      
      // Activate audio session before playing (important for iOS)
      final session = await AudioSession.instance;
      await session.setActive(true);
      print('[AudioHandler] Audio session activated');
      
      await _player.play();
      print('[AudioHandler] Play command sent successfully, playing: ${_player.playing}');
    } catch (e, stack) {
      print('[AudioHandler] ERROR during play: $e');
      print('[AudioHandler] Stack trace: $stack');
      onError?.call(e);
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // If current item is an ad, fire completion callback
    if (isCurrentItemAd) {
      final ad = currentAd;
      if (ad != null) {
        onAdComplete?.call(ad.id);
      }
    }
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    final currentIndex = _player.currentIndex ?? 0;

    // Find the previous non-ad item
    var targetIndex = currentIndex - 1;
    while (targetIndex >= 0 && _adIndices.contains(targetIndex)) {
      targetIndex--;
    }

    if (targetIndex >= 0) {
      await _player.seek(Duration.zero, index: targetIndex);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _adIndices.clear();
    _concatenatingSource = null;
    await super.stop();
  }

  Future<void> dispose() {
    _adIndices.clear();
    _concatenatingSource = null;
    _queueUrls.clear();
    _prefetchManager.clearTracking();
    _networkMonitor.dispose();
    return _player.dispose();
  }

  /// Get current network quality (for UI display).
  NetworkQuality get networkQuality => _networkMonitor.currentQuality;

  /// Stream of network quality changes.
  Stream<NetworkQuality> get networkQualityStream => _networkMonitor.qualityStream;

  /// Check if a specific URL is cached.
  Future<bool> isUrlCached(String url) => _prefetchManager.isCached(url);

  /// Get buffered position for progress indicators.
  Duration get bufferedPosition => _player.bufferedPosition;

  /// Stream of position for ad skip countdown.
  Stream<Duration> get adPositionStream => _player.positionStream.where((_) => isCurrentItemAd);

  /// Clear ad indices (for queue reset).
  void clearAdState() {
    _adIndices.clear();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
