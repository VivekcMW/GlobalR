import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'streaks_service.dart';

/// Streak badge for home screen.
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(listeningStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    if (stats.currentStreak == 0 && !stats.hasListenedToday) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '${stats.currentStreak}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Streak card with more details.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(listeningStatsProvider);
    final statusMessage = ref.watch(streakStatusProvider);
    final scheme = Theme.of(context).colorScheme;

    final (hours, minutes) = stats.totalTime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stats.isStreakAtRisk
              ? [Colors.orange.shade600, Colors.red.shade600]
              : [scheme.primaryContainer, scheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Streak fire
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),

              // Streak info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.currentStreak} Day Streak',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: stats.isStreakAtRisk
                            ? Colors.white
                            : scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      statusMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: stats.isStreakAtRisk
                            ? Colors.white70
                            : scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Total Time',
                value: hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                icon: Icons.access_time,
              ),
              _StatItem(
                label: 'Items Played',
                value: '${stats.totalItemsPlayed}',
                icon: Icons.headphones,
              ),
              _StatItem(
                label: 'Best Streak',
                value: '${stats.longestStreak}',
                icon: Icons.emoji_events,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// Weekly insights screen.
class WeeklyInsightsScreen extends ConsumerWidget {
  const WeeklyInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(listeningStatsProvider);
    final weeklyWrap = ref.watch(weeklyWrapProvider);
    final scheme = Theme.of(context).colorScheme;

    final weekMinutes = weeklyWrap['totalMinutes'] as int? ?? 0;
    final weekItems = weeklyWrap['totalItems'] as int? ?? 0;
    final daysListened = weeklyWrap['daysListened'] as int? ?? 0;
    final topCategory = weeklyWrap['topCategory'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Insights'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Streak card
          const StreakCard(),

          const SizedBox(height: 24),

          // Weekly summary
          Text(
            'This Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          _InsightCard(
            icon: Icons.access_time,
            iconColor: Colors.blue,
            title: '${weekMinutes ~/ 60}h ${weekMinutes % 60}m',
            subtitle: 'Time listened this week',
          ),

          _InsightCard(
            icon: Icons.calendar_today,
            iconColor: Colors.green,
            title: '$daysListened of 7 days',
            subtitle: 'Days you listened',
          ),

          _InsightCard(
            icon: Icons.headphones,
            iconColor: Colors.purple,
            title: '$weekItems items',
            subtitle: 'Content pieces enjoyed',
          ),

          if (topCategory != null)
            _InsightCard(
              icon: Icons.favorite,
              iconColor: Colors.red,
              title: topCategory,
              subtitle: 'Your top category',
            ),

          const SizedBox(height: 24),

          // All-time stats
          Text(
            'All Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          _InsightCard(
            icon: Icons.timer,
            iconColor: Colors.orange,
            title:
                '${stats.totalMinutesListened ~/ 60}h ${stats.totalMinutesListened % 60}m',
            subtitle: 'Total listening time',
          ),

          _InsightCard(
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
            title: '${stats.longestStreak} days',
            subtitle: 'Longest streak',
          ),

          // Top categories
          if (stats.topCategories.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Favorite Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.topCategories
                  .map((cat) => Chip(
                        label: Text(cat),
                        backgroundColor: scheme.primaryContainer,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
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

/// Compact streak reminder chip.
class StreakReminderChip extends ConsumerWidget {
  const StreakReminderChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(listeningStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    // Only show if there's a streak at risk
    if (!stats.isStreakAtRisk && stats.currentStreak <= 0) {
      return const SizedBox.shrink();
    }

    if (stats.hasListenedToday) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Could start playing
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Keep your ${stats.currentStreak}-day streak!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
