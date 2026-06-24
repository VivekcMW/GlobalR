import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sleep_timer_provider.dart';

/// Bottom sheet for selecting sleep timer duration.
class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    final controller = ref.read(sleepTimerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.bedtime_outlined),
                  const SizedBox(width: 12),
                  Text('Sleep Timer',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (timer.isActive) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      timer.isFading ? Icons.volume_down : Icons.timer,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timer.isFading
                          ? 'Fading out...'
                          : controller.formatRemaining(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        controller.cancel();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            ...SleepOption.values.map((option) => _SleepOptionTile(
                  option: option,
                  isSelected: timer.option == option,
                  onTap: () {
                    controller.start(option);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _SleepOptionTile extends StatelessWidget {
  final SleepOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _SleepOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: isSelected
          ? Icon(Icons.check_circle, color: scheme.primary)
          : const SizedBox(width: 24),
      title: Text(option.label),
      selected: isSelected,
      onTap: onTap,
    );
  }
}

/// Compact sleep timer button for the player controls.
class SleepTimerButton extends ConsumerWidget {
  const SleepTimerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    final controller = ref.read(sleepTimerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: () => _showSheet(context),
      icon: Icon(
        timer.isActive ? Icons.bedtime : Icons.bedtime_outlined,
        color: timer.isActive ? scheme.primary : null,
      ),
      label: Text(
        timer.isActive ? controller.formatRemaining() : 'Sleep',
        style: TextStyle(
          color: timer.isActive ? scheme.primary : null,
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const SleepTimerSheet(),
    );
  }
}
