import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/local/local_store.dart';
import '../../data/models/catalog_item.dart';
import '../../data/models/item_signals.dart';
import '../../features/ads/ad_models.dart';
import '../../features/ads/ad_provider.dart';
import '../../radio_engine/radio_engine.dart';
import 'providers.dart';

/// Snapshot of the live radio session for the UI.
class RadioState {
  final List<CatalogItem> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool loading;
  final bool isPlayingAd;
  final AdCreative? currentAd;

  const RadioState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.loading = false,
    this.isPlayingAd = false,
    this.currentAd,
  });

  CatalogItem? get current =>
      (currentIndex >= 0 && currentIndex < queue.length)
          ? queue[currentIndex]
          : null;

  RadioState copyWith({
    List<CatalogItem>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? loading,
    bool? isPlayingAd,
    AdCreative? currentAd,
    bool clearCurrentAd = false,
  }) =>
      RadioState(
        queue: queue ?? this.queue,
        currentIndex: currentIndex ?? this.currentIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        loading: loading ?? this.loading,
        isPlayingAd: isPlayingAd ?? this.isPlayingAd,
        currentAd: clearCurrentAd ? null : (currentAd ?? this.currentAd),
      );
}

/// Orchestrates: engine builds the queue → audio plays it → playback events
/// update local signals → tail is re-ranked. The only stateful glue in the app.
class RadioController extends Notifier<RadioState> {
  RadioEngine get _engine => ref.read(radioEngineProvider);
  LocalStore get _store => ref.read(localStoreProvider);

  @override
  RadioState build() => const RadioState();

  Map<String, ItemSignals> _signals() => _store.loadAllSignals();

  /// Check if ads are disabled for the current user (premium users).
  bool get _adsDisabled => ref.read(adsDisabledProvider);

  /// Build a fresh radio queue from the user's interests and start playing.
  Future<void> startRadio({List<String>? onlyInterests}) async {
    state = state.copyWith(loading: true);
    final catalog = ref.read(catalogProvider).valueOrNull;
    var profile = ref.read(profileProvider);
    print('[RadioController] startRadio() - Profile languages: ${profile.languages}, interests: ${profile.interests}');
    print('[RadioController] startRadio() - Catalog items: ${catalog?.items.length ?? 0}');
    if (onlyInterests != null) {
      profile = profile.copyWith(interests: onlyInterests);
    }
    if (catalog == null) {
      print('[RadioController] ERROR: Catalog is null!');
      state = state.copyWith(loading: false);
      return;
    }

    final queue = _engine.buildRadio(profile, catalog, _signals(),
        now: DateTime.now());
    print('[RadioController] Built queue with ${queue.length} items');
    if (queue.isEmpty) {
      print('[RadioController] WARNING: Empty queue! Check if profile languages/interests match catalog items');
    }
    state = RadioState(queue: queue, currentIndex: 0, loading: false);

    final handler = ref.read(audioHandlerProvider);

    // Ad decision: check if we should show a pre-roll ad
    // Skip ads in demo mode since VAST ad servers may return incompatible content
    AdCreative? preRollAd;
    if (!_adsDisabled && !AppConfig.demoAudio) {
      final adDecision = ref.read(adDecisionServiceProvider);
      final sessionNotifier = ref.read(adSessionStateProvider.notifier);
      final sessionState = ref.read(adSessionStateProvider);

      final decision = adDecision.shouldShowPreRoll(
        state: sessionState,
        isPremium: _adsDisabled,
      );

      if (decision.show) {
        // Fetch the ad
        final adService = ref.read(adServiceProvider);
        preRollAd = await adService.fetchAd(slotType: AdSlotType.preRoll);

        if (preRollAd != null) {
          sessionNotifier.onAdPlayed(preRollAd.id, isPreRoll: true);
        }
      }
    }

    // Set up ad callbacks
    handler.onAdStart = _onAdStart;
    handler.onAdComplete = _onAdComplete;
    handler.onAdSkip = _onAdSkip;
    handler.onError = _onAudioError;

    final success = await handler.setRadioQueue(
      queue,
      preferredVoice: profile.preferredVoice,
      preRollAd: preRollAd,
    );
    
    if (!success) {
      print('[RadioController] Failed to set radio queue');
      state = state.copyWith(loading: false, isPlaying: false);
      return;
    }
    
    print('[RadioController] Queue set successfully, starting playback');
    await handler.play();

    // If no pre-roll, fire play event for first content
    if (preRollAd == null) {
      _onPlay(0);
    }

    state = state.copyWith(isPlaying: true, isPlayingAd: preRollAd != null);
  }

