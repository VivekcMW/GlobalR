import 'package:flutter/material.dart';

/// Visual layout for a [DisplayAdSlot]. Different screens/contexts call for
/// different shapes — a tall list wants a compact banner, a grid-like
/// section reads better as a native card, a dedicated promo spot can afford
/// a larger block.
enum DisplayAdLayout { banner, card, mediumRectangle }

/// A house/self-promo display ad creative. No third-party ad network is
/// integrated yet (see CHANGELOG) — this is the same house-ad concept
/// [HouseAds] already uses for audio, applied to on-screen display slots.
class DisplayAdCreative {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String ctaLabel;
  final String route; // in-app go_router path

  const DisplayAdCreative({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.ctaLabel,
    required this.route,
  });
}

/// House display-ad inventory + rotation, mirroring [HouseAds]' pattern for
/// audio spots. All in-app (no external links) — Premium upsell leads.
class HouseDisplayAds {
  HouseDisplayAds._();

  static const List<DisplayAdCreative> rotation = [
    DisplayAdCreative(
      id: 'house_display_premium',
      title: 'Go Premium',
      subtitle: 'No ads, every voice, offline listening',
      icon: Icons.workspace_premium_outlined,
      ctaLabel: 'Upgrade',
      route: '/settings',
    ),
    DisplayAdCreative(
      id: 'house_display_referral',
      title: 'Share Global Radio',
      subtitle: 'Invite a friend and you both get a free week of Premium',
      icon: Icons.card_giftcard_outlined,
      ctaLabel: 'Invite',
      route: '/referral',
    ),
    DisplayAdCreative(
      id: 'house_display_interests',
      title: 'Tune your stations',
      subtitle: 'Add more interests to get better picks',
      icon: Icons.tune_rounded,
      ctaLabel: 'Customize',
      route: '/interests',
    ),
  ];

  static DisplayAdCreative next({String? lastAdId}) {
    if (rotation.length == 1) return rotation.first;
    final lastIndex = rotation.indexWhere((ad) => ad.id == lastAdId);
    return rotation[(lastIndex + 1) % rotation.length];
  }
}
