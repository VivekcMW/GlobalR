import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../audio/audio_handler.dart';
import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../core/network/network_error_handler.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../share/share_service.dart';
import 'widgets/diya_disc.dart';
import 'widgets/seek_bar.dart';
import 'widgets/sleep_timer_sheet.dart';
import 'widgets/speed_selector.dart';
import 'widgets/story_read_sheet.dart';
import 'widgets/up_next_sheet.dart';

/// Full-screen player: big art, title, controls, "why this", favorite.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radio = ref.watch(radioControllerProvider);
    final controller = ref.read(radioControllerProvider.notifier);
    final audioHandler = ref.read(audioHandlerProvider);
    final item = radio.current;
    final scheme = Theme.of(context).colorScheme;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nothing playing yet')),
      );
    }

    final interest = Interest.byId(item.primaryInterest);
    final isFav = controller.isFavorite(item.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Now Playing'),
        actions: [
          if (item.text.isNotEmpty || item.hasImage)
            IconButton(
              icon: const Icon(Icons.menu_book_outlined),
              tooltip: 'Read story',
              onPressed: () => StoryReadSheet.show(context),
            ),
          IconButton(
            icon: const Icon(Icons.directions_car_outlined),
            tooltip: 'Car Mode',
            onPressed: () => context.push('/car'),
          ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Up Next',
            onPressed: () => UpNextSheet.show(context),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          // Swipe down to dismiss.
          if ((details.primaryVelocity ?? 0) > 300) {
            Navigator.of(context).maybePop();
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                DiyaDisc(
                  ringHue: DesignTokens.interestHue(item.primaryInterest),
                  isPlaying: radio.isPlaying,
                  motifSeed: interest?.category ?? item.primaryInterest,
                  size: 240,
                ),
                const SizedBox(height: 28),
                Text(item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '${interest?.label ?? item.primaryInterest} · ${AppLanguage.nativeNameFor(item.language)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _WhyThisChip(isDaily: item.isDaily),
                    const SizedBox(width: 8),
                    const _DataBadge(),
                  ],
                ),
                const Spacer(),

                // Seek bar with position/duration
                SeekBar(audioHandler: audioHandler),
                const SizedBox(height: 4),

                // Speed control
                StreamBuilder<double>(
                  stream: audioHandler.speedStream,
                  initialData: audioHandler.speed,
                  builder: (context, snapshot) {
                    final speed = snapshot.data ?? 1.0;
                    return SpeedButton(
                      speed: speed,
                      onTap: () => _showSpeedSheet(context, speed, audioHandler),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Transport controls
                StreamBuilder<ProcessingState>(
                  stream: audioHandler.processingStateStream,
                  builder: (context, snapshot) {
                    final processing = snapshot.data ?? ProcessingState.idle;
                    final isLoading = processing == ProcessingState.loading ||
                        processing == ProcessingState.buffering;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.skip_previous),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            controller.skipPrevious();
                          },
                        ),
                        IconButton(
                          iconSize: 30,
                          icon: const Icon(Icons.replay_10),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            audioHandler.seekBy(const Duration(seconds: -10));
                          },
                        ),
                        isLoading
                            ? const SizedBox(
                                width: 76,
                                height: 76,
                                child: Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 3),
                                ),
                              )
                            : IconButton(
                                iconSize: 76,
                                color: scheme.primary,
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  controller.togglePlayPause();
                                },
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                          scale: anim, child: child),
                                  child: Icon(
                                    radio.isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    key: ValueKey<bool>(radio.isPlaying),
                                    size: 76,
                                  ),
                                ),
                              ),
                        IconButton(
                          iconSize: 30,
                          icon: const Icon(Icons.forward_10),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            audioHandler.seekBy(const Duration(seconds: 10));
                          },
                        ),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.skip_next),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            controller.skipNext();
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      tooltip: isFav ? 'Favorited' : 'Favorite',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        controller.toggleFavorite(item.id);
                      },
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                    ),
                    IconButton(
                      tooltip: 'Share this moment',
                      onPressed: () => ShareService()
                          .shareItem(item, at: audioHandler.position),
                      icon: const Icon(Icons.share_outlined),
                    ),
                    const SleepTimerButton(),
                    IconButton(
                      tooltip: 'Source',
                      onPressed: () => _showAttribution(context, item.attribution),
                      icon: const Icon(Icons.info_outline),
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

  void _showAttribution(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attribution',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(text.isEmpty ? 'No attribution recorded.' : text),
          ],
        ),
      ),
    );
  }

  void _showSpeedSheet(BuildContext context, double currentSpeed,
      GlobalRadioAudioHandler audioHandler) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SpeedSelectorSheet(
        currentSpeed: currentSpeed,
        onSpeedSelected: (speed) => audioHandler.setSpeed(speed),
      ),
    );
  }
}

class _WhyThisChip extends StatelessWidget {
  final bool isDaily;
  const _WhyThisChip({required this.isDaily});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.auto_awesome, size: 16),
      label: Text(isDaily ? "Today's pick for you" : 'Matches your interests'),
    );
  }
}

/// Data-frugality badge: approximate hourly data use, or offline state.
class _DataBadge extends ConsumerWidget {
  const _DataBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final lowData = ref.watch(profileProvider).lowDataMode;
    final scheme = Theme.of(context).colorScheme;

    final (icon, label) = !isOnline
        ? (Icons.cloud_off_rounded, 'Offline · saved audio')
        // 48 kbps ≈ 21 MB/hr (low-data), 64 kbps ≈ 28 MB/hr.
        : lowData
            ? (Icons.data_saver_on_rounded, '~21 MB/hr')
            : (Icons.network_cell_rounded, '~28 MB/hr');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
