import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../core/network/network_error_handler.dart';
import '../../shared/providers/daypart_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../../shared/utils/interest_icons.dart';
import '../engagement/milestones.dart';
import '../festivals/festival_live_card.dart';
import '../kids_mode/kids_mode_provider.dart';
import '../morning_brief/morning_brief.dart';
import '../sponsored/sponsored_station.dart';
import '../voice_search/voice_search_widgets.dart';
import '../voting/listeners_choice_card.dart';
import 'widgets/continue_listening_card.dart';

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
    final kidsMode = ref.watch(kidsModeProvider);

    // Milestone celebration: confetti sheet when a streak threshold is
    // crossed during playback.
    ref.listen<int?>(pendingMilestoneProvider, (_, days) {
      if (days == null) return;
      ref.read(pendingMilestoneProvider.notifier).state = null;
      showMilestoneCelebration(context, ref, days);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name == null ? 'Global Radio' : 'Namaste, ${profile.name}'),
        actions: const [
          // "Ask the Radio": voice-first search & control.
          VoiceSearchIconButton(),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load catalog: $e')),
        data: (catalog) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Offline is a state, not an error — calm saffron banner.
              if (!ref.watch(isOnlineProvider))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Offline — playing your saved stories',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (kidsMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(
                    avatar: const Icon(Icons.child_care, size: 18),
                    label: const Text('Kids Mode on — kid-safe stations only'),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              // Festival live room (festival days only)
              const FestivalLiveCard(),
              // Hero: Now Playing or "tune the dial" daypart CTA
              if (radio.current != null)
                _NowPlayingHero(
                  title: radio.current!.title,
                  isPlaying: radio.isPlaying,
                  daypart: ref.watch(currentDaypartProvider),
                  onResume: controller.togglePlayPause,
                  onTap: () => context.push('/player'),
                )
              else
                _PlayRadioCard(
                  daypart: ref.watch(currentDaypartProvider),
                  onPlay: () async {
                    await controller.startRadio();
                    if (context.mounted) context.push('/player');
                  },
                ),
              const SizedBox(height: 12),
              const MorningBriefCard(),
              const ContinueListeningCard(),
              const SizedBox(height: 12),

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
              const SizedBox(height: 12),
              const ListenersChoiceCard(),
              const SponsoredStationCard(),
            ],
          );
        },
      ),
    );
  }
}

class _PlayRadioCard extends StatelessWidget {
  final VoidCallback onPlay;
  final Daypart daypart;
  const _PlayRadioCard({required this.onPlay, required this.daypart});

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
            colors: [
              daypart.gradientTop.withValues(alpha: 0.9),
              daypart.accent.withValues(alpha: 0.35),
            ],
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
                  Row(
                    children: [
                      Icon(daypart.icon, size: 18, color: daypart.accent),
                      const SizedBox(width: 6),
                      Text(
                        '${daypart.labelNative} · ${daypart.labelEn}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: daypart.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Your radio is ready',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(daypart.heroLineEn,
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
  final Daypart daypart;
  final VoidCallback onResume;
  final VoidCallback onTap;

  const _NowPlayingHero({
    required this.title,
    required this.isPlaying,
    required this.daypart,
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
              daypart.gradientTop.withValues(alpha: 0.9),
              daypart.accent.withValues(alpha: 0.35),
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
                  Row(
                    children: [
                      Icon(daypart.icon, size: 14, color: daypart.accent),
                      const SizedBox(width: 4),
                      Text(
                        isPlaying
                            ? 'Now Playing · ${daypart.labelNative}'
                            : 'Paused · ${daypart.labelNative}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: daypart.accent),
                      ),
                    ],
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
