import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../shared/providers/radio_controller.dart';
import '../../../shared/utils/interest_icons.dart';

/// "Up Next" bottom sheet: shows the radio queue, highlights the current
/// item, and lets the user jump to any track.
class UpNextSheet extends ConsumerWidget {
  const UpNextSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const UpNextSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radio = ref.watch(radioControllerProvider);
    final controller = ref.read(radioControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text('Up Next',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: radio.queue.isEmpty
                ? const Center(child: Text('Queue is empty'))
                : ListView.builder(
                    itemCount: radio.queue.length,
                    itemBuilder: (context, index) {
                      final item = radio.queue[index];
                      final interest = Interest.byId(item.primaryInterest);
                      final isCurrent = index == radio.currentIndex;
                      final isPast = index < radio.currentIndex;

                      return ListTile(
                        selected: isCurrent,
                        selectedTileColor:
                            scheme.primary.withValues(alpha: 0.08),
                        leading: CircleAvatar(
                          backgroundColor: isCurrent
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          child: isCurrent
                              ? Icon(Icons.graphic_eq,
                                  size: 20, color: scheme.onPrimary)
                              : Icon(
                                  interest != null
                                      ? interestIcon(interest.id)
                                      : Icons.headphones_rounded,
                                  size: 20,
                                  color: isPast
                                      ? scheme.onSurfaceVariant
                                          .withValues(alpha: 0.5)
                                      : scheme.onSurfaceVariant,
                                ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w600 : null,
                            color: isPast
                                ? scheme.onSurface.withValues(alpha: 0.45)
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${interest?.label ?? item.primaryInterest} · '
                          '${_formatDuration(item.durationSec)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: isCurrent
                            ? Text('Now',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: scheme.primary))
                            : null,
                        onTap: isCurrent
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                controller.playAt(index);
                                Navigator.of(context).pop();
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
