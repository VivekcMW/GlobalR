import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/radio_controller.dart';
import '../ad_models.dart';

/// Overlay widget shown during ad playback.
/// Displays "Ad" badge, countdown timer, and skip button.
class AdOverlay extends ConsumerStatefulWidget {
  const AdOverlay({super.key});

  @override
  ConsumerState<AdOverlay> createState() => _AdOverlayState();
}

class _AdOverlayState extends ConsumerState<AdOverlay> {
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    final radioState = ref.read(radioControllerProvider);
    final ad = radioState.currentAd;

    if (ad == null) return;

    // Set initial state
    _secondsRemaining = ad.skipOffset?.inSeconds ?? 5;
    _canSkip = ad.skipPolicy == AdSkipPolicy.alwaysSkippable;

    if (ad.skipPolicy != AdSkipPolicy.nonSkippable) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _secondsRemaining--;
          if (_secondsRemaining <= 0) {
            _canSkip = true;
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void didUpdateWidget(AdOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startCountdown();
  }

  Future<void> _onSkip() async {
    if (!_canSkip) return;

    final controller = ref.read(radioControllerProvider.notifier);
    await controller.skipAd();
  }

  @override
  Widget build(BuildContext context) {
    final radioState = ref.watch(radioControllerProvider);

    // Don't show if not playing an ad
    if (!radioState.isPlayingAd || radioState.currentAd == null) {
      return const SizedBox.shrink();
    }

    final ad = radioState.currentAd!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ad badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.campaign,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AD',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Skip button or countdown
            _buildSkipButton(ad, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton(AdCreative ad, ThemeData theme) {
    // Non-skippable ads show nothing
    if (ad.skipPolicy == AdSkipPolicy.nonSkippable) {
      return const SizedBox.shrink();
    }

    if (_canSkip) {
      // Show skip button
      return FilledButton.icon(
        onPressed: _onSkip,
        icon: const Icon(Icons.skip_next, size: 18),
        label: const Text('Skip Ad'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    } else {
      // Show countdown
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              'Skip in ${_secondsRemaining}s',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// A simpler ad badge widget for compact displays.
class AdBadge extends ConsumerWidget {
  final double size;

  const AdBadge({super.key, this.size = 24});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioState = ref.watch(radioControllerProvider);

    if (!radioState.isPlayingAd) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'AD',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
