import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/providers.dart';
import '../../kids_mode/kids_mode_provider.dart';
import '../display_ad_models.dart';

/// A house-ad display slot. Never shown to Premium users or in Kids Mode —
/// same policy as the audio ad system and [SponsoredStationCard]. Picks the
/// next creative in [HouseDisplayAds]' rotation each time it's built, so
/// scrolling past several slots on one screen cycles through the roster
/// instead of repeating the same one.
///
/// Place with a [layout] matching its context:
/// - [DisplayAdLayout.banner]: compact strip for dense lists (Library, Settings)
/// - [DisplayAdLayout.card]: native card matching surrounding Card-based UI (Home)
/// - [DisplayAdLayout.mediumRectangle]: larger standalone block (dedicated promo spots)
class DisplayAdSlot extends ConsumerWidget {
  final DisplayAdLayout layout;
  final String? lastAdId;

  const DisplayAdSlot({super.key, required this.layout, this.lastAdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile.isPremium) return const SizedBox.shrink();
    if (ref.watch(kidsModeProvider)) return const SizedBox.shrink();

    final ad = HouseDisplayAds.next(lastAdId: lastAdId);
    return switch (layout) {
      DisplayAdLayout.banner => _AdBanner(ad: ad),
      DisplayAdLayout.card => _AdCard(ad: ad),
      DisplayAdLayout.mediumRectangle => _AdMediumRectangle(ad: ad),
    };
  }
}

/// Compact horizontal strip — fits inline in a dense list without breaking
/// its rhythm.
class _AdBanner extends StatelessWidget {
  final DisplayAdCreative ad;
  const _AdBanner({required this.ad});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(ad.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(ad.icon, size: 20, color: scheme.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${ad.title} — ${ad.subtitle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(ad.ctaLabel,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.secondary, fontWeight: FontWeight.w600)),
            const _AdDisclosure(),
          ],
        ),
      ),
    );
  }
}

/// Native card matching the Card-based rows already used on Home/Library.
class _AdCard extends StatelessWidget {
  final DisplayAdCreative ad;
  const _AdCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(ad.icon, color: scheme.secondary),
        title: Row(
          children: [
            Flexible(child: Text(ad.title)),
            const SizedBox(width: 8),
            const _AdDisclosure(),
          ],
        ),
        subtitle: Text(ad.subtitle),
        trailing: FilledButton.tonal(
          onPressed: () => context.push(ad.route),
          child: Text(ad.ctaLabel),
        ),
      ),
    );
  }
}

/// Larger standalone block for a dedicated promo spot (e.g. between major
/// sections, or a placeholder for a future 300x250-style network creative).
class _AdMediumRectangle extends StatelessWidget {
  final DisplayAdCreative ad;
  const _AdMediumRectangle({required this.ad});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(ad.route),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              scheme.secondaryContainer,
              scheme.secondaryContainer.withValues(alpha: 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ad.icon, size: 32, color: scheme.onSecondaryContainer),
                const Spacer(),
                const _AdDisclosure(),
              ],
            ),
            const SizedBox(height: 12),
            Text(ad.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: scheme.onSecondaryContainer)),
            const SizedBox(height: 4),
            Text(ad.subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSecondaryContainer)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(ad.route),
              child: Text(ad.ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "Ad" label — every layout carries a disclosure, same principle as
/// [SponsoredStationCard]'s "Sponsored" chip.
class _AdDisclosure extends StatelessWidget {
  const _AdDisclosure();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('Ad',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant)),
    );
  }
}
