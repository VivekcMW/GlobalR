import 'package:flutter/material.dart';

/// Available playback speeds.
const List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

/// Bottom sheet for selecting playback speed.
class SpeedSelectorSheet extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;

  const SpeedSelectorSheet({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  @override
  Widget build(BuildContext context) {
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
                  Text('Playback Speed',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...playbackSpeeds.map((speed) => _SpeedTile(
                  speed: speed,
                  isSelected: (speed - currentSpeed).abs() < 0.01,
                  onTap: () {
                    onSpeedSelected(speed);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _SpeedTile extends StatelessWidget {
  final double speed;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeedTile({
    required this.speed,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = speed == 1.0 ? 'Normal' : '${speed}x';

    return ListTile(
      leading: isSelected
          ? Icon(Icons.check_circle, color: scheme.primary)
          : const SizedBox(width: 24),
      title: Text(label),
      selected: isSelected,
      onTap: onTap,
    );
  }
}

/// Compact speed button for the player controls.
class SpeedButton extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const SpeedButton({super.key, required this.speed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = speed == 1.0 ? '1x' : '${speed}x';
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
