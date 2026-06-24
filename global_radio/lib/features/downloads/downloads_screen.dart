import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';
import 'download_manager.dart';
import 'download_provider.dart';
import 'download_repository.dart';

/// Screen showing downloaded content and download queue.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadsProvider);
    final controller = ref.read(downloadsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (state.downloaded.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete all downloads',
              onPressed: () => _confirmDeleteAll(context, controller),
            ),
        ],
      ),
      body: state.downloaded.isEmpty && state.queue.isEmpty
          ? _buildEmptyState(context, controller)
          : _buildContent(context, ref, state, controller),
    );
  }

  Widget _buildEmptyState(BuildContext context, DownloadsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No downloads yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Download content to listen offline.\nGreat for saving mobile data!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => controller.autoDownloadNext(count: 10),
              icon: const Icon(Icons.download),
              label: const Text('Download recommended'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DownloadsState state,
    DownloadsController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Settings card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage_outlined),
                    const SizedBox(width: 12),
                    Text(
                      'Storage used: ${state.formattedSize}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('WiFi only'),
                  subtitle: const Text('Download only when connected to WiFi'),
                  value: state.wifiOnly,
                  onChanged: controller.setWifiOnly,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Auto-download'),
                  subtitle: const Text('Automatically download next items'),
                  value: state.autoDownload,
                  onChanged: controller.setAutoDownload,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),

        // Download queue
        if (state.queue.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Downloading',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.cancelAll,
                child: const Text('Cancel all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.queue.map((task) => _DownloadTaskTile(
                task: task,
                onCancel: () => controller.cancel(task.item.id, task.voice),
              )),
        ],

        // Downloaded items
        if (state.downloaded.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Downloaded (${state.downloaded.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...state.downloaded.map((item) => _DownloadedItemTile(
                item: item,
                catalog: ref.read(catalogProvider).valueOrNull,
                onDelete: () => controller.delete(item.itemId, item.voice),
              )),
        ],
      ],
    );
  }

  void _confirmDeleteAll(BuildContext context, DownloadsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all downloads?'),
        content: const Text(
          'This will remove all downloaded content from your device. '
          'You can download them again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.deleteAll();
              Navigator.pop(ctx);
            },
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
  }
}

class _DownloadTaskTile extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onCancel;

  const _DownloadTaskTile({required this.task, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _buildLeading(context),
        title: Text(task.item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: _buildSubtitle(context),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onCancel,
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    switch (task.status) {
      case DownloadStatus.pending:
        return const Icon(Icons.schedule);
      case DownloadStatus.downloading:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: task.progress > 0 ? task.progress : null,
            strokeWidth: 2,
          ),
        );
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel);
    }
  }

  Widget? _buildSubtitle(BuildContext context) {
    switch (task.status) {
      case DownloadStatus.pending:
        return const Text('Waiting...');
      case DownloadStatus.downloading:
        return LinearProgressIndicator(value: task.progress);
      case DownloadStatus.failed:
        return Text(task.error ?? 'Download failed',
            style: const TextStyle(color: Colors.red));
      default:
        return null;
    }
  }
}

class _DownloadedItemTile extends StatelessWidget {
  final DownloadedItem item;
  final dynamic catalog;
  final VoidCallback onDelete;

  const _DownloadedItemTile({
    required this.item,
    required this.catalog,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Try to find the catalog item for more details
    String title = item.itemId;
    if (catalog != null) {
      final catalogItem = catalog.items.firstWhere(
        (it) => it.id == item.itemId,
        orElse: () => null,
      );
      if (catalogItem != null) {
        title = catalogItem.title;
      }
    }

    final size = item.sizeBytes < 1024 * 1024
        ? '${(item.sizeBytes / 1024).toStringAsFixed(0)} KB'
        : '${(item.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.download_done),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$size · ${item.language}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