  /// Called when ad playback starts.
  void _onAdStart(AdCreative ad) {
    state = state.copyWith(isPlayingAd: true, currentAd: ad);

    // Fire impression tracking
    final trackingService = ref.read(adTrackingServiceProvider);
    trackingService.trackImpression(ad);
  }

  /// Called when ad completes naturally.
  void _onAdComplete(String adId) {
    // Update session state
    final sessionNotifier = ref.read(adSessionStateProvider.notifier);
    sessionNotifier.onAdPlayed(adId);

    // Fire complete tracking
    final ad = state.currentAd;
    if (ad != null) {
      final trackingService = ref.read(adTrackingServiceProvider);
      trackingService.trackComplete(ad);
    }

    state = state.copyWith(isPlayingAd: false, clearCurrentAd: true);

    // Fire play event for next content item
    _onPlay(state.currentIndex);
  }

  /// Called when ad is skipped.
  void _onAdSkip(String adId, Duration position) {
    final ad = state.currentAd;
    if (ad != null) {
      final trackingService = ref.read(adTrackingServiceProvider);
      trackingService.trackSkip(ad, position);
    }

    // Still count it as played for frequency capping
    final sessionNotifier = ref.read(adSessionStateProvider.notifier);
    sessionNotifier.onAdPlayed(adId);

    state = state.copyWith(isPlayingAd: false, clearCurrentAd: true);
  }

  /// Called when an audio error occurs.
  void _onAudioError(Object error) {
    print('[RadioController] Audio error: $error');
    state = state.copyWith(loading: false);
    // Try to skip to next track on error
    skipNext();
  }

  Future<void> play() async {
    final handler = ref.read(audioHandlerProvider);
    print('[RadioController] play() called, queue length: ${state.queue.length}, current index: ${state.currentIndex}');
    print('[RadioController] Handler isReady: ${handler.isReady}, isLoading: ${handler.isLoading}');
    await handler.play();
    state = state.copyWith(isPlaying: true);
    print('[RadioController] play() completed, isPlaying: ${handler.isPlaying}');
  }

