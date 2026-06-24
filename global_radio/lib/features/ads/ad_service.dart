import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'ad_models.dart';

/// Service for fetching and parsing VAST (Video Ad Serving Template) responses.
/// VAST is the IAB standard for video/audio ad serving.
///
/// Uses Google's test VAST endpoint for development; replace with production
/// ad network (Google Ad Manager, Triton Digital, etc.) in production.
class AdService {
  final Dio _dio;
  final AdConfig config;

  /// Google's VAST 4.0 test tag - returns a real test ad.
  /// Replace with your ad network's endpoint in production.
  static const String _googleTestVastUrl =
      'https://pubads.g.doubleclick.net/gampad/ads?'
      'iu=/21775744923/external/single_ad_samples&'
      'sz=640x480&'
      'cust_params=sample_ct%3Dlinear&'
      'ciu_szs=300x250%2C728x90&'
      'gdfp_req=1&'
      'output=vast&'
      'unviewed_position_start=1&'
      'env=vp&'
      'impl=s&'
      'correlator=';

  /// Audio-specific test VAST (shorter, audio-friendly).
  static const String _audioTestVastUrl =
      'https://pubads.g.doubleclick.net/gampad/ads?'
      'iu=/21775744923/external/single_preroll_skippable&'
      'sz=640x480&'
      'ciu_szs=300x250%2C728x90&'
      'gdfp_req=1&'
      'output=vast&'
      'unviewed_position_start=1&'
      'env=vp&'
      'impl=s&'
      'correlator=';

  AdService({Dio? dio, this.config = AdConfig.defaults})
      : _dio = dio ?? Dio();

  /// Fetch an ad creative for the given slot type.
  /// Returns null if fetch fails and no fallback is configured.
  Future<AdCreative?> fetchAd({
    required AdSlotType slotType,
    bool isOffline = false,
  }) async {
    // For offline mode, return bundled promo ad
    if (isOffline) {
      return AdCreative.fallback(isOffline: true);
    }

    try {
      final response = await _fetchVast();
      if (response != null) {
        return response.toCreative();
      }
    } catch (e) {
      // Log error but don't crash
      if (kDebugMode) {
        print('AdService: VAST fetch failed: $e');
      }
    }

    // Fallback to bundled ad if configured
    if (config.useFallbackOnError) {
      return AdCreative.fallback();
    }

    return null;
  }

