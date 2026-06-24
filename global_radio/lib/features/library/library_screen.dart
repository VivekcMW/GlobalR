import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../data/models/catalog_item.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../../shared/utils/interest_icons.dart';

/// Library: Saved (Favorites), Recently Played, Downloads
/// Now rendered as a flat list with sections, no inner tabs.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final favs = ref.watch(favoritesProvider);
    final recent = ref.watch(recentlyPlayedProvider);
    final controller = ref.read(radioControllerProvider.notifier);

    CatalogItem? lookup(String id) {
      if (catalog == null) return null;
      for (final it in catalog.items) {
        if (it.id == id) return it;
      }
      return null;
    }

    final savedItems = favs.map((s) => lookup(s.itemId)).whereType<CatalogItem>().toList();
    final recentItems = recent.map((s) => lookup(s.itemId)).whereType<CatalogItem>().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Saved (Favorites) Section
          _SectionHeader(
            icon: Icons.bookmark_rounded,
            title: 'Saved',
            count: savedItems.length,
          ),
          if (savedItems.isEmpty)
            _EmptyCard(message: 'Tap ♥ on the player to save favorites.')
          else
            ...savedItems.take(5).map((it) => _ItemCard(
                  item: it,
                  onTap: () async {
                    await controller.startRadio(onlyInterests: it.interests);
                    if (context.mounted) context.push('/player');
                  },
                )),
          if (savedItems.length > 5)
            TextButton(
              onPressed: () {
                // TODO: Navigate to full saved list
              },
              child: Text('See all ${savedItems.length} saved'),
            ),
          const SizedBox(height: 20),

          // Recently Played Section
          _SectionHeader(
            icon: Icons.history,
            title: 'Recently Played',
            count: recentItems.length,
          ),
          if (recentItems.isEmpty)
            _EmptyCard(message: 'Items you play will appear here.')
          else
            ...recentItems.take(5).map((it) => _ItemCard(
                  item: it,
                  onTap: () async {
                    await controller.startRadio(onlyInterests: it.interests);
                    if (context.mounted) context.push('/player');
                  },
                )),
          if (recentItems.length > 5)
            TextButton(
              onPressed: () {
                // TODO: Navigate to full history
              },
              child: Text('See all ${recentItems.length} recent'),
            ),
          const SizedBox(height: 20),

          // Downloads Section
          _SectionHeader(
            icon: Icons.download_done_rounded,
            title: 'Downloads',
            count: 0,
          ),
          _EmptyCard(
            message: 'Downloaded content for offline listening will appear here.',
            icon: Icons.cloud_download_outlined,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData? icon;

  const _EmptyCard({required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: scheme.outline),
              const SizedBox(height: 12),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final CatalogItem item;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final interest = Interest.byId(item.primaryInterest);
    return Card(
      child: ListTile(
        leading: interest != null
            ? InterestIconWidget(
                interestId: interest.id,
                category: interest.category,
                size: 18,
              )
            : const Icon(Icons.headphones_rounded, size: 24),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${Interest.labelFor(item.primaryInterest)} · ${item.durationSec ~/ 60} min',
        ),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
}
