import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

import '../../core/constants.dart';
import '../../core/widget_service.dart';
import '../../data/local/local_store.dart';
import '../../data/models/catalog_item.dart';
import '../../data/models/item_signals.dart';
import '../../data/models/user_profile.dart';
import '../../features/ads/ad_models.dart';
import '../../features/ads/ad_provider.dart';
import '../../features/engagement/engagement_service.dart';
import '../../features/kids_mode/kids_mode_provider.dart';
import '../../features/player/providers/sleep_timer_provider.dart';
import '../../features/streaks/streaks_service.dart';
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

  /// Set around user-initiated skips so the player-index listener doesn't
  /// treat them as natural (gapless) advances.
  bool _manualAdvance = false;

  /// Whether the previous player index was an ad slot.
  bool _lastWasAd = false;

  /// Guards end-of-queue handling so it only fires once per session.
  bool _queueEnded = false;

  @override
  RadioState build() {
    // Keep isPlaying synced with the real player state so the UI reflects
    // playback started/paused from anywhere (lock screen, headphones, ads).
    final handler = ref.read(audioHandlerProvider);
    final playingSub = handler.playingStream.listen((playing) {
      if (!playing) _saveResumePoint();
      if (state.isPlaying != playing) {
        state = state.copyWith(isPlaying: playing);
      }
    });

    // Single source of truth for the current track: when just_audio advances
    // (gapless auto-advance, lock-screen skip, ad ending), sync currentIndex,
    // log completion signals, and feed the engine/ads/sleep-timer.
    final indexSub =
        handler.currentIndexStream.listen(_onPlayerIndexChanged);

    // End of queue: the index stream doesn't fire when the last item ends.
    final stateSub = handler.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) {
        _onQueueCompleted();
      }
    });

    ref.onDispose(() {
      playingSub.cancel();
      indexSub.cancel();
      stateSub.cancel();
    });
    return const RadioState();
  }

  Map<String, ItemSignals> _signals() => _store.loadAllSignals();

  /// Check if ads are disabled for the current user (premium users).
  bool get _adsDisabled => ref.read(adsDisabledProvider);

  /// Build a fresh radio queue from the user's interests and start playing.
  Future<void> startRadio({List<String>? onlyInterests}) async {
    state = state.copyWith(loading: true);
    _queueEnded = false;
    _manualAdvance = false;
    _lastWasAd = false;
    final catalog = ref.read(catalogProvider).value;
    var profile = ref.read(profileProvider);
    debugPrint('[RadioController] startRadio() - Profile languages: ${profile.languages}, interests: ${profile.interests}');
    debugPrint('[RadioController] startRadio() - Catalog items: ${catalog?.items.length ?? 0}');
    if (onlyInterests != null) {
      profile = profile.copyWith(interests: onlyInterests);
    }
    // Kids Mode always wins: restrict every queue to kid-safe interests.
    if (ref.read(kidsModeProvider)) {
      profile = profile.copyWith(
          interests: KidsModeController.kidSafeInterests);
    }
    if (catalog == null) {
      debugPrint('[RadioController] ERROR: Catalog is null!');
      state = state.copyWith(loading: false);
      return;
    }

    final queue = _engine.buildRadio(profile, catalog, _signals(),
        now: DateTime.now());
    debugPrint('[RadioController] Built queue with ${queue.length} items');
    if (queue.isEmpty) {
      debugPrint('[RadioController] WARNING: Empty queue! Check if profile languages/interests match catalog items');
    }
    await _launchQueue(queue, profile);
  }

  /// Start playback with an explicit, pre-built list of items — used by
  /// Morning Brief, festival rooms, Listener's Choice, offline packs and
  /// "continue listening".
  Future<void> startRadioWithItems(List<CatalogItem> items) async {
    if (items.isEmpty) return;
    state = state.copyWith(loading: true);
    _queueEnded = false;
    _manualAdvance = false;
    _lastWasAd = false;
    var queue = items;
    if (ref.read(kidsModeProvider)) {
      final safe = items
          .where((it) => it.interests
              .any(KidsModeController.kidSafeInterests.contains))
          .toList();
      if (safe.isEmpty) {
        state = state.copyWith(loading: false);
        return;
      }
      queue = safe;
    }
    await _launchQueue(queue, ref.read(profileProvider));
  }

  /// Hand a built queue to the audio handler (ads, callbacks, playback).
  Future<void> _launchQueue(
      List<CatalogItem> queue, UserProfile profile) async {
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
        isPremium: ref.read(profileProvider).isPremium,
        isKidsMode: ref.read(kidsModeProvider),
        inGracePeriod: ref.read(adGracePeriodProvider),
      );

      if (decision.show) {
        // Fetch the ad
        final adService = ref.read(adServiceProvider);
        preRollAd = await adService.fetchAd(
          slotType: AdSlotType.preRoll,
          lastAdId: sessionState.lastPlayedAdId,
        );

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
      debugPrint('[RadioController] Failed to set radio queue');
      state = state.copyWith(loading: false, isPlaying: false);
      return;
    }
    
    debugPrint('[RadioController] Queue set successfully, starting playback');
    await handler.play();

    // Engagement: learn the habitual listening hour (best-effort).
    unawaited(ref.read(engagementControllerProvider).onSessionStart());

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
    debugPrint('[RadioController] Audio error: $error');
    state = state.copyWith(loading: false);
    // Try to skip to next track on error
    skipNext();
  }

  Future<void> play() async {
    final handler = ref.read(audioHandlerProvider);
    if (_queueEnded) {
      // The queue finished: restart from the top instead of a silent no-op.
      _queueEnded = false;
      _manualAdvance = true;
      await handler.skipToQueueItem(handler.playerIndexForContent(0));
      _advanceTo(0, rerank: false);
    }
    debugPrint('[RadioController] play() called, queue length: ${state.queue.length}, current index: ${state.currentIndex}');
    debugPrint('[RadioController] Handler isReady: ${handler.isReady}, isLoading: ${handler.isLoading}');
    await handler.play();
    state = state.copyWith(isPlaying: true);
    debugPrint('[RadioController] play() completed, isPlaying: ${handler.isPlaying}');
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
      _manualAdvance = true;
      final skipped = await handler.skipCurrentAd();
      if (!skipped) {
        // Ad cannot be skipped yet
        _manualAdvance = false;
        return;
      }
      return; // Index listener reconciles state when the ad slot is left.
    }

    final cur = state.current;
    if (cur != null) _logEvent(RadioEvent.skip, cur);
    _manualAdvance = true;
    await ref.read(audioHandlerProvider).skipToNext();

    // Check for mid-roll ad insertion
    await _maybeInsertMidRollAd();
    _advanceTo(state.currentIndex + 1, rerank: true);
  }

  /// Insert a mid-roll ad if conditions are met.
  /// Skip in demo mode since VAST ad servers may return incompatible content.
  Future<void> _maybeInsertMidRollAd() async {
    if (_adsDisabled || AppConfig.demoAudio) return;

    final adDecision = ref.read(adDecisionServiceProvider);
    final sessionNotifier = ref.read(adSessionStateProvider.notifier);
    final sessionState = ref.read(adSessionStateProvider);

    // Never interrupt a bedtime/sleep run with a mid-roll.
    final isBedtimeRun =
        state.current?.interests.contains('bedtime') ?? false;

    final decision = adDecision.shouldShowMidRoll(
      state: sessionState,
      isPremium: ref.read(profileProvider).isPremium,
      currentItemIndex: state.currentIndex,
      isKidsMode: ref.read(kidsModeProvider),
      inGracePeriod: ref.read(adGracePeriodProvider),
      isBedtimeContent: isBedtimeRun,
    );

    if (!decision.show) return;

    // Fetch the ad
    final adService = ref.read(adServiceProvider);
    final ad = await adService.fetchAd(
      slotType: AdSlotType.midRoll,
      lastAdId: sessionState.lastPlayedAdId,
    );

    if (ad != null) {
      final handler = ref.read(audioHandlerProvider);
      await handler.insertMidRollAd(ad, afterContentIndex: state.currentIndex);
      sessionNotifier.onAdPlayed(ad.id);
    }
  }

  Future<void> skipPrevious() async {
    final handler = ref.read(audioHandlerProvider);
    // Standard transport behavior: restart the current track when more than
    // 3 seconds in (or already at the first item); otherwise go back.
    if (handler.position > const Duration(seconds: 3) ||
        state.currentIndex == 0) {
      await handler.seek(Duration.zero);
      return;
    }
    _manualAdvance = true;
    await handler.skipToPrevious();
    _advanceTo(state.currentIndex - 1, rerank: false);
  }

  Future<void> playAt(int index) async {
    final handler = ref.read(audioHandlerProvider);
    _queueEnded = false;
    _manualAdvance = true;
    await handler.skipToQueueItem(handler.playerIndexForContent(index));
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
      _onItemCompleted(cur);
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
    return handler.isCurrentItemAd ? handler.position : Duration.zero;
  }

  // ---- internals ------------------------------------------------------------

  /// Reacts to every player queue-index change — the single source of truth
  /// for [RadioState.currentIndex].
  void _onPlayerIndexChanged(int? playerIndex) {
    if (playerIndex == null || state.queue.isEmpty) return;
    final handler = ref.read(audioHandlerProvider);
    final wasAd = _lastWasAd;
    final contentIndex = handler.contentIndexFor(playerIndex);
    _lastWasAd = contentIndex == null;

    if (contentIndex == null) return; // Ad slot — ad callbacks own the state.

    if (_manualAdvance) {
      // User-initiated skip: state was (or will be) updated by the caller;
      // just reconcile if the player landed somewhere unexpected.
      _manualAdvance = false;
      if (contentIndex != state.currentIndex) {
        state = state.copyWith(currentIndex: contentIndex);
      }
      return;
    }

    if (contentIndex == state.currentIndex) return;
    _handleNaturalAdvance(contentIndex, previousWasAd: wasAd);
  }

  /// A track finished and just_audio advanced gaplessly: log the completion
  /// (engine learning + streaks + ad pacing), notify the sleep timer, sync
  /// state, then consider scheduling a mid-roll after the new item.
  Future<void> _handleNaturalAdvance(int newIndex,
      {required bool previousWasAd}) async {
    if (!previousWasAd) {
      final finished = state.current;
      if (finished != null) {
        _onItemCompleted(finished);
        ref.read(adSessionStateProvider.notifier).onContentPlayed();
        ref.read(sleepTimerProvider.notifier).onEpisodeComplete();
      }
    }
    _advanceTo(newIndex, rerank: false);
    if (!previousWasAd) {
      await _maybeInsertMidRollAd();
    }
  }

  /// The last item in the queue finished playing.
  void _onQueueCompleted() {
    if (_queueEnded || state.queue.isEmpty) return;
    _queueEnded = true;
    final cur = state.current;
    if (cur != null && !state.isPlayingAd) {
      _onItemCompleted(cur);
    }
    ref.read(sleepTimerProvider.notifier).onEpisodeComplete();
    state = state.copyWith(isPlaying: false);
    unawaited(ref.read(widgetServiceProvider).updateNowPlaying(null));
  }

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
    // Keep the home-screen widget in step with playback (best-effort).
    unawaited(
        ref.read(widgetServiceProvider).updateNowPlaying(cur, isPlaying: true));
  }

  void _bumpComplete(String itemId) {
    final s = _store.signalsFor(itemId);
    _store.saveSignals(s.copyWith(completeCount: s.completeCount + 1));
  }

  /// Single funnel for a finished item: engine learning, local signals,
  /// and streak/listening-time stats.
  void _onItemCompleted(CatalogItem item) {
    _logEvent(RadioEvent.complete, item);
    _bumpComplete(item.id);
    final minutes = (item.durationSec / 60).ceil().clamp(1, 120);
    unawaited(ref
        .read(listeningStatsProvider.notifier)
        .recordListening(
          minutes: minutes,
          category: item.primaryInterest,
          language: item.language,
        )
        .then((_) => ref.read(engagementControllerProvider).onItemListened()));
  }

  /// Persist where the listener left off so Home can offer "continue".
  void _saveResumePoint() {
    final cur = state.current;
    if (cur == null || state.isPlayingAd) return;
    final pos = ref.read(audioHandlerProvider).position;
    if (pos < const Duration(seconds: 5)) return;
    _store.putSetting(RadioController.resumePointKey, {
      'itemId': cur.id,
      'positionMs': pos.inMilliseconds,
      'savedAt': DateTime.now().toIso8601String(),
    });
    ref.invalidate(resumePointProvider);
  }

  static const resumePointKey = 'resume_point';

  /// Clear the stored resume point (after resuming or dismissing).
  Future<void> clearResumePoint() async {
    await _store.putSetting(RadioController.resumePointKey, null);
    ref.invalidate(resumePointProvider);
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

/// Where the listener last stopped, for the "Continue listening" card.
class ResumePoint {
  final String itemId;
  final Duration position;
  const ResumePoint({required this.itemId, required this.position});
}

final resumePointProvider = Provider<ResumePoint?>((ref) {
  final raw = ref
      .read(localStoreProvider)
      .getSetting<Map<dynamic, dynamic>>(RadioController.resumePointKey);
  final itemId = raw?['itemId'] as String?;
  final positionMs = raw?['positionMs'] as int?;
  if (itemId == null || positionMs == null) return null;
  return ResumePoint(
      itemId: itemId, position: Duration(milliseconds: positionMs));
});
