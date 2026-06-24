import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../core/constants.dart';
import '../data/models/catalog_item.dart';
import '../features/ads/ad_models.dart';

/// Background audio handler: wraps just_audio behind audio_service so playback
/// continues in the background with lock-screen controls (docs tech-spec §1).
///
/// Builds a gapless queue and prefetches lazily. Voice resolution + URL
/// building happens before items reach here (via [CatalogItem.audioUrlFor]).
///
/// Supports ad insertion (pre-roll, mid-roll) with skip-after-5s behavior.
class GlobalRadioAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  /// Tracks which queue indices are ads (for UI and skip prevention).
  final Set<int> _adIndices = {};

  /// Callback when ad playback starts (for UI notification).
  void Function(AdCreative ad)? onAdStart;

  /// Callback when ad playback completes (for state update).
  void Function(String adId)? onAdComplete;

  /// Callback when ad is skipped.
  void Function(String adId, Duration position)? onAdSkip;

  /// The concatenating source for dynamic ad insertion.
  ConcatenatingAudioSource? _concatenatingSource;

  GlobalRadioAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.currentIndexStream.listen(_onIndexChanged);
  }

  /// Handle track changes, including ad detection.
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
    }
  }

  /// Convert engine output (CatalogItem queue) into a playable source.
  Future<void> setRadioQueue(
    List<CatalogItem> items, {
    required String preferredVoice,
    int initialIndex = 0,
    AdCreative? preRollAd,
  }) async {
    _adIndices.clear();

    final mediaItems = <MediaItem>[];
    final sources = <AudioSource>[];
    var queueIndex = 0;

    // Insert pre-roll ad if provided
    if (preRollAd != null) {
      final adMediaItem = _createAdMediaItem(preRollAd);
      mediaItems.add(adMediaItem);
      sources.add(_createAdAudioSource(preRollAd, adMediaItem));
      _adIndices.add(queueIndex);
      queueIndex++;
    }

    // Add content items
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final m = MediaItem(
        id: it.audioUrlFor(preferredVoice),
        title: it.title,
        album: it.interests.join(', '),
        duration: Duration(seconds: it.durationSec),
        artUri: null,
        extras: {'itemId': it.id, 'type': it.type, 'isAd': false},
      );
      mediaItems.add(m);

      if (AppConfig.demoAudio) {
        sources.add(
            AudioSource.asset(it.demoAssetFor(preferredVoice), tag: m));
      } else {
        sources.add(AudioSource.uri(Uri.parse(m.id), tag: m));
      }
      queueIndex++;
    }

    queue.add(mediaItems);

    _concatenatingSource = ConcatenatingAudioSource(children: sources);

    // Adjust initial index for pre-roll ad
    final adjustedIndex = preRollAd != null ? 0 : initialIndex;

    await _player.setAudioSource(
      _concatenatingSource!,
      initialIndex: adjustedIndex.clamp(0, mediaItems.isEmpty ? 0 : mediaItems.length - 1),
    );
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
  Future<void> play() => _player.play();

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
    return _player.dispose();
  }

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