  Future<void> pause() async {
    await ref.read(audioHandlerProvider).pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> togglePlayPause() =>
      state.isPlaying ? pause() : play();

  Future<void> skipNext() async {
    // If currently playing an ad, use the skip ad method
    if (state.isPlayingAd) {
      final handler = ref.read(audioHandlerProvider);
      final skipped = await handler.skipCurrentAd();
      if (!skipped) {
        // Ad cannot be skipped yet
        return;
      }
    } else {
      final cur = state.current;
      if (cur != null) _logEvent(RadioEvent.skip, cur);
      await ref.read(audioHandlerProvider).skipToNext();

      // Check for mid-roll ad insertion
      await _maybeInsertMidRollAd();
    }
    _advanceTo(state.currentIndex + 1, rerank: true);
  }

  /// Insert a mid-roll ad if conditions are met.
  /// Skip in demo mode since VAST ad servers may return incompatible content.
  Future<void> _maybeInsertMidRollAd() async {
    if (_adsDisabled || AppConfig.demoAudio) return;

    final adDecision = ref.read(adDecisionServiceProvider);
    final sessionNotifier = ref.read(adSessionStateProvider.notifier);
    final sessionState = ref.read(adSessionStateProvider);

    final decision = adDecision.shouldShowMidRoll(
      state: sessionState,
      isPremium: _adsDisabled,
      currentItemIndex: state.currentIndex,
    );

    if (!decision.show) return;

    // Fetch the ad
    final adService = ref.read(adServiceProvider);
    final ad = await adService.fetchAd(slotType: AdSlotType.midRoll);

    if (ad != null) {
      final handler = ref.read(audioHandlerProvider);
      await handler.insertMidRollAd(ad, afterContentIndex: state.currentIndex);
      sessionNotifier.onAdPlayed(ad.id);
    }
  }

  Future<void> skipPrevious() async {
    await ref.read(audioHandlerProvider).skipToPrevious();
    _advanceTo(state.currentIndex - 1, rerank: false);
  }

  Future<void> playAt(int index) async {
    await ref.read(audioHandlerProvider).skipToQueueItem(index);
    _advanceTo(index, rerank: false);
    await play();
  }

  /// Call when the current item finishes naturally.
  Future<void> onComplete() async {
    // If this was an ad, the handler already fired _onAdComplete
    if (state.isPlayingAd) {
      return;
    }

    final cur = state.current;
    if (cur != null) {
      _logEvent(RadioEvent.complete, cur);
      _bumpComplete(cur.id);
    }

    // Increment items since last ad
    final sessionNotifier = ref.read(adSessionStateProvider.notifier);
    sessionNotifier.onContentPlayed();

    // Check for mid-roll ad before advancing
    await _maybeInsertMidRollAd();

    _advanceTo(state.currentIndex + 1, rerank: false);
  }

  void toggleFavorite(String itemId) {
    final s = _store.signalsFor(itemId);
    _store.saveSignals(s.copyWith(favorited: !s.favorited));
    // Trigger listeners that read favorites.
    ref.invalidate(favoritesProvider);
    state = state.copyWith();
  }

  bool isFavorite(String itemId) => _store.signalsFor(itemId).favorited;

  /// Skip the current ad (if allowed by skip policy).
  Future<bool> skipAd() async {
    if (!state.isPlayingAd) return false;

    final handler = ref.read(audioHandlerProvider);
    return handler.skipCurrentAd();
  }

  /// Get the current ad position for skip countdown.
  Duration get adPosition {
    final handler = ref.read(audioHandlerProvider);
    return handler.isCurrentItemAd
        ? handler.positionStream.first as Duration? ?? Duration.zero
        : Duration.zero;
  }

  // ---- internals ------------------------------------------------------------

  void _advanceTo(int index, {required bool rerank}) {
    final clamped = index.clamp(0, (state.queue.length - 1).clamp(0, 1 << 30));
    var queue = state.queue;
    if (rerank && clamped + 1 < queue.length) {
      queue = _engine.rerankTail(
          queue, clamped + 1, ref.read(profileProvider), _signals(),
          now: DateTime.now());
    }
    state = state.copyWith(queue: queue, currentIndex: clamped);
    final cur = state.current;
    if (cur != null) _onPlay(clamped);
  }

  void _onPlay(int index) {
    final cur = (index >= 0 && index < state.queue.length)
        ? state.queue[index]
        : null;
    if (cur == null) return;
    _logEvent(RadioEvent.play, cur);
    final s = _store.signalsFor(cur.id);
    _store.saveSignals(s.copyWith(
      playCount: s.playCount + 1,
      lastPlayedAt: DateTime.now(),
    ));
  }

  void _bumpComplete(String itemId) {
    final s = _store.signalsFor(itemId);
    _store.saveSignals(s.copyWith(completeCount: s.completeCount + 1));
  }

  void _logEvent(RadioEvent event, CatalogItem item) {
    if (event == RadioEvent.skip) {
      final s = _store.signalsFor(item.id);
      _store.saveSignals(s.copyWith(skipCount: s.skipCount + 1));
    }
    _engine.onPlaybackEvent(event, item);
  }
}

final radioControllerProvider =
    NotifierProvider<RadioController, RadioState>(RadioController.new);

/// Favorites + recently-played, derived from local signals.
final favoritesProvider = Provider<List<ItemSignals>>(
    (ref) => ref.read(localStoreProvider).favorites());
final recentlyPlayedProvider = Provider<List<ItemSignals>>(
    (ref) => ref.read(localStoreProvider).recentlyPlayed());
