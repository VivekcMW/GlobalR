import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../../shared/utils/interest_icons.dart';
import 'today_provider.dart';

/// Today tab: daily habit driver with astrology, festivals, streaks.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(todayContentProvider);
    final profile = ref.watch(profileProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible header with greeting
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(content.dateFormatted),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                    child: Row(
                      children: [
                        Icon(Icons.wb_sunny_rounded,
                            size: 28, color: scheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          '${content.greeting}${profile.name != null ? ", ${profile.name}" : ""}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Streak banner (if active)
                if (content.hasStreak) ...[
                  _StreakBanner(
                    streak: content.currentStreak,
                    hasListenedToday: content.hasListenedToday,
                  ),
                  const SizedBox(height: 16),
                ],

                // Zodiac selector
                Text('Your Rashi',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const _ZodiacSelector(),
                const SizedBox(height: 16),

                // Today's Astrology Card (main feature)
                const _AstrologyCard(),
                const SizedBox(height: 20),

                // Morning Show Card (if available)
                if (content.hasMorningShow) ...[
                  _MorningShowCard(show: content.morningShow!),
                  const SizedBox(height: 20),
                ],

                // Festival Card (if any today)
                if (content.hasFestivals) ...[
                  _FestivalCard(festivals: content.todaysFestivals),
                  const SizedBox(height: 20),
                ],

                // Daily stories
                if (content.dailyStories.isNotEmpty) ...[
                  Text("Today's Stories",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...content.dailyStories.map(
                    (item) => _DailyItemCard(item: item),
                  ),
                ],

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Streak banner widget.
class _StreakBanner extends StatelessWidget {
  final int streak;
  final bool hasListenedToday;

  const _StreakBanner({required this.streak, required this.hasListenedToday});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasListenedToday
              ? [Colors.orange.shade400, Colors.deepOrange.shade400]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('🔥', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak day streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (!hasListenedToday)
                  Text(
                    'Listen today to keep it going!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
              ],
            ),
          ),
          if (hasListenedToday)
            Icon(Icons.check_circle, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}

/// Zodiac sign selector.
class _ZodiacSelector extends ConsumerWidget {
  const _ZodiacSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSign = ref.watch(selectedSignProvider);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: zodiacSigns.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sign = zodiacSigns[index];
          final isSelected = selectedSign?.id == sign.id;

          return GestureDetector(
            onTap: () =>
                ref.read(selectedSignProvider.notifier).state = sign,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: scheme.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(sign.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 2),
                  Text(
                    sign.name.substring(0, 3),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? scheme.primary : null,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Main astrology card.
class _AstrologyCard extends ConsumerWidget {
  const _AstrologyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astrology = ref.watch(signAstrologyProvider);
    final selectedSign = ref.watch(selectedSignProvider);
    final controller = ref.read(radioControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    if (astrology == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.auto_awesome,
                  size: 48, color: scheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                selectedSign != null
                    ? "No astrology content for ${selectedSign.name} today"
                    : "Select your zodiac sign above",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await controller.startRadio(onlyInterests: astrology.interests);
          if (context.mounted) context.push('/player');
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade400,
                Colors.indigo.shade600,
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(selectedSign?.icon ?? '✨',
                      style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's ${selectedSign?.name ?? 'Daily'} Forecast",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          astrology.title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 16, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(
                    '${astrology.durationSec ~/ 60} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow,
                            size: 20, color: Colors.deepPurple.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Listen Now',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.deepPurple.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Morning show card.
class _MorningShowCard extends ConsumerWidget {
  final SequencedShow show;

  const _MorningShowCard({required this.show});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(show.icon, style: TextStyle(fontSize: 24))),
        ),
        title: Text(show.title),
        subtitle: Text(
            '${show.segments.length} segments · ${show.estimatedDuration.inMinutes} min'),
        trailing: Icon(Icons.play_circle_outline, size: 32),
        onTap: () {
          // Play morning show
          context.push('/player');
        },
      ),
    );
  }
}

/// Festival card.
class _FestivalCard extends StatelessWidget {
  final List<Festival> festivals;

  const _FestivalCard({required this.festivals});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🎉', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  "Today's Festival",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...festivals.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(f.icon, style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        f.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Daily item card.
class _DailyItemCard extends ConsumerWidget {
  final dynamic item;

  const _DailyItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(radioControllerProvider.notifier);
    final interest = Interest.byId(item.primaryInterest);

    return Card(
      child: ListTile(
        leading: interest != null
            ? InterestIconWidget(
                interestId: interest.id,
                category: interest.category,
                size: 18,
              )
            : const Icon(Icons.headphones_rounded),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle:
            Text('${Interest.labelFor(item.primaryInterest)} · ${item.durationSec ~/ 60} min'),
        trailing: const Icon(Icons.play_circle_outline),
        onTap: () async {
          await controller.startRadio(onlyInterests: item.interests);
          if (context.mounted) context.push('/player');
        },
      ),
    );
  }
}
