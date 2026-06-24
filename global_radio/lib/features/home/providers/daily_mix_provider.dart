import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/item_signals.dart';
import '../../../radio_engine/daily_mix_generator.dart';
import '../../../shared/providers/providers.dart';

/// Provider for the daily mix generator.
final dailyMixGeneratorProvider = Provider<DailyMixGenerator>((ref) {
  return DailyMixGenerator();
});

/// Provider for the current daily mix.
final dailyMixProvider = Provider<DailyMix?>((ref) {
  final generator = ref.read(dailyMixGeneratorProvider);
  final profile = ref.watch(profileProvider);
  final catalogAsync = ref.watch(catalogProvider);
  final store = ref.read(localStoreProvider);

  final catalog = catalogAsync.valueOrNull;
  if (catalog == null) return null;

  final signals = store.loadAllSignals();

  return generator.generate(
    profile: profile,
    catalog: catalog,
    signals: signals,
    now: DateTime.now(),
  );
});

/// Provider for favorites mix.
final favoritesMixProvider = Provider<DailyMix?>((ref) {
  final generator = ref.read(dailyMixGeneratorProvider);
  final profile = ref.watch(profileProvider);
  final catalogAsync = ref.watch(catalogProvider);
  final store = ref.read(localStoreProvider);

  final catalog = catalogAsync.valueOrNull;
  if (catalog == null) return null;

  final signals = store.loadAllSignals();

  return generator.generateFavorites(
    profile: profile,
    catalog: catalog,
    signals: signals,
    now: DateTime.now(),
  );
});

/// Provider family for interest-specific mixes.
final interestMixProvider = Provider.family<DailyMix?, String>((ref, interest) {
  final generator = ref.read(dailyMixGeneratorProvider);
  final profile = ref.watch(profileProvider);
  final catalogAsync = ref.watch(catalogProvider);
  final store = ref.read(localStoreProvider);

  final catalog = catalogAsync.valueOrNull;
  if (catalog == null) return null;

  final signals = store.loadAllSignals();

  return generator.generateForInterest(
    interest: interest,
    profile: profile,
    catalog: catalog,
    signals: signals,
    now: DateTime.now(),
  );
});
