import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/catalog_item.dart';
import '../../../shared/providers/providers.dart';

/// Bottom sheet showing the story's text alongside its illustration,
/// windowed to whichever panel matches current playback position.
class StoryReadSheet extends ConsumerWidget {
  final CatalogItem item;
  final ScrollController scrollController;

  const StoryReadSheet(
      {super.key, required this.item, required this.scrollController});

  static Future<void> show(BuildContext context, CatalogItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) =>
            StoryReadSheet(item: item, scrollController: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.read(audioHandlerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (item.hasImage)
                  StreamBuilder<Duration>(
                    stream: audioHandler.positionStream,
                    initialData: audioHandler.position,
                    builder: (context, snapshot) {
                      final index = item.panelIndexFor(snapshot.data ?? Duration.zero);
                      return _StoryPanelWindow(
                        imageUrl: item.imageUrlResolved!,
                        panelCount: item.imagePanelCount,
                        panelIndex: index,
                      );
                    },
                  ),
                const SizedBox(height: 20),
                Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  item.text.isEmpty ? 'No story text available for this item.' : item.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows exactly one panel-width slice of a wider [imageUrl] strip,
/// cross-fading when [panelIndex] changes.
class _StoryPanelWindow extends StatelessWidget {
  final String imageUrl;
  final int panelCount;
  final int panelIndex;

  const _StoryPanelWindow({
    required this.imageUrl,
    required this.panelCount,
    required this.panelIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = constraints.maxWidth;
            return ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  key: ValueKey<int>(panelIndex),
                  width: panelWidth,
                  height: panelWidth,
                  child: OverflowBox(
                    maxWidth: panelWidth * panelCount,
                    minWidth: panelWidth * panelCount,
                    alignment: Alignment(
                      // -1 = leftmost panel, 1 = rightmost panel.
                      panelCount <= 1
                          ? 0
                          : (-1 + 2 * panelIndex / (panelCount - 1)),
                      0,
                    ),
                    child: Image.network(
                      imageUrl,
                      width: panelWidth * panelCount,
                      height: panelWidth,
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
