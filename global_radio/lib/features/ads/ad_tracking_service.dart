import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import 'ad_models.dart';

/// Ad tracking event types.
enum AdTrackingEvent {
  impression,   // Ad started playing
  firstQuartile, // 25% complete
  midpoint,     // 50% complete
  thirdQuartile, // 75% complete
  complete,     // 100% complete
  skip,         // User skipped
  click,        // User clicked through
  error,        // Playback error
}

/// Service for firing ad tracking pixels.
/// Handles impression, quartile, completion, and click tracking.
class AdTrackingService {
  final Dio _dio;
  final AnalyticsService? _analytics;

  /// Tracks which events have been fired for each ad to prevent duplicates.
  final Map<String, Set<AdTrackingEvent>> _firedEvents = {};

  AdTrackingService({Dio? dio, AnalyticsService? analytics})
      : _dio = dio ?? Dio(),
        _analytics = analytics;

  /// Fire impression pixel when ad starts playing.
  Future<void> trackImpression(AdCreative ad) async {
    if (_hasFired(ad.id, AdTrackingEvent.impression)) return;

    _markFired(ad.id, AdTrackingEvent.impression);

    if (ad.impressionUrl != null) {
      await _firePixel(ad.impressionUrl!);
    }

    _logEvent('AD_IMPRESSION', ad);
  }

  /// Fire quartile tracking based on playback progress.
  Future<void> trackProgress(AdCreative ad, Duration position) async {
    final progress = position.inMilliseconds / ad.duration.inMilliseconds;

    if (progress >= 0.25 && !_hasFired(ad.id, AdTrackingEvent.firstQuartile)) {
      _markFired(ad.id, AdTrackingEvent.firstQuartile);
      _logEvent('AD_FIRST_QUARTILE', ad);
    }

    if (progress >= 0.50 && !_hasFired(ad.id, AdTrackingEvent.midpoint)) {
      _markFired(ad.id, AdTrackingEvent.midpoint);
      _logEvent('AD_MIDPOINT', ad);
    }

    if (progress >= 0.75 && !_hasFired(ad.id, AdTrackingEvent.thirdQuartile)) {
      _markFired(ad.id, AdTrackingEvent.thirdQuartile);
      _logEvent('AD_THIRD_QUARTILE', ad);
    }
  }

  /// Fire completion pixel when ad finishes.
  Future<void> trackComplete(AdCreative ad) async {
    if (_hasFired(ad.id, AdTrackingEvent.complete)) return;

    _markFired(ad.id, AdTrackingEvent.complete);

    if (ad.completeUrl != null) {
      await _firePixel(ad.completeUrl!);
    }

    _logEvent('AD_COMPLETE', ad);
  }

  /// Fire skip pixel when user skips ad.
  Future<void> trackSkip(AdCreative ad, Duration position) async {
    if (_hasFired(ad.id, AdTrackingEvent.skip)) return;

    _markFired(ad.id, AdTrackingEvent.skip);

    if (ad.skipTrackingUrl != null) {
      await _firePixel(ad.skipTrackingUrl!);
    }

    _logEvent('AD_SKIP', ad, extra: {'skipAt': position.inSeconds});
  }

  /// Fire click tracking pixel.
  Future<void> trackClick(AdCreative ad) async {
    if (_hasFired(ad.id, AdTrackingEvent.click)) return;

    _markFired(ad.id, AdTrackingEvent.click);

    if (ad.clickTrackingUrl != null) {
      await _firePixel(ad.clickTrackingUrl!);
    }

    _logEvent('AD_CLICK', ad);
  }

  /// Fire error pixel on playback failure.
  Future<void> trackError(AdCreative ad, String errorMessage) async {
    if (_hasFired(ad.id, AdTrackingEvent.error)) return;

    _markFired(ad.id, AdTrackingEvent.error);

    if (ad.errorUrl != null) {
      // VAST error URLs often have [ERRORCODE] macro
      final errorUrl = ad.errorUrl!
          .replaceAll('[ERRORCODE]', '400')
          .replaceAll('[ERRORMESSAGE]', Uri.encodeComponent(errorMessage));
      await _firePixel(errorUrl);
    }

    _logEvent('AD_ERROR', ad, extra: {'error': errorMessage});
  }

  /// Clear tracking state for an ad (for replay scenarios).
  void clearTrackingState(String adId) {
    _firedEvents.remove(adId);
  }

  /// Clear all tracking state (on session reset).
  void clearAllTrackingState() {
    _firedEvents.clear();
  }

  // --- Private helpers ---

  bool _hasFired(String adId, AdTrackingEvent event) {
    return _firedEvents[adId]?.contains(event) ?? false;
  }

  void _markFired(String adId, AdTrackingEvent event) {
    _firedEvents.putIfAbsent(adId, () => {}).add(event);
  }

  /// Fire a tracking pixel (GET request, fire-and-forget).
  Future<void> _firePixel(String url) async {
    try {
      // Add cache-busting parameter
      final separator = url.contains('?') ? '&' : '?';
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final finalUrl = '$url${separator}cb=$cacheBuster';

      await _dio.get(
        finalUrl,
        options: Options(
          // Fire and forget - don't wait for response
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          // Accept any response
          validateStatus: (_) => true,
        ),
      );
    } catch (e) {
      // Tracking failures are non-critical - log but don't crash
      if (kDebugMode) {
        print('AdTracking: Pixel fire failed: $e');
      }
    }
  }

  /// Log event for analytics integration.
  void _logEvent(String eventName, AdCreative ad, {Map<String, dynamic>? extra}) {
    // Determine if ad is skippable based on skip policy
    final isSkippable = ad.skipPolicy != AdSkipPolicy.nonSkippable;

    // Log to analytics service if available
    if (_analytics != null) {
      switch (eventName) {
        case 'AD_IMPRESSION':
          _analytics!.logEvent(AdImpressionEvent(
            adType: isSkippable ? 'skippable' : 'non_skippable',
            adSource: ad.title,
          ));
          break;
        case 'AD_SKIP':
          final secondsWatched = extra?['seconds_watched'] as int? ?? 0;
          _analytics!.logEvent(AdSkipEvent(
            adType: isSkippable ? 'skippable' : 'non_skippable',
            secondsWatched: secondsWatched,
          ));
          break;
        case 'AD_COMPLETE':
          _analytics!.logEvent(AdCompleteEvent(
            adType: isSkippable ? 'skippable' : 'non_skippable',
            durationSeconds: ad.duration.inSeconds,
          ));
          break;
      }
    }

    // Also log to console for debugging
    final params = <String, dynamic>{
      'ad_id': ad.id,
      'ad_title': ad.title,
      'ad_duration': ad.duration.inSeconds,
      'is_offline_ad': ad.isOfflineAd,
      ...?extra,
    };

    if (kDebugMode) {
      print('AdTracking: $eventName $params');
    }
  }
}

/// Extension for easy progress tracking.
extension AdTrackingExtension on AdTrackingService {
  /// Track all relevant events based on playback position.
  Future<void> updatePlaybackProgress(
    AdCreative ad,
    Duration position,
    bool isComplete,
  ) async {
    await trackProgress(ad, position);

    if (isComplete) {
      await trackComplete(ad);
    }
  }
}
