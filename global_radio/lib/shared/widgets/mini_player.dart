import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/constants.dart';
import '../providers/providers.dart';
import '../providers/radio_controller.dart';

/// Bottom persistent mini-player with progress bar, voice badge, and waveform.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radio = ref.watch(radioControllerProvider);
    final current = radio.current;
    if (current == null) return const SizedBox.shrink();

    final controller = ref.read(radioControllerProvider.notifier);
    final profile = ref.watch(profileProvider);
    final audioHandler = ref.watch(audioHandlerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: () => context.push('/player'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar at top (2px)
            StreamBuilder<Duration>(
              stream: audioHandler.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = Duration(seconds: current.durationSec);
                final progress = duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;

                return Container(
                  height: 2,
                  color: scheme.surfaceContainerHighest,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(color: scheme.primary),
                  ),
                );
              },
            ),
            // Main content (62px to keep total at 64px)
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Waveform indicator when playing, interest icon when paused
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: radio.isPlaying
                        ? _WaveformIndicator(color: scheme.primary)
                        : _InterestIcon(interestId: current.primaryInterest),
                  ),
                  const SizedBox(width: 10),
                  // Title only (single line)
                  Expanded(
                    child: Text(
                      current.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Voice badge
                  _VoiceBadge(voiceId: profile.preferredVoice),
                  const SizedBox(width: 4),
                  // Play/pause button with loading indicator
                  StreamBuilder<ProcessingState>(
                    stream: audioHandler.processingStateStream,
                    builder: (context, snapshot) {
                      final processingState = snapshot.data ?? ProcessingState.idle;
                      final isLoading = processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering;
                      
                      if (isLoading) {
                        return const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      
                      return IconButton(
                        iconSize: 32,
                        icon: Icon(radio.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled),
                        color: scheme.primary,
                        onPressed: controller.togglePlayPause,
                      );
                    },
                  ),
                  // Skip next button
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: controller.skipNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interest icon for paused state.
class _InterestIcon extends StatelessWidget {
  final String interestId;

  const _InterestIcon({required this.interestId});

  @override
  Widget build(BuildContext context) {
    final interest = Interest.byId(interestId);
    final scheme = Theme.of(context).colorScheme;

    if (interest == null) {
      return CircleAvatar(
        backgroundColor: scheme.primary.withValues(alpha: 0.18),
        child: const Icon(Icons.headphones_rounded, size: 18),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          _iconForCategory(interest.category),
          size: 20,
          color: scheme.primary,
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    return switch (category) {
      'stories' => Icons.auto_stories,
      'spiritual' => Icons.self_improvement,
      'knowledge' => Icons.school,
      'entertainment' => Icons.music_note,
      'lifestyle' => Icons.favorite,
      'news' => Icons.article,
      'culture' => Icons.temple_hindu,
      _ => Icons.headphones,
    };
  }
}

/// Compact voice badge.
class _VoiceBadge extends StatelessWidget {
  final String voiceId;

  const _VoiceBadge({required this.voiceId});

  @override
  Widget build(BuildContext context) {
    final voice = VoicePreset.byId(voiceId);
    if (voice == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${voice.icon} ${voice.shortLabel}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

/// Animated 3-bar waveform indicator.
class _WaveformIndicator extends StatefulWidget {
  final Color color;

  const _WaveformIndicator({required this.color});

  @override
  State<_WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<_WaveformIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      ),
    );

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Start animations with staggered delay
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) {
              return Container(
                width: 4,
                height: 20 * _animations[i].value,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
