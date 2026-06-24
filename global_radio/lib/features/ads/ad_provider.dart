import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/providers/providers.dart';
import 'ad_decision_service.dart';
import 'ad_models.dart';
import 'ad_service.dart';
import 'ad_tracking_service.dart';

// --- Service Providers ---

/// Ad configuration provider.
final adConfigProvider = Provider<AdConfig>((ref) => AdConfig.defaults);

/// Ad service provider for VAST fetching.
final adServiceProvider = Provider<AdService>((ref) {
  final config = ref.watch(adConfigProvider);
  return AdService(config: config);
});

/// Ad decision service provider.
final adDecisionServiceProvider = Provider<AdDecisionService>((ref) {
  final config = ref.watch(adConfigProvider);
  return AdDecisionService(config: config);
});

/// Ad tracking service provider.
final adTrackingServiceProvider = Provider<AdTrackingService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return AdTrackingService(analytics: analytics);
});

// --- State Providers ---

/// Session state for ad frequency capping.
final adSessionStateProvider =
    NotifierProvider<AdSessionNotifier, AdSessionState>(AdSessionNotifier.new);

/// Current ad playback state for UI.
final adPlaybackStateProvider =
    NotifierProvider<AdPlaybackNotifier, AdPlaybackState>(
        AdPlaybackNotifier.new);

/// Whether ads are currently disabled (premium user).
final adsDisabledProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider);
  return profile.isPremium;
});

// --- Notifiers ---

/// Manages ad session state.
class AdSessionNotifier extends Notifier<AdSessionState> {
  @override
  AdSessionState build() {
    return AdSessionState.newSession();
  }

  /// Record that a content item finished playing.
  void onContentPlayed() {
    state = state.onContentPlayed();
  }

  /// Record that an ad finished playing.
  void onAdPlayed(String adId, {bool isPreRoll = false}) {
    state = state.onAdPlayed(adId, isPreRoll: isPreRoll);
  }

  /// Reset for a new listening session.
  void resetSession() {
    state = AdSessionState.newSession();

    // Also clear tracking state
    ref.read(adTrackingServiceProvider).clearAllTrackingState();
  }

  /// Check if pre-roll should be shown.
  AdDecision shouldShowPreRoll() {
    final isPremium = ref.read(adsDisabledProvider);
    return ref.read(adDecisionServiceProvider).shouldShowPreRoll(
          state: state,
          isPremium: isPremium,
        );
  }

  /// Check if mid-roll should be shown after current item.
  AdDecision shouldShowMidRoll(int currentIndex, {String? candidateAdId}) {
    final isPremium = ref.read(adsDisabledProvider);
    return ref.read(adDecisionServiceProvider).shouldShowMidRoll(
          state: state,
          isPremium: isPremium,
          currentItemIndex: currentIndex,
          candidateAdId: candidateAdId,
        );
  }
}

/// Manages current ad playback state for UI.
class AdPlaybackNotifier extends Notifier<AdPlaybackState> {
  Timer? _skipTimer;

  @override
  AdPlaybackState build() {
    ref.onDispose(() => _skipTimer?.cancel());
    return const AdPlaybackState();
  }

  /// Start playing an ad.
  void startAd(AdCreative ad) {
    _skipTimer?.cancel();

    state = AdPlaybackState(
      currentAd: ad,
      position: Duration.zero,
      canSkip: ad.skipPolicy == AdSkipPolicy.alwaysSkippable,
      skipAvailableIn: ad.skipOffset,
    );

    // Fire impression
    ref.read(adTrackingServiceProvider).trackImpression(ad);

    // Start skip countdown timer if skippable after delay
    if (ad.skipPolicy == AdSkipPolicy.skippableAfter5s &&
        ad.skipOffset != null) {
      _startSkipCountdown(ad.skipOffset!);
    }
  }

