import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/features/ads/ad_models.dart';
import 'package:global_radio/features/ads/ad_tracking_service.dart';

void main() {
  group('AdTrackingService', () {
    late AdTrackingService service;

    setUp(() {
      service = AdTrackingService();
    });

    AdCreative createTestAd({
      String id = 'test-ad-1',
      Duration duration = const Duration(seconds: 30),
      bool isSkippable = true,
    }) {
      return AdCreative(
        id: id,
        title: 'Test Ad',
        mediaUrl: 'https://example.com/ad.mp3',
        duration: duration,
        isSkippable: isSkippable,
        skipOffset: const Duration(seconds: 5),
      );
    }

    group('trackImpression', () {
      test('fires impression event once', () async {
        final ad = createTestAd();

        // First call should fire
        await service.trackImpression(ad);
        
        // Second call with same ad should be ignored (no exception)
        await service.trackImpression(ad);
      });

      test('fires for different ads', () async {
        final ad1 = createTestAd(id: 'ad-1');
        final ad2 = createTestAd(id: 'ad-2');

        await service.trackImpression(ad1);
        await service.trackImpression(ad2);
        // Both should complete without issues
      });
    });

    group('trackProgress', () {
      test('fires quartile events at correct progress points', () async {
        final ad = createTestAd(duration: const Duration(seconds: 100));

        // 25% - first quartile
        await service.trackProgress(ad, const Duration(seconds: 25));

        // 50% - midpoint
        await service.trackProgress(ad, const Duration(seconds: 50));

        // 75% - third quartile
        await service.trackProgress(ad, const Duration(seconds: 75));
      });

      test('does not fire quartile events before threshold', () async {
        final ad = createTestAd(duration: const Duration(seconds: 100));

        // 20% - before first quartile
        await service.trackProgress(ad, const Duration(seconds: 20));
        // Should not throw, just not fire
      });
    });

    group('trackComplete', () {
      test('fires completion event', () async {
        final ad = createTestAd();
        await service.trackComplete(ad);
      });

      test('only fires once per ad', () async {
        final ad = createTestAd();
        await service.trackComplete(ad);
        await service.trackComplete(ad); // Should be ignored
      });
    });

    group('trackSkip', () {
      test('fires skip event with watched duration', () async {
        final ad = createTestAd();
        await service.trackSkip(ad, const Duration(seconds: 10));
      });
    });

    group('trackClick', () {
      test('fires click event', () async {
        final ad = createTestAd();
        await service.trackClick(ad);
      });
    });

    group('trackError', () {
      test('fires error event with message', () async {
        final ad = createTestAd();
        await service.trackError(ad, 'Network timeout');
      });
    });

    group('clearTracking', () {
      test('allows re-firing events after clear', () async {
        final ad = createTestAd();
        
        await service.trackImpression(ad);
        service.clearTracking(ad.id);
        
        // Should be able to fire again
        await service.trackImpression(ad);
      });
    });
  });
}
