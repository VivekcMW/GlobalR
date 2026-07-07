import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/providers.dart';
import '../../../shared/providers/radio_controller.dart';

/// "Continue listening" card: resumes the last item where it stopped.
class ContinueListeningCard extends ConsumerWidget {
  const ContinueListeningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumePointProvider);
    final catalog = ref.watch(catalogProvider).value;
    final radio = ref.watch(radioControllerProvider);
    // Hide while something is actively playing.
    if (resume == null || catalog == null || radio.isPlaying) {
      return const SizedBox.shrink();
    }
    final itemIndex =
        catalog.items.indexWhere((it) => it.id == resume.itemId);
    if (itemIndex < 0) return const SizedBox.shrink();
    final item = catalog.items[itemIndex];
    // Don't offer a resume for the item that is already loaded & paused.
    if (radio.current?.id == item.id) return const SizedBox.shrink();

    final mins = resume.position.inMinutes;
    final secs = resume.position.inSeconds % 60;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.restart_alt, size: 28),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            'Continue from $mins:${secs.toString().padLeft(2, '0')}'),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 20),
          tooltip: 'Dismiss',
          onPressed: () =>
              ref.read(radioControllerProvider.notifier).clearResumePoint(),
        ),
        onTap: () async {
          final controller = ref.read(radioControllerProvider.notifier);
          await controller.startRadioWithItems([item]);
          await ref.read(audioHandlerProvider).seek(resume.position);
          await controller.clearResumePoint();
          if (context.mounted) context.push('/player');
        },
      ),
    );
  }
}