  /// Update playback position.
  void updatePosition(Duration position) {
    final ad = state.currentAd;
    if (ad == null) return;

    final remaining = ad.skipOffset != null && !state.canSkip
        ? ad.skipOffset! - position
        : null;

    state = state.copyWith(
      position: position,
      skipAvailableIn: remaining != null && remaining.inSeconds > 0
          ? remaining
          : null,
      canSkip: state.canSkip ||
          (ad.skipOffset != null && position >= ad.skipOffset!),
    );

    // Track progress
    ref.read(adTrackingServiceProvider).trackProgress(ad, position);
  }

  /// Ad completed naturally.
  void completeAd() {
    final ad = state.currentAd;
    if (ad == null) return;

    ref.read(adTrackingServiceProvider).trackComplete(ad);
    ref.read(adSessionStateProvider.notifier).onAdPlayed(ad.id);

    _cleanup();
  }

  /// User skipped the ad.
  void skipAd() {
    final ad = state.currentAd;
    if (ad == null || !state.canSkip) return;

    ref.read(adTrackingServiceProvider).trackSkip(ad, state.position);
    ref.read(adSessionStateProvider.notifier).onAdPlayed(ad.id);

    _cleanup();
  }

  /// Ad playback error.
  void onError(String message) {
    final ad = state.currentAd;
    if (ad != null) {
      ref.read(adTrackingServiceProvider).trackError(ad, message);
    }

    _cleanup();
  }

  /// User clicked on ad.
  Future<void> onClick() async {
    final ad = state.currentAd;
    if (ad == null || ad.clickThroughUrl == null) return;

    await ref.read(adTrackingServiceProvider).trackClick(ad);

    // Launch the ad click-through URL
    final uri = Uri.tryParse(ad.clickThroughUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _startSkipCountdown(Duration skipOffset) {
    _skipTimer = Timer(skipOffset, () {
      if (state.currentAd != null) {
        state = state.copyWith(canSkip: true, skipAvailableIn: null);
      }
    });
  }

  void _cleanup() {
    _skipTimer?.cancel();
    _skipTimer = null;
    state = const AdPlaybackState();
  }
}

// --- Utility Providers ---

/// Whether an ad is currently playing.
final isAdPlayingProvider = Provider<bool>((ref) {
  return ref.watch(adPlaybackStateProvider).currentAd != null;
});

/// Current ad (if playing).
final currentAdProvider = Provider<AdCreative?>((ref) {
  return ref.watch(adPlaybackStateProvider).currentAd;
});

/// Whether skip button should be visible.
final canSkipAdProvider = Provider<bool>((ref) {
  return ref.watch(adPlaybackStateProvider).canSkip;
});

/// Time until skip is available (for countdown UI).
final skipCountdownProvider = Provider<Duration?>((ref) {
  return ref.watch(adPlaybackStateProvider).skipAvailableIn;
});

/// Ads remaining in session.
final adsRemainingProvider = Provider<int>((ref) {
  final config = ref.watch(adConfigProvider);
  final state = ref.watch(adSessionStateProvider);
  return (config.maxAdsPerSession - state.adsPlayedThisSession).clamp(0, config.maxAdsPerSession);
});

// --- Action Providers ---

/// Fetch an ad for the given slot type.
final fetchAdProvider = FutureProvider.family<AdCreative?, AdSlotType>(
  (ref, slotType) async {
    // Premium users don't fetch ads
    if (ref.read(adsDisabledProvider)) return null;

    final adService = ref.read(adServiceProvider);
    return await adService.fetchAd(slotType: slotType);
  },
);

/// Pre-fetch ads for offline pack.
final prefetchOfflineAdsProvider = FutureProvider.family<List<AdCreative>, int>(
  (ref, count) async {
    // Premium users don't get offline ads
    if (ref.read(adsDisabledProvider)) return [];

    final adService = ref.read(adServiceProvider);
    return await adService.prefetchAdsForOffline(count);
  },
);
