import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'festival_provider.dart';

/// Festival banner for home screen - shows today's festival.
class FestivalBanner extends ConsumerWidget {
  final VoidCallback? onTap;

  const FestivalBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysFestivals = ref.watch(todaysFestivalsProvider);

    if (todaysFestivals.isEmpty) {
      return const SizedBox.shrink();
    }

    final festival = todaysFestivals.first;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer,
              scheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Festival icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  festival.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Festival info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Happy ${festival.name}!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Play special ${festival.name} content',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Play button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Upcoming festivals card for home screen.
class UpcomingFestivalsCard extends ConsumerWidget {
  const UpcomingFestivalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingFestivalsProvider);

    if (upcoming.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.event, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Festivals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Festival list
          ...upcoming.take(3).map((festival) => _FestivalRow(festival: festival)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FestivalRow extends StatelessWidget {
  final Festival festival;

  const _FestivalRow({required this.festival});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysUntil = festival.daysUntil ?? 0;

    String daysText;
    if (daysUntil == 0) {
      daysText = 'Today';
    } else if (daysUntil == 1) {
      daysText = 'Tomorrow';
    } else {
      daysText = 'In $daysUntil days';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Icon
          Text(festival.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              festival.name,
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface,
              ),
            ),
          ),

          // Days until
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: daysUntil <= 1
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              daysText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: daysUntil <= 1
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact festival chip for inline display.
class FestivalChip extends StatelessWidget {
  final Festival festival;
  final VoidCallback? onTap;

  const FestivalChip({
    super.key,
    required this.festival,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Text(festival.icon),
      label: Text(festival.name),
      backgroundColor: scheme.secondaryContainer,
      labelStyle: TextStyle(color: scheme.onSecondaryContainer),
      onPressed: onTap,
    );
  }
}

/// Full festival calendar screen.
class FestivalCalendarScreen extends ConsumerWidget {
  const FestivalCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(festivalCalendarProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Festival Calendar'),
      ),
      body: calendarAsync.when(
        data: (calendar) {
          final today = calendar.todaysFestivals;
          final upcoming = calendar.upcomingFestivals(30);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Today's festivals
              if (today.isNotEmpty) ...[
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...today.map((f) => _ExpandedFestivalCard(festival: f)),
                const SizedBox(height: 24),
              ],

              // Upcoming
              if (upcoming.isNotEmpty) ...[
                Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...upcoming.map((f) => _ExpandedFestivalCard(festival: f)),
              ],

              // Empty state
              if (today.isEmpty && upcoming.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No upcoming festivals',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ExpandedFestivalCard extends StatelessWidget {
  final Festival festival;

  const _ExpandedFestivalCard({required this.festival});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysUntil = festival.daysUntil ?? 0;
    final nextDate = festival.nextDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(festival.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    festival.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (nextDate != null)
                    Text(
                      _formatDate(nextDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _TypeChip(type: festival.type),
                      if (daysUntil <= 7)
                        _DaysChip(days: daysUntil),
                    ],
                  ),
                ],
              ),
            ),

            // Play button
            IconButton(
              icon: Icon(Icons.play_circle_fill, color: scheme.primary, size: 36),
              onPressed: () {
                // TODO: Play festival content
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color bgColor;
    String label;

    switch (type) {
      case 'national':
        bgColor = Colors.orange.shade100;
        label = 'National';
        break;
      case 'religious':
        bgColor = Colors.purple.shade100;
        label = 'Religious';
        break;
      case 'harvest':
        bgColor = Colors.green.shade100;
        label = 'Harvest';
        break;
      case 'new_year':
        bgColor = Colors.blue.shade100;
        label = 'New Year';
        break;
      default:
        bgColor = scheme.surfaceContainerHighest;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  final int days;

  const _DaysChip({required this.days});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String label;
    if (days == 0) {
      label = 'Today!';
    } else if (days == 1) {
      label = 'Tomorrow';
    } else {
      label = '$days days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: days == 0 ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: days == 0 ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
