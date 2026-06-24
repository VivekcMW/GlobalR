import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/constants.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../../shared/utils/interest_icons.dart';
import 'providers/sleep_timer_provider.dart';
import 'widgets/sleep_timer_sheet.dart';
import 'widgets/speed_selector.dart';

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Waveform-pulse stand-in for cover art.
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.5),
                      scheme.secondary.withValues(alpha: 0.25),
                    ],
                  ),
                ),
                child: Center(
                  child: interest != null
                      ? Icon(
                          interestIcon(interest.id),
                          size: 72,
                          color: interestCategoryColor(interest.category),
                        )
                      : Icon(
                          Icons.headphones_rounded,
                          size: 72,
                          color: scheme.primary,
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Text(item.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '${interest?.label ?? item.primaryInterest} · ${AppLanguage.nativeNameFor(item.language)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _WhyThisChip(item: item, isDaily: item.isDaily),
              const Spacer(),

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

              // Controls
              StreamBuilder<bool>(
                stream: audioHandler.processingStateStream.map((state) => 
                  state == ProcessingState.loading || state == ProcessingState.buffering),
                initialData: false,
                builder: (context, loadingSnapshot) {
                  final isLoading = loadingSnapshot.data ?? false;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_previous),
                        onPressed: isLoading ? null : controller.skipPrevious,
                      ),
                      isLoading
                          ? const SizedBox(
                              width: 80,
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 3),
                              ),
                            )
                          : IconButton(
                              iconSize: 80,
                              color: scheme.primary,
                              icon: Icon(radio.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled),
                              onPressed: controller.togglePlayPause,
                            ),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_next),
                        onPressed: isLoading ? null : controller.skipNext,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => controller.toggleFavorite(item.id),
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                    label: Text(isFav ? 'Favorited' : 'Favorite'),
                  ),
                  const SleepTimerButton(),
                  TextButton.icon(
                    onPressed: () => _showAttribution(context, item.attribution),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Source'),
                  ),
                ],
              ),
            ],
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

  void _showSpeedSheet(
      BuildContext context, double currentSpeed, dynamic audioHandler) {
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
  final dynamic item;
  final bool isDaily;
  const _WhyThisChip({required this.item, required this.isDaily});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.auto_awesome, size: 16),
      label: Text(isDaily ? "Today's pick for you" : 'Matches your interests'),
    );
  }
}
