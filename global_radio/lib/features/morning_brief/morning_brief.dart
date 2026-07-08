import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/catalog_item.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../streaks/streaks_service.dart';

/// Interests in the order they appear in the brief.
const _briefOrder = <String>[
  'news',
  'astrology',
  'festivals',
  'devotion',
  'motivation',
];

/// Builds today's Morning Brief: a short personalized bulletin assembled
/// from the freshest catalog items in the user's languages.
List<CatalogItem> buildMorningBrief(
  Catalog catalog,
  List<String> languages, {
  int maxItems = 8,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final picked = <CatalogItem>[];
  final seen = <String>{};

  for (final interest in _briefOrder) {
    final candidates = catalog.items
        .where((it) =>
            it.reachable &&
            languages.contains(it.language) &&
            it.interests.contains(interest) &&
            !seen.contains(it.id))
        .toList()
      ..sort((a, b) {
        // Daily/dated content first, then most recent, then popular.
        final dailyCmp = (b.isDaily ? 1 : 0) - (a.isDaily ? 1 : 0);
        if (dailyCmp != 0) return dailyCmp;
        final aDate = a.publishedDate ?? a.date;
        final bDate = b.publishedDate ?? b.date;
        if (aDate != null && bDate != null) {
          final cmp = bDate.compareTo(aDate);
          if (cmp != 0) return cmp;
        }
        return b.popularity.compareTo(a.popularity);
      });
    // Up to 2 per interest so the brief stays varied and short.
    for (final it in candidates.take(2)) {
      picked.add(it);
      seen.add(it.id);
      if (picked.length >= maxItems) return picked;
    }
  }
  // Discard stale daily items from a different day.
  return picked
      .where((it) =>
          it.date == null ||
          it.date!.difference(today).inDays.abs() <= 1)
      .toList();
}

/// Today's Morning Brief queue for the current profile.
final morningBriefProvider = Provider<List<CatalogItem>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const [];
  final profile = ref.watch(profileProvider);
  return buildMorningBrief(catalog, profile.languages);
});

/// Home card: one tap to play today's brief, with the streak flame.
class MorningBriefCard extends ConsumerWidget {
  const MorningBriefCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(morningBriefProvider);
    if (brief.isEmpty) return const SizedBox.shrink();

    final streak = ref.watch(currentStreakProvider);
    final scheme = Theme.of(context).colorScheme;
    final totalMin =
        (brief.fold<int>(0, (sum, it) => sum + it.durationSec) / 60).ceil();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await ref
              .read(radioControllerProvider.notifier)
              .startRadioWithItems(brief);
          if (context.mounted) context.push('/player');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.tertiaryContainer,
                scheme.tertiaryContainer.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.wb_sunny_rounded,
                  size: 40, color: scheme.tertiary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting — Your Brief',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${brief.length} stories · ~$totalMin min'
                      '${streak > 0 ? '  ·  🔥 $streak day streak' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill,
                  size: 40, color: scheme.tertiary),
            ],
          ),
        ),
      ),
    );
  }
}
