import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/radio_controller.dart';
import '../voice_search/voice_search_widgets.dart';

/// Car Mode: high-contrast, oversized controls for driving.
/// Voice-first — the mic button opens the existing voice search sheet.
class CarModeScreen extends ConsumerWidget {
  const CarModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radio = ref.watch(radioControllerProvider);
    final controller = ref.read(radioControllerProvider.notifier);
    final item = radio.current;

    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            iconSize: 36,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Car Mode'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  item?.title ?? 'Nothing playing',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BigButton(
                      icon: Icons.skip_previous,
                      size: 72,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        controller.skipPrevious();
                      },
                    ),
                    _BigButton(
                      icon: radio.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 140,
                      color: Colors.amber,
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        controller.togglePlayPause();
                      },
                    ),
                    _BigButton(
                      icon: Icons.skip_next,
                      size: 72,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        controller.skipNext();
                      },
                    ),
                  ],
                ),
                const Spacer(),
                // Voice-first entry: "Play Tamil news", "next", "pause"...
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.mic, size: 32),
                    label: const Text('Voice command',
                        style: TextStyle(fontSize: 20)),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const VoiceSearchSheet(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: size,
      color: color,
      icon: Icon(icon),
      onPressed: onTap,
    );
  }
}
