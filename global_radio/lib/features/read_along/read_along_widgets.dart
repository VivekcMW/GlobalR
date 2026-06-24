import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'read_along_provider.dart';

/// Full-screen read-along view with synchronized text.
class ReadAlongScreen extends ConsumerStatefulWidget {
  const ReadAlongScreen({super.key});

  @override
  ConsumerState<ReadAlongScreen> createState() => _ReadAlongScreenState();
}

class _ReadAlongScreenState extends ConsumerState<ReadAlongScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _lastHighlightedIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transcriptAsync = ref.watch(currentTranscriptProvider);
    final settings = ref.watch(readAlongSettingsProvider);
    final currentIndex = ref.watch(currentSegmentIndexProvider);
    final scheme = Theme.of(context).colorScheme;

    // Auto-scroll when segment changes
    if (settings.autoScroll &&
        currentIndex != null &&
        currentIndex != _lastHighlightedIndex) {
      _lastHighlightedIndex = currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSegment(currentIndex);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Read Along'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () =>
                ref.read(readAlongSettingsProvider.notifier).decreaseFontSize(),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () =>
                ref.read(readAlongSettingsProvider.notifier).increaseFontSize(),
          ),
          PopupMenuButton<HighlightMode>(
            icon: const Icon(Icons.highlight),
            onSelected: (mode) => ref
                .read(readAlongSettingsProvider.notifier)
                .setHighlightMode(mode),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: HighlightMode.word,
                child: Text('Highlight word'),
              ),
              const PopupMenuItem(
                value: HighlightMode.sentence,
                child: Text('Highlight sentence'),
              ),
              const PopupMenuItem(
                value: HighlightMode.karaoke,
                child: Text('Karaoke style'),
              ),
            ],
          ),
        ],
      ),
      body: transcriptAsync.when(
        data: (transcript) {
          if (transcript == null) {
            return const Center(
              child: Text('No transcript available for this content'),
            );
          }

          return Column(
            children: [
              // Progress bar
              if (settings.showProgress)
                LinearProgressIndicator(
                  value: ref.watch(transcriptProgressProvider),
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),

              // Text content
              Expanded(
                child: _buildTextContent(
                  transcript,
                  currentIndex,
                  settings,
                ),
              ),

              // Bottom controls
              _buildBottomControls(settings),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTextContent(
    SyncedTranscript transcript,
    int? currentIndex,
    ReadAlongSettings settings,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: transcript.segments.length,
      itemBuilder: (context, index) {
        final segment = transcript.segments[index];
        final isCurrent = index == currentIndex;
        final isPast = currentIndex != null && index < currentIndex;

        Color textColor;
        FontWeight fontWeight;
        double opacity;

        switch (settings.highlightMode) {
          case HighlightMode.word:
            textColor = isCurrent ? scheme.primary : scheme.onSurface;
            fontWeight = isCurrent ? FontWeight.bold : FontWeight.normal;
            opacity = 1.0;
            break;

          case HighlightMode.sentence:
            textColor = isCurrent ? scheme.primary : scheme.onSurface;
            fontWeight = isCurrent ? FontWeight.w500 : FontWeight.normal;
            opacity = 1.0;
            break;

          case HighlightMode.karaoke:
            if (isCurrent) {
              textColor = scheme.primary;
              fontWeight = FontWeight.bold;
              opacity = 1.0;
            } else if (isPast) {
              textColor = scheme.onSurface;
              fontWeight = FontWeight.normal;
              opacity = 0.5;
            } else {
              textColor = scheme.onSurface;
              fontWeight = FontWeight.normal;
              opacity = 0.3;
            }
            break;
        }

        return Padding(
          padding: EdgeInsets.only(
            top: segment.isParagraphStart ? 16 : 4,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: settings.fontSize,
              height: settings.lineSpacing,
              color: textColor.withValues(alpha: opacity),
              fontWeight: fontWeight,
            ),
            child: Text(
              segment.text,
              key: ValueKey('segment_$index'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(ReadAlongSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Auto-scroll toggle
          FilterChip(
            label: const Text('Auto-scroll'),
            selected: settings.autoScroll,
            onSelected: (_) =>
                ref.read(readAlongSettingsProvider.notifier).toggleAutoScroll(),
          ),

          // Progress toggle
          FilterChip(
            label: const Text('Progress'),
            selected: settings.showProgress,
            onSelected: (_) => ref
                .read(readAlongSettingsProvider.notifier)
                .toggleShowProgress(),
          ),
        ],
      ),
    );
  }

  void _scrollToSegment(int index) {
    if (!_scrollController.hasClients) return;

    // Estimate position based on index
    const estimatedItemHeight = 40.0;
    final targetOffset = index * estimatedItemHeight;

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

/// Compact read-along overlay for the player screen.
class ReadAlongOverlay extends ConsumerWidget {
  const ReadAlongOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(isReadAlongAvailableProvider);
    final currentSegment = ref.watch(currentSegmentProvider);
    final settings = ref.watch(readAlongSettingsProvider);
    final scheme = Theme.of(context).colorScheme;

    if (!isAvailable || currentSegment == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        currentSegment.text,
        style: TextStyle(
          fontSize: settings.fontSize,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Button to toggle read-along mode.
class ReadAlongButton extends ConsumerWidget {
  const ReadAlongButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(isReadAlongAvailableProvider);

    if (!isAvailable) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.subtitles),
      tooltip: 'Read Along',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReadAlongScreen()),
        );
      },
    );
  }
}
