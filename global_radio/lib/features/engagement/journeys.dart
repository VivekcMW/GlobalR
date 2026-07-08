/// Serialized journeys: multi-episode series built purely from catalog
/// metadata (no new audio). One episode unlocks per day, giving a reason to
/// come back tomorrow. Definitions can be overridden remotely via the
/// `engage_journeys_json` Remote Config key.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/remote_config_service.dart';
import '../../data/local/local_store.dart';
import '../../data/models/catalog_item.dart';
import '../../shared/providers/providers.dart';
import '../kids_mode/kids_mode_provider.dart';

/// A journey definition: ordered list of catalog base IDs.
class Journey {
  final String id;
  final String title;
  final String emoji;
  final String subtitle;
  final List<String> baseIds;

  const Journey({
    required this.id,
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.baseIds,
  });

  factory Journey.fromJson(Map<String, dynamic> j) => Journey(
        id: j['id'] as String,
        title: j['title'] as String? ?? j['id'] as String,
        emoji: j['emoji'] as String? ?? '📚',
        subtitle: j['subtitle'] as String? ?? '',
        baseIds:
            (j['baseIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  static const defaults = [
    Journey(
      id: 'panchatantra-12',
      title: 'Panchatantra Journey',
      emoji: '🐒',
      subtitle: '12 timeless animal tales, one each day',
      baseIds: [
        'kids-monkey-and-crocodile',
        'kids-blue-jackal',
        'kids-crane-and-crab',
        'kids-four-friends',
        'kids-talkative-turtle',
        'kids-musical-donkey',
        'kids-elephants-and-mice',
        'kids-doves-and-net',
        'kids-jackal-and-drum',
        'kids-crows-and-snake',
        'kids-loyal-mongoose',
        'kids-rabbits-and-elephant',
      ],
    ),
    Journey(
      id: 'paisa-course',
      title: 'Paisa Ki Pathshala',
      emoji: '💰',
      subtitle: 'A 6-day money course in plain language',
      baseIds: [
        'finance-what-is-sip',
        'finance-emergency-fund',
        'finance-budget-50-30-20',
        'finance-upi-safety',
        'finance-beware-ponzi',
        'finance-credit-score',
      ],
    ),
  ];
}

/// Per-journey progress persisted in local settings.
class JourneyProgress {
  final int episodesDone; // next unlockable episode index == episodesDone
  final String lastPlayedDay; // 'yyyy-MM-dd' of the last played episode

  const JourneyProgress({this.episodesDone = 0, this.lastPlayedDay = ''});

  Map<String, dynamic> toJson() =>
      {'episodesDone': episodesDone, 'lastPlayedDay': lastPlayedDay};

  factory JourneyProgress.fromJson(Map<dynamic, dynamic> j) => JourneyProgress(
        episodesDone: (j['episodesDone'] as num?)?.toInt() ?? 0,
        lastPlayedDay: j['lastPlayedDay'] as String? ?? '',
      );
}

class Journeys {
  static const storeKey = 'journey_progress';

  static String dayKey(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  /// Whether the next episode is unlocked today (one per calendar day).
  static bool nextUnlocked(JourneyProgress p, DateTime now) =>
      p.lastPlayedDay != dayKey(now);

  /// Parse remote journey definitions; falls back to defaults on bad input.
  static List<Journey> parse(String json) {
    if (json.trim().isEmpty) return Journey.defaults;
    try {
      final raw = jsonDecode(json);
      if (raw is! List) return Journey.defaults;
      final journeys = raw
          .whereType<Map<String, dynamic>>()
          .map(Journey.fromJson)
          .where((j) => j.baseIds.isNotEmpty)
          .toList();
      return journeys.isEmpty ? Journey.defaults : journeys;
    } catch (e) {
      debugPrint('Journeys: bad engage_journeys_json: $e');
      return Journey.defaults;
    }
  }

  /// Find the catalog item for [baseId] in the first matching profile
  /// language (catalog IDs are `<base_id>-<lang>`).
  static CatalogItem? resolveItem(
      String baseId, List<CatalogItem> catalog, List<String> languages) {
    final candidates =
        catalog.where((it) => it.id.startsWith('$baseId-')).toList();
    if (candidates.isEmpty) return null;
    for (final lang in languages) {
      for (final it in candidates) {
        if (it.language == lang) return it;
      }
    }
    return candidates.first;
  }
}

/// State for the journey card on the Today screen.
class JourneyCardState {
  final Journey journey;
  final JourneyProgress progress;
  final CatalogItem nextItem;
  final bool unlockedToday;

  const JourneyCardState({
    required this.journey,
    required this.progress,
    required this.nextItem,
    required this.unlockedToday,
  });

  int get nextEpisodeNumber => progress.episodesDone + 1;
  int get totalEpisodes => journey.baseIds.length;
  bool get completed => progress.episodesDone >= journey.baseIds.length;
}

/// All journey definitions (remote-overridable).
final journeysProvider = Provider<List<Journey>>((ref) {
  final rc = ref.watch(remoteConfigProvider);
  return Journeys.parse(rc.engageJourneysJson);
});

/// The most relevant journey to surface today: first in-progress, else first
/// not-started; null when Kids Mode is off-limits for the journey content or
/// nothing resolves against the catalog.
final activeJourneyProvider = Provider<JourneyCardState?>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return null;
  final profile = ref.watch(profileProvider);
  final store = ref.watch(localStoreProvider);
  final kidsMode = ref.watch(kidsModeProvider);
  final raw =
      store.getSetting<Map<dynamic, dynamic>>(Journeys.storeKey) ?? const {};

  for (final journey in ref.watch(journeysProvider)) {
    final progress = raw[journey.id] is Map
        ? JourneyProgress.fromJson(raw[journey.id] as Map)
        : const JourneyProgress();
    if (progress.episodesDone >= journey.baseIds.length) continue; // done
    final item = Journeys.resolveItem(journey.baseIds[progress.episodesDone],
        catalog.items, profile.languages);
    if (item == null) continue;
    // Kids Mode: only kid-safe journeys may surface.
    if (kidsMode && !item.interests.any((i) => i == 'kids')) continue;
    return JourneyCardState(
      journey: journey,
      progress: progress,
      nextItem: item,
      unlockedToday: Journeys.nextUnlocked(progress, DateTime.now()),
    );
  }
  return null;
});

/// Marks the current episode as played and advances the journey.
Future<void> advanceJourney(
    LocalStore store, String journeyId, JourneyProgress progress) async {
  final raw =
      (store.getSetting<Map<dynamic, dynamic>>(Journeys.storeKey) ?? {})
          .map((k, v) => MapEntry(k.toString(), v));
  raw[journeyId] = JourneyProgress(
    episodesDone: progress.episodesDone + 1,
    lastPlayedDay: Journeys.dayKey(DateTime.now()),
  ).toJson();
  await store.putSetting(Journeys.storeKey, raw);
}
