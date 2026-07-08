import 'ad_models.dart';

/// House ad inventory: our own promo spots that fill unfilled slots and take
/// a configured share (`AdConfig.houseAdRatio`) of served ads.
///
/// Waterfall position: direct-sold -> programmatic VAST -> house.
/// House creatives are bundled assets so they also work offline; every spot
/// ends with the Premium "remove ads" pitch and deep-links to the paywall.
class HouseAds {
  HouseAds._();

  /// Rotation order matters: Premium promo leads (primary upsell funnel).
  static const List<AdCreative> rotation = [
    AdCreative(
      id: 'house_premium_promo',
      title: 'Global Radio Premium — no ads, all voices, offline',
      mediaUrl: 'assets/audio/ads/house_premium_promo.mp3',
      duration: Duration(seconds: 13),
      skipPolicy: AdSkipPolicy.skippableAfter5s,
      skipOffset: Duration(seconds: 5),
      clickThroughUrl: 'https://globalradio.app/premium',
      isOfflineAd: true,
    ),
    AdCreative(
      id: 'house_referral_promo',
      title: 'Share Global Radio with a friend',
      mediaUrl: 'assets/audio/ads/house_referral_promo.mp3',
      duration: Duration(seconds: 9),
      skipPolicy: AdSkipPolicy.skippableAfter5s,
      skipOffset: Duration(seconds: 5),
      clickThroughUrl: 'https://globalradio.app/',
      isOfflineAd: true,
    ),
  ];

  /// Next house creative, rotating and never repeating [lastAdId].
  static AdCreative next({String? lastAdId}) {
    if (rotation.length == 1) return rotation.first;
    final lastIndex = rotation.indexWhere((ad) => ad.id == lastAdId);
    return rotation[(lastIndex + 1) % rotation.length];
  }
}
