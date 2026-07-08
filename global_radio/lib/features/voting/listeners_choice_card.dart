import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../shared/providers/radio_controller.dart';
import 'voting_service.dart';

/// Maps content-request categories to catalog interest ids.
const _categoryToInterests = <String, List<String>>{
  'kids_stories': ['kids', 'fairytales', 'bedtime'],
  'stories': ['moral', 'fiction', 'folklore'],
  'comedy': ['comedy'],
  'news': ['news'],
  'lifestyle': ['health', 'cooking', 'travel'],
  'podcast': ['education', 'biography'],
};

/// The interests behind this week's most-voted content requests.
final listenersChoiceProvider = Provider<List<String>>((ref) {
  final requests = ref.watch(contentRequestsProvider);
  final sorted = [...requests]..sort((a, b) => b.votes.compareTo(a.votes));
  final interests = <String>[];
  for (final req in sorted) {
    for (final id in _categoryToInterests[req.category] ?? const <String>[]) {
      if (!interests.contains(id)) interests.add(id);
    }
    if (interests.length >= 4) break;
  }
  return interests;
});

/// Home card: a station programmed by community votes.
class ListenersChoiceCard extends ConsumerWidget {
  const ListenersChoiceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(listenersChoiceProvider);
    if (interests.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final labels =
        interests.take(3).map(Interest.labelFor).join(' · ');

    return Card(
      child: ListTile(
        leading: Icon(Icons.how_to_vote_outlined, color: scheme.primary),
        title: const Text("Listeners' Choice"),
        subtitle: Text('Top voted this week: $labels',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.play_circle_outline),
        onTap: () async {
          await ref
              .read(radioControllerProvider.notifier)
              .startRadio(onlyInterests: interests);
          if (context.mounted) context.push('/player');
        },
      ),
    );
  }
}