  /// Fetch and parse VAST XML from ad server.
  Future<VastResponse?> _fetchVast() async {
    final url = '$_audioTestVastUrl${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: config.vastTimeout,
          sendTimeout: config.vastTimeout,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseVast(response.data!);
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('AdService: Network error: ${e.message}');
      }
    }

    return null;
  }

  /// Parse VAST XML response.
  /// Simplified parser for VAST 2.0/3.0/4.0 InLine ads.
  VastResponse? _parseVast(String xml) {
    try {
      // Extract Ad ID
      final adIdMatch = RegExp(r'<Ad\s+id="([^"]*)"').firstMatch(xml);
      final adId = adIdMatch?.group(1) ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';

      // Extract title
      final titleMatch = RegExp(r'<AdTitle>([^<]*)</AdTitle>').firstMatch(xml);
      final title = titleMatch?.group(1)?.trim();

      // Extract duration (HH:MM:SS format)
      final durationMatch = RegExp(r'<Duration>(\d{2}):(\d{2}):(\d{2})</Duration>')
          .firstMatch(xml);
      Duration duration = const Duration(seconds: 15); // Default
      if (durationMatch != null) {
        final hours = int.tryParse(durationMatch.group(1)!) ?? 0;
        final minutes = int.tryParse(durationMatch.group(2)!) ?? 0;
        final seconds = int.tryParse(durationMatch.group(3)!) ?? 0;
        duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
      }

      // Extract skip offset (skipoffset="00:00:05" or "5" or "5%")
      int skipOffsetSeconds = config.skipOffsetSeconds;
      final skipMatch = RegExp(r'skipoffset="([^"]*)"').firstMatch(xml);
      if (skipMatch != null) {
        final skipValue = skipMatch.group(1)!;
        if (skipValue.contains(':')) {
          // Time format HH:MM:SS
          final parts = skipValue.split(':');
          if (parts.length >= 3) {
            skipOffsetSeconds = (int.tryParse(parts[0]) ?? 0) * 3600 +
                (int.tryParse(parts[1]) ?? 0) * 60 +
                (int.tryParse(parts[2]) ?? 0);
          }
        } else if (skipValue.endsWith('%')) {
          // Percentage - calculate from duration
          final percent = int.tryParse(skipValue.replaceAll('%', '')) ?? 0;
          skipOffsetSeconds = (duration.inSeconds * percent / 100).round();
        } else {
          skipOffsetSeconds = int.tryParse(skipValue) ?? config.skipOffsetSeconds;
        }
      }

      // Extract media files (prefer audio/mp3)
      final mediaFiles = <String>[];
      final mediaMatches = RegExp(
        r'<MediaFile[^>]*>([^<]+)</MediaFile>',
        multiLine: true,
      ).allMatches(xml);
      for (final match in mediaMatches) {
        final url = match.group(1)?.trim();
        if (url != null && url.isNotEmpty) {
          mediaFiles.add(url);
        }
      }

      // Also check for CDATA wrapped URLs
      final cdataMatches = RegExp(
        r'<MediaFile[^>]*>\s*<!\[CDATA\[([^\]]+)\]\]>\s*</MediaFile>',
        multiLine: true,
      ).allMatches(xml);
      for (final match in cdataMatches) {
        final url = match.group(1)?.trim();
        if (url != null && url.isNotEmpty) {
          mediaFiles.add(url);
        }
      }

      if (mediaFiles.isEmpty) {
        if (kDebugMode) {
          print('AdService: No media files found in VAST');
        }
        return null;
      }

      // Extract impression URLs
      final impressionUrls = <String>[];
      final impressionMatches = RegExp(
        r'<Impression[^>]*>(?:<!\[CDATA\[)?([^\]<]+)(?:\]\]>)?</Impression>',
        multiLine: true,
      ).allMatches(xml);
      for (final match in impressionMatches) {
        final url = match.group(1)?.trim();
        if (url != null && url.isNotEmpty && url.startsWith('http')) {
          impressionUrls.add(url);
        }
      }

      // Extract click through URL
      String? clickThrough;
      final clickMatch = RegExp(
        r'<ClickThrough[^>]*>(?:<!\[CDATA\[)?([^\]<]+)(?:\]\]>)?</ClickThrough>',
      ).firstMatch(xml);
      if (clickMatch != null) {
        clickThrough = clickMatch.group(1)?.trim();
      }

      // Extract tracking events
      final trackingEvents = <String, List<String>>{};
      final trackingMatches = RegExp(
        r'<Tracking\s+event="([^"]+)"[^>]*>(?:<!\[CDATA\[)?([^\]<]+)(?:\]\]>)?</Tracking>',
        multiLine: true,
      ).allMatches(xml);
      for (final match in trackingMatches) {
        final event = match.group(1)?.toLowerCase();
        final url = match.group(2)?.trim();
        if (event != null && url != null && url.startsWith('http')) {
          trackingEvents.putIfAbsent(event, () => []).add(url);
        }
      }

      // Extract error URL
      String? errorUrl;
      final errorMatch = RegExp(
        r'<Error[^>]*>(?:<!\[CDATA\[)?([^\]<]+)(?:\]\]>)?</Error>',
      ).firstMatch(xml);
      if (errorMatch != null) {
        errorUrl = errorMatch.group(1)?.trim();
      }

      return VastResponse(
        adId: adId,
        adTitle: title,
        mediaFiles: mediaFiles,
        duration: duration,
        impressionUrls: impressionUrls,
        clickThrough: clickThrough,
        trackingEvents: trackingEvents,
        skipOffsetSeconds: skipOffsetSeconds,
        errorUrl: errorUrl,
      );
    } catch (e) {
      if (kDebugMode) {
        print('AdService: VAST parse error: $e');
      }
      return null;
    }
  }

  /// Pre-fetch multiple ads for offline packs.
  /// Returns list of successfully fetched creatives.
  Future<List<AdCreative>> prefetchAdsForOffline(int count) async {
    final ads = <AdCreative>[];

    for (var i = 0; i < count; i++) {
      final ad = await fetchAd(slotType: AdSlotType.midRoll);
      if (ad != null) {
        ads.add(ad);
      }

      // Add small delay between fetches to avoid rate limiting
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Always include fallback promo ad
    if (ads.isEmpty) {
      ads.add(AdCreative.fallback(isOffline: true));
    }

    return ads;
  }
}

/// Extension for selecting best media file from VAST response.
extension MediaFileSelector on List<String> {
  /// Select best audio file URL.
  String? get bestAudioUrl {
    // Priority: MP3 > M4A > any audio > first file
    final mp3 = firstWhere(
      (url) => url.toLowerCase().contains('.mp3'),
      orElse: () => '',
    );
    if (mp3.isNotEmpty) return mp3;

    final m4a = firstWhere(
      (url) => url.toLowerCase().contains('.m4a'),
      orElse: () => '',
    );
    if (m4a.isNotEmpty) return m4a;

    final audio = firstWhere(
      (url) => url.toLowerCase().contains('audio'),
      orElse: () => '',
    );
    if (audio.isNotEmpty) return audio;

    return isNotEmpty ? first : null;
  }
}
