/// Today-screen engagement cards: serialized journeys, the daily mystery
/// story, the weekly goal ring and the "you asked, we made it" voting-loop
/// closer. All watch their own providers, render nothing when inactive, and
/// respect Kids Mode / Remote Config gates enforced upstream.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics_events.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../voting/voting_widgets.dart';
import 'journeys.dart';
import 'mystery_slot.dart';
import 'voting_winner.dart';
import 'weekly_goal.dart';

void _logEvent(WidgetRef ref, AnalyticsEvent event) {
  ref.read(analyticsServiceProvider).logEvent(event).catchError((_) {});
}

/// Serialized journey: "Episode N of M" with a daily unlock.
class JourneyCard extends ConsumerWidget {
  const JourneyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeJourneyProvider);
    if (state == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: state.unlockedToday
            ? () async {
                _logEvent(
                    ref,
                    JourneyEvent(
                      journeyId: state.journey.id,
                      action: state.progress.episodesDone == 0
                          ? 'started'
                          : 'episode_played',
                      episode: state.nextEpisodeNumber,
                    ));
                await advanceJourney(ref.read(localStoreProvider),
                    state.journey.id, state.progress);
                ref.invalidate(activeJourneyProvider);
                await ref
                    .read(radioControllerProvider.notifier)
                    .startRadioWithItems([state.nextItem]);
                if (context.mounted) context.push('/player');
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(state.journey.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.journey.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      state.unlockedToday
                          ? 'Episode ${state.nextEpisodeNumber} of ${state.totalEpisodes} — ${state.nextItem.title}'
                          : 'Episode ${state.nextEpisodeNumber} unlocks tomorrow',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value:
                            state.progress.episodesDone / state.totalEpisodes,
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                state.unlockedToday
                    ? Icons.play_circle_fill
                    : Icons.lock_clock,
                size: 34,
                color: state.unlockedToday
                    ? scheme.primary
                    : scheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily mystery story: hidden until tapped, same pick for everyone today.
class MysteryCard extends ConsumerWidget {
  const MysteryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mysteryItemProvider);
    if (item == null) return const SizedBox.shrink();
    final revealed = ref.watch(mysteryRevealedProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (!revealed) {
            _logEvent(ref, MysteryRevealEvent(itemId: item.id));
            await ref.read(mysteryRevealedProvider.notifier).reveal();
            return;
          }
          await ref
              .read(radioControllerProvider.notifier)
              .startRadioWithItems([item]);
          if (context.mounted) context.push('/player');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.tertiaryContainer,
                scheme.tertiaryContainer.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Text(revealed ? '🎁' : '❓',
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      revealed ? item.title : "Today's Mystery Story",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      revealed
                          ? 'Tap to listen'
                          : 'Everyone gets the same surprise. Tap to reveal!',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(revealed ? Icons.play_circle_fill : Icons.visibility,
                  size: 30, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weekly goal: listen N of 7 days.
class WeeklyGoalCard extends ConsumerWidget {
  const WeeklyGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(weeklyGoalProvider);
    if (goal.goalDays <= 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: goal.progress,
                    strokeWidth: 5,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                  Center(
                    child: Text(
                      goal.met ? '✓' : '${goal.daysListened}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.met ? 'Weekly goal met!' : 'Weekly goal',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    goal.met
                        ? '${goal.daysListened} of 7 days — shabash!'
                        : 'Listen on ${goal.goalDays} of 7 days · ${goal.daysListened} done',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
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

/// "You asked, we made it" — publicly close the voting loop.
class VotingWinnerCard extends ConsumerWidget {
  const VotingWinnerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winner = ref.watch(votingWinnerProvider);
    if (winner == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (_) => const ContentRequestsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🗳️', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You asked, we made it',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      '"${winner.title}" — chosen by ${winner.votes} listeners. Vote for what\'s next!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
