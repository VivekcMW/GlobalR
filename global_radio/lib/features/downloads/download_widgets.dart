import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pack_downloader.dart';

/// Featured download packs card for home screen.
class FeaturedPacksCard extends ConsumerWidget {
  const FeaturedPacksCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredPacks = ref.watch(featuredPacksProvider);
    final scheme = Theme.of(context).colorScheme;

    if (featuredPacks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Download for Offline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DownloadPacksScreen(),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: featuredPacks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PackCard(pack: featuredPacks[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PackCard extends ConsumerWidget {
  final DownloadPack pack;

  const _PackCard({required this.pack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded = ref.watch(isPackDownloadedProvider(pack.id));
    final activeDownloads = ref.watch(activeDownloadsProvider);
    final downloadProgress = activeDownloads[pack.id];
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Navigate to pack details or start download
            if (!isDownloaded && downloadProgress == null) {
              ref.read(activeDownloadsProvider.notifier).startDownload(pack);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(pack.icon, style: const TextStyle(fontSize: 32)),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pack.itemCount} items · ${pack.sizeFormatted}',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),

                      // Status/action
                      _buildStatus(context, isDownloaded, downloadProgress),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(
    BuildContext context,
    bool isDownloaded,
    PackDownloadProgress? progress,
  ) {
    final scheme = Theme.of(context).colorScheme;

    if (isDownloaded) {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'Downloaded',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (progress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: progress.progress,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress.progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.download, size: 16, color: scheme.primary),
        const SizedBox(width: 4),
        Text(
          'Download',
          style: TextStyle(
            fontSize: 11,
            color: scheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Full download packs screen.
class DownloadPacksScreen extends ConsumerWidget {
  const DownloadPacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(downloadPacksProvider);
    final categoriesAsync = ref.watch(packCategoriesProvider);
    final totalSize = ref.watch(totalDownloadedSizeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Packs'),
        actions: [
          if (totalSize > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  label: Text('$totalSize MB'),
                  avatar: const Icon(Icons.storage, size: 16),
                ),
              ),
            ),
        ],
      ),
      body: packsAsync.when(
        data: (packs) {
          return categoriesAsync.when(
            data: (categories) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Featured section
                  _SectionHeader(title: 'Featured'),
                  const SizedBox(height: 8),
                  ...packs.where((p) => p.featured).map(
                        (p) => _ExpandedPackCard(pack: p),
                      ),

                  const SizedBox(height: 24),

                  // By category
                  ...categories.expand((category) {
                    final categoryPacks = packs
                        .where((p) => p.category == category.id)
                        .toList();
                    if (categoryPacks.isEmpty) return <Widget>[];
                    return [
                      _SectionHeader(
                        title: '${category.icon} ${category.name}',
                      ),
                      const SizedBox(height: 8),
                      ...categoryPacks.map((p) => _ExpandedPackCard(pack: p)),
                      const SizedBox(height: 24),
                    ];
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _ExpandedPackCard extends ConsumerWidget {
  final DownloadPack pack;

  const _ExpandedPackCard({required this.pack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded = ref.watch(isPackDownloadedProvider(pack.id));
    final activeDownloads = ref.watch(activeDownloadsProvider);
    final downloadProgress = activeDownloads[pack.id];
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(pack.icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pack.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.audiotrack,
                        text: '${pack.itemCount} items',
                      ),
                      _InfoChip(
                        icon: Icons.timer,
                        text: pack.durationFormatted,
                      ),
                      _InfoChip(
                        icon: Icons.storage,
                        text: pack.sizeFormatted,
                      ),
                    ],
                  ),

                  // Progress bar if downloading
                  if (downloadProgress != null &&
                      downloadProgress.status == PackDownloadStatus.downloading)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: downloadProgress.progress,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Downloading ${(downloadProgress.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Action button
            const SizedBox(width: 8),
            _buildActionButton(context, ref, isDownloaded, downloadProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    bool isDownloaded,
    PackDownloadProgress? progress,
  ) {
    final scheme = Theme.of(context).colorScheme;

    if (isDownloaded) {
      return PopupMenuButton(
        icon: Icon(Icons.check_circle, color: Colors.green),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'play',
            child: Text('Play'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
        onSelected: (value) async {
          if (value == 'delete') {
            final service = ref.read(packDownloaderServiceProvider);
            await service.deletePack(pack.id);
          }
        },
      );
    }

    if (progress != null) {
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(activeDownloadsProvider.notifier).cancelDownload(pack.id);
        },
      );
    }

    return IconButton(
      icon: Icon(Icons.download, color: scheme.primary),
      onPressed: () {
        ref.read(activeDownloadsProvider.notifier).startDownload(pack);
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Manage downloads screen.
class ManageDownloadsScreen extends ConsumerWidget {
  const ManageDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(downloadPacksProvider);
    final downloadedIds = ref.watch(downloadedPackIdsProvider);
    final totalSize = ref.watch(totalDownloadedSizeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Downloads'),
      ),
      body: Column(
        children: [
          // Storage info
          Container(
            padding: const EdgeInsets.all(16),
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.storage, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalSize MB used',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${downloadedIds.length} packs downloaded',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (downloadedIds.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete All?'),
                          content: const Text(
                            'This will remove all downloaded packs.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        final service = ref.read(packDownloaderServiceProvider);
                        for (final id in downloadedIds) {
                          await service.deletePack(id);
                        }
                      }
                    },
                    child: const Text('Delete All'),
                  ),
              ],
            ),
          ),

          // Downloaded packs list
          Expanded(
            child: packsAsync.when(
              data: (allPacks) {
                final downloaded =
                    allPacks.where((p) => downloadedIds.contains(p.id)).toList();

                if (downloaded.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_for_offline_outlined,
                          size: 64,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No downloaded packs',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: downloaded.length,
                  itemBuilder: (context, index) {
                    return _ExpandedPackCard(pack: downloaded[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
