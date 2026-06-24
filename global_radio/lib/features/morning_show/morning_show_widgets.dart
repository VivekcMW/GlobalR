import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'morning_show_provider.dart';

/// Hero card for the daily show on the home screen.
class DailyShowCard extends ConsumerWidget {
  const DailyShowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(dailyShowProvider);
    final controller = ref.read(dailyShowControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    // Return empty when show is not ready
    if (show == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.playDailyShow(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors(show),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      show.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            show.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            show.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Play button
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 32,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Segments preview
                Row(
                  children: show.segments.map((segment) {
                    return Expanded(
                      child: _SegmentChip(segment: segment),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Duration info
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(show.estimatedDuration),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.playlist_play,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${show.totalItems} items',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _gradientColors(SequencedShow show) {
    if (show.title.contains('Morning')) {
      return [const Color(0xFFFF8C00), const Color(0xFFFFD700)];
    } else if (show.title.contains('Afternoon')) {
      return [const Color(0xFF4FC3F7), const Color(0xFF2196F3)];
    } else if (show.title.contains('Evening')) {
      return [const Color(0xFFFF7043), const Color(0xFFE91E63)];
    } else {
      return [const Color(0xFF3F51B5), const Color(0xFF1A237E)];
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}

class _SegmentChip extends ConsumerWidget {
  final ShowSegment segment;

  const _SegmentChip({required this.segment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(dailyShowControllerProvider);

    return GestureDetector(
      onTap: () => controller.playSegment(segment),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              _interestIcon(segment.interest),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              segment.title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _interestIcon(String interest) {
    switch (interest) {
      case 'devotion':
        return '🪔';
      case 'astrology':
        return '✨';
      case 'news':
        return '📰';
      case 'moral':
        return '📖';
      case 'kids':
        return '🧒';
      default:
        return '🎧';
    }
  }
}

/// Compact version for smaller spaces.
class DailyShowChip extends ConsumerWidget {
  const DailyShowChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(dailyShowProvider);
    final controller = ref.read(dailyShowControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    if (show == null) {
      return const SizedBox.shrink();
    }

    return ActionChip(
      avatar: Text(show.icon),
      label: Text(show.title),
      backgroundColor: scheme.primaryContainer,
      onPressed: () => controller.playDailyShow(),
    );
  }
}
