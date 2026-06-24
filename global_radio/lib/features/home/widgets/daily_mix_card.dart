import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../radio_engine/daily_mix_generator.dart';
import '../../../shared/providers/radio_controller.dart';
import '../providers/daily_mix_provider.dart';

/// Card showing the personalized daily mix on the home screen.
class DailyMixCard extends ConsumerWidget {
  const DailyMixCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = ref.watch(dailyMixProvider);
    final controller = ref.read(radioControllerProvider.notifier);

    if (mix == null || mix.isEmpty) {
      return const SizedBox.shrink();
    }

    return _MixCard(
      mix: mix,
      icon: Icons.auto_awesome,
      gradient: [
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
      ],
      onPlay: () async {
        // Start playing the mix
        await controller.startRadio();
        if (context.mounted) context.push('/player');
      },
    );
  }
}

/// Card showing the favorites mix.
class FavoritesMixCard extends ConsumerWidget {
  const FavoritesMixCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = ref.watch(favoritesMixProvider);
    final controller = ref.read(radioControllerProvider.notifier);

    if (mix == null || mix.isEmpty) {
      return const SizedBox.shrink();
    }

    return _MixCard(
      mix: mix,
      icon: Icons.favorite,
      gradient: [
        Colors.pink.withValues(alpha: 0.3),
        Colors.red.withValues(alpha: 0.2),
      ],
      onPlay: () async {
        await controller.startRadio();
        if (context.mounted) context.push('/player');
      },
    );
  }
}

/// Reusable mix card widget.
class _MixCard extends StatelessWidget {
  final DailyMix mix;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onPlay;

  const _MixCard({
    required this.mix,
    required this.icon,
    required this.gradient,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPlay,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Mix icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: scheme.primary),
              ),
              const SizedBox(width: 16),

              // Mix info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mix.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mix.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mix.length} items',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                    ),
                  ],
                ),
              ),

              // Play button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: scheme.onPrimary,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrollable list of interest-based mixes.
class InterestMixesRow extends ConsumerWidget {
  const InterestMixesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ['kids', 'moral', 'devotion', 'astrology'];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: interests.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final interest = interests[index];
          final mix = ref.watch(interestMixProvider(interest));

          if (mix == null || mix.isEmpty) {
            return const SizedBox.shrink();
          }

          return _SmallMixCard(
            mix: mix,
            interest: interest,
          );
        },
      ),
    );
  }
}

class _SmallMixCard extends ConsumerWidget {
  final DailyMix mix;
  final String interest;

  const _SmallMixCard({required this.mix, required this.interest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(radioControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final (icon, color) = _interestStyle(interest);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await controller.startRadio(onlyInterests: [interest]);
          if (context.mounted) context.push('/player');
        },
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                mix.name,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${mix.length} items',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _interestStyle(String interest) {
    switch (interest) {
      case 'kids':
        return ('🧒', Colors.orange);
      case 'moral':
        return ('📖', Colors.blue);
      case 'devotion':
        return ('🪔', Colors.amber);
      case 'astrology':
        return ('✨', Colors.purple);
      default:
        return ('🎧', Colors.grey);
    }
  }
}
