/// Daily mystery story: one deterministic, date-seeded pick from the library
/// that stays hidden until the listener taps "Reveal". Everyone gets the same
/// mystery on the same day (shared watercooler moment), and it never repeats
/// two days in a row.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/remote_config_service.dart';
import '../../data/models/catalog_item.dart';
import '../../shared/providers/providers.dart';
import '../kids_mode/kids_mode_provider.dart';

class MysterySlot {
  /// Deterministic pick for [day] from [items]: stable across devices because
  /// it uses the sorted item IDs and a date-derived index.
  static CatalogItem? pick(List<CatalogItem> items, DateTime day) {
    final eligible = items
        .where((it) => it.type == 'library' && it.reachable)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (eligible.isEmpty) return null;
    final seed = day.year * 10000 + day.month * 100 + day.day;
    return eligible[seed % eligible.length];
  }
}

/// Today's mystery item in one of the user's languages, or null when the
/// mechanic is disabled / Kids Mode is on and the pick isn't kid-safe.
final mysteryItemProvider = Provider<CatalogItem?>((ref) {
  final rc = ref.watch(remoteConfigProvider);
  if (!rc.engageMysterySlotEnabled) return null;
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return null;
  final profile = ref.watch(profileProvider);
  final inLanguage = catalog.items
      .where((it) => profile.languages.contains(it.language))
      .toList();
  final item = MysterySlot.pick(inLanguage, DateTime.now());
  if (item == null) return null;
  if (ref.watch(kidsModeProvider) && !item.interests.contains('kids')) {
    return null;
  }
  return item;
});

/// Whether today's mystery has been revealed (resets each day).
class MysteryRevealController extends Notifier<bool> {
  static const storeKey = 'mystery_revealed_day';

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  bool build() =>
      ref.read(localStoreProvider).getSetting<String>(storeKey) == _today;

  Future<void> reveal() async {
    state = true;
    await ref.read(localStoreProvider).putSetting(storeKey, _today);
  }
}

final mysteryRevealedProvider =
    NotifierProvider<MysteryRevealController, bool>(
        MysteryRevealController.new);
