import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/features/ads/ad_decision_service.dart';
import 'package:global_radio/features/ads/ad_models.dart';
import 'package:global_radio/features/ads/ad_service.dart';
import 'package:global_radio/features/ads/house_ads.dart';

void main() {
  // An enabled config for rule tests (compiled defaults ship dark).
  const liveConfig = AdConfig(enabled: true);
  final now = DateTime(2026, 7, 4, 20, 0);

  group('AdDecisionService kill switch', () {
    test('default config keeps ads dark', () {
      final service = AdDecisionService(); // AdConfig.defaults
      final decision = service.shouldShowPreRoll(
        state: AdSessionState.newSession(),
        isPremium: false,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, contains('kill switch'));
    });

    test('mid-roll also gated by kill switch', () {
      final service = AdDecisionService();
      final decision = service.shouldShowMidRoll(
        state: const AdSessionState(itemsSinceLastAd: 10),
        isPremium: false,
        currentItemIndex: 5,
      );
      expect(decision.show, isFalse);
    });
  });

  group('AdDecisionService hard gates', () {
    final service = AdDecisionService(config: liveConfig);

    test('Kids Mode never sees ads', () {
      final decision = service.shouldShowMidRoll(
        state: const AdSessionState(itemsSinceLastAd: 10),
        isPremium: false,
        currentItemIndex: 5,
        isKidsMode: true,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, 'Kids Mode');
    });

    test('premium users never see ads', () {
      final decision = service.shouldShowPreRoll(
        state: AdSessionState.newSession(),
        isPremium: true,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, 'Premium user');
    });

    test('install grace period suppresses ads', () {
      final decision = service.shouldShowPreRoll(
        state: AdSessionState.newSession(),
        isPremium: false,
        inGracePeriod: true,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, 'Install grace period');
    });

    test('bedtime run suppresses mid-rolls', () {
      final decision = service.shouldShowMidRoll(
        state: const AdSessionState(itemsSinceLastAd: 10),
        isPremium: false,
        currentItemIndex: 5,
        isBedtimeContent: true,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, 'Bedtime run');
    });

    test('bedtime suppression can be disabled remotely', () {
      final relaxed = AdDecisionService(
          config: const AdConfig(enabled: true, suppressDuringBedtime: false));
      final decision = relaxed.shouldShowMidRoll(
        state: const AdSessionState(itemsSinceLastAd: 10),
        isPremium: false,
        currentItemIndex: 5,
        isBedtimeContent: true,
        now: now,
      );
      expect(decision.show, isTrue);
    });
  });

  group('AdDecisionService pacing', () {
    final service = AdDecisionService(config: liveConfig);

    test('mid-roll requires N items since last ad', () {
      final decision = service.shouldShowMidRoll(
        state: const AdSessionState(itemsSinceLastAd: 3),
        isPremium: false,
        currentItemIndex: 5,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, contains('items since last ad'));
    });

    test('min wall-clock gap wins over item count', () {
      // 10 items played but the last ad was only 5 minutes ago.
      final state = AdSessionState(
        itemsSinceLastAd: 10,
        lastAdAt: now.subtract(const Duration(minutes: 5)),
        adTimestamps: [now.subtract(const Duration(minutes: 5))],
        adsPlayedThisSession: 1,
      );
      final decision = service.shouldShowMidRoll(
        state: state,
        isPremium: false,
        currentItemIndex: 10,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, contains('minutes since last ad'));
    });

    test('mid-roll shows when both item and time gates pass', () {
      final state = AdSessionState(
        itemsSinceLastAd: 4,
        lastAdAt: now.subtract(const Duration(minutes: 15)),
        adTimestamps: [now.subtract(const Duration(minutes: 15))],
        adsPlayedThisSession: 1,
      );
      final decision = service.shouldShowMidRoll(
        state: state,
        isPremium: false,
        currentItemIndex: 10,
        now: now,
      );
      expect(decision.show, isTrue);
    });

    test('session cap blocks further ads', () {
      final state = AdSessionState(
        itemsSinceLastAd: 10,
        adsPlayedThisSession: liveConfig.maxAdsPerSession,
        lastAdAt: now.subtract(const Duration(hours: 2)),
      );
      final decision = service.shouldShowMidRoll(
        state: state,
        isPremium: false,
        currentItemIndex: 30,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, 'Session ad limit reached');
    });

    test('hourly cap blocks a burst of ads', () {
      final recent = List.generate(
          liveConfig.maxAdsPerHour,
          (i) => now.subtract(Duration(minutes: 13 * (i + 1))));
      final state = AdSessionState(
        itemsSinceLastAd: 10,
        adsPlayedThisSession: liveConfig.maxAdsPerHour,
        lastAdAt: recent.first,
        adTimestamps: recent,
      );
      final decision = service.shouldShowMidRoll(
        state: state,
        isPremium: false,
        currentItemIndex: 30,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, 'Hourly ad limit reached');
    });

    test('hourly cap frees up as ads age out of the window', () {
      final old = List.generate(
          4, (i) => now.subtract(Duration(minutes: 70 + i * 15)));
      final state = AdSessionState(
        itemsSinceLastAd: 10,
        adsPlayedThisSession: 4,
        lastAdAt: old.first,
        adTimestamps: old,
      );
      expect(state.adsInLastHour(now), 0);
      final decision = service.shouldShowMidRoll(
        state: state,
        isPremium: false,
        currentItemIndex: 30,
        now: now,
      );
      expect(decision.show, isTrue);
    });

    test('same ad never plays twice in a row', () {
      final state = AdSessionState(
        itemsSinceLastAd: 10,
        lastPlayedAdId: 'ad_1',
        lastAdAt: now.subtract(const Duration(minutes: 20)),
        adsPlayedThisSession: 1,
      );
      final decision = service.shouldShowMidRoll(
        state: state,
        isPremium: false,
        currentItemIndex: 10,
        candidateAdId: 'ad_1',
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, 'Same ad as last time');
    });

    test('pre-roll only once per session', () {
      final decision = service.shouldShowPreRoll(
        state: const AdSessionState(preRollShown: true),
        isPremium: false,
        now: now,
      );
      expect(decision.show, isFalse);
      expect(decision.reason, 'Pre-roll already shown');
    });
  });

  group('AdSessionState', () {
    test('onAdPlayed records timestamp and resets item counter', () {
      final state = const AdSessionState(itemsSinceLastAd: 5)
          .onAdPlayed('ad_1', at: now);
      expect(state.itemsSinceLastAd, 0);
      expect(state.lastAdAt, now);
      expect(state.adTimestamps, [now]);
      expect(state.adsPlayedThisSession, 1);
    });
  });

  group('Offline pack ads', () {
    test('kill switch and Kids Mode exclude offline ads', () {
      final dark = AdDecisionService();
      expect(
        dark.shouldIncludeAdsInOfflinePack(isPremium: false, packItemCount: 10),
        isFalse,
      );

      final live = AdDecisionService(config: liveConfig);
      expect(
        live.shouldIncludeAdsInOfflinePack(
            isPremium: false, packItemCount: 10, isKidsMode: true),
        isFalse,
      );
      expect(
        live.adsForOfflinePack(
            packItemCount: 10, isPremium: false, isKidsMode: true),
        0,
      );
      expect(
        live.shouldIncludeAdsInOfflinePack(isPremium: false, packItemCount: 10),
        isTrue,
      );
    });
  });

  group('House ads', () {
    test('rotation never repeats the last ad', () {
      final first = HouseAds.next();
      final second = HouseAds.next(lastAdId: first.id);
      expect(second.id, isNot(first.id));
    });

    test('house creatives are bundled assets with premium click-through', () {
      for (final ad in HouseAds.rotation) {
        expect(ad.isOfflineAd, isTrue);
        expect(ad.mediaUrl, startsWith('assets/audio/ads/'));
      }
      expect(HouseAds.rotation.first.clickThroughUrl, contains('premium'));
    });

    test('house slot reservation follows configured ratio', () {
      final service = AdService(
          config: const AdConfig(enabled: true, houseAdRatio: 0.25));
      final houseSlots =
          List.generate(8, (i) => service.isHouseSlot(i + 1));
      expect(houseSlots, [
        false, false, false, true, // every 4th ad
        false, false, false, true,
      ]);
    });

    test('houseAdRatio 0 disables reserved house slots', () {
      final service =
          AdService(config: const AdConfig(enabled: true, houseAdRatio: 0));
      expect(List.generate(10, (i) => service.isHouseSlot(i + 1)),
          everyElement(isFalse));
    });
  });
}
