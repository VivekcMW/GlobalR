import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../../shared/utils/interest_icons.dart';

/// Home: "Your Stations" (per interest) + Now Playing hero.
/// Daily content moved to separate Today tab.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final catalogAsync = ref.watch(catalogProvider);
    final radio = ref.watch(radioControllerProvider);
    final controller = ref.read(radioControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name == null ? 'Global Radio' : 'Namaste, ${profile.name}'),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load catalog: $e')),
        data: (catalog) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Hero: Now Playing or Play Radio CTA
              if (radio.current != null)
                _NowPlayingHero(
                  title: radio.current!.title,
                  isPlaying: radio.isPlaying,
                  onResume: controller.togglePlayPause,
                  onTap: () => context.push('/player'),
                )
              else
                _PlayRadioCard(onPlay: () async {
                  await controller.startRadio();
                  if (context.mounted) context.push('/player');
                }),
              const SizedBox(height: 24),

              Text('Your Stations',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...profile.interests.map((id) {
                final interest = Interest.byId(id);
                final count = catalog.items
                    .where((it) =>
                        it.interests.contains(id) &&
                        profile.languages.contains(it.language))
                    .length;
                return Card(
                  child: ListTile(
                    leading: interest != null
                        ? InterestIconWidget(
                            interestId: interest.id,
                            category: interest.category,
                            size: 22,
                          )
                        : const Icon(Icons.headphones_rounded, size: 28),
                    title: Text(interest?.label ?? id),
                    subtitle: Text('$count items'),
                    trailing: const Icon(Icons.play_circle_outline),
                    onTap: () async {
                      await controller.startRadio(onlyInterests: [id]);
                      if (context.mounted) context.push('/player');
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _PlayRadioCard extends StatelessWidget {
  final VoidCallback onPlay;
  const _PlayRadioCard({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [scheme.primary.withValues(alpha: 0.35), scheme.secondary.withValues(alpha: 0.35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your radio is ready',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('A continuous mix of your interests',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.play_circle_filled, size: 56, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

/// Hero card showing currently playing track.
class _NowPlayingHero extends StatelessWidget {
  final String title;
  final bool isPlaying;
  final VoidCallback onResume;
  final VoidCallback onTap;

  const _NowPlayingHero({
    required this.title,
    required this.isPlaying,
    required this.onResume,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.3),
              scheme.tertiary.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Animated waveform or static icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPlaying ? Icons.equalizer : Icons.headphones,
                color: scheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlaying ? 'Now Playing' : 'Paused',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              iconSize: 48,
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle_filled,
                color: scheme.primary,
              ),
              onPressed: onResume,
            ),
          ],
        ),
      ),
    );
  }
}
