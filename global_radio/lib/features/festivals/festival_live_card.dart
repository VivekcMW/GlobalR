import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../engagement/listener_counts.dart';
import 'festival_provider.dart';

/// Simulated-but-stable "listening now" count for a festival room.
/// Deterministic per festival/hour so it doesn't jump around on rebuilds.
int festivalListenerCount(Festival festival, DateTime now) {
  final seed = festival.id.hashCode ^ (now.day * 24 + now.hour);
  return 1200 + seed.abs() % 4200 + now.hour * 41;
}

/// Home hero shown on festival days: join the live themed station.
class FestivalLiveCard extends ConsumerWidget {
  const FestivalLiveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final festivals = ref.watch(todaysFestivalsProvider);
    if (festivals.isEmpty) return const SizedBox.shrink();
    final festival = festivals.first;
    if (festival.contentTags.isEmpty) return const SizedBox.shrink();

    final profile = ref.watch(profileProvider);
    final name = festival.localizedName(
        profile.languages.isNotEmpty ? profile.languages.first : 'english');
    // Prefer a real, analytics-fed count; fall back to the simulated one.
    final listeners =
        ref.watch(realListenerCountProvider('festival:${festival.id}')) ??
            festivalListenerCount(festival, DateTime.now());
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await ref
              .read(radioControllerProvider.notifier)
              .startRadio(onlyInterests: festival.contentTags);
          if (context.mounted) context.push('/player');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.errorContainer,
                scheme.errorContainer.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Text(festival.icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('LIVE',
                              style: TextStyle(
                                  color: scheme.onError,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('$name Radio',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$listeners listening now',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill, size: 40, color: scheme.error),
            ],
          ),
        ),
      ),
    );
  }
}
