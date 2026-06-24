import 'dart:math';

import '../data/models/catalog_item.dart';
import '../data/models/item_signals.dart';
import '../data/models/user_profile.dart';

/// Tunable scoring weights (ship as remote config — docs algorithm §10).
class RadioWeights {
  final double interest;
  final double freshness;
  final double popularity;
  final double affinity;
  final double noveltyPenalty;
  final double favoriteBoost;
  final int adEveryN;

  const RadioWeights({
    this.interest = 0.35,
    this.freshness = 0.20,
    this.popularity = 0.15,
    this.affinity = 0.20,
    this.noveltyPenalty = 0.25,
    this.favoriteBoost = 0.15,
    this.adEveryN = 4,
  });

  /// Cold-start weights: no affinity yet → lean on popularity + freshness.
  static const coldStart = RadioWeights(
    interest: 0.45,
    popularity: 0.30,
    freshness: 0.25,
    affinity: 0.0,
    noveltyPenalty: 0.0,
    favoriteBoost: 0.0,
  );

  static const standard = RadioWeights();
}

/// Pure, on-device radio engine: interests → filter → rank → sequence → queue.
///
/// Stateless except for an optional per-session interest bias adjusted by
/// live playback events (skip/complete). Deterministic given the same inputs +
/// `now`, which keeps it unit-testable.
class RadioEngine {
  final RadioWeights weights;

  /// Transient per-session nudges keyed by interest id (docs algorithm §5).
  final Map<String, double> _sessionBias = {};

  RadioEngine({this.weights = RadioWeights.standard});

  // ---- Public API -----------------------------------------------------------

  /// Build the radio queue for a user over the cached catalog + local signals.
  List<CatalogItem> buildRadio(
    UserProfile profile,
    Catalog catalog,
    Map<String, ItemSignals> signals, {
    required DateTime now,
  }) {
    final coldStart = signals.isEmpty;
    final w = coldStart ? RadioWeights.coldStart : weights;

    final pool = _filter(catalog.items, profile);
    if (pool.isEmpty) return const [];

    final ranked = [...pool]..sort((a, b) => _score(b, profile, signals, w, now)
        .compareTo(_score(a, profile, signals, w, now)));

    var queue = _sequence(ranked, profile, now);
    if (coldStart) queue = _guaranteeCoverage(queue, ranked, profile.interests);
    return queue;
  }

  /// React to a playback event by nudging session bias. Returns whether the
  /// queue tail should be re-ranked (true on skip).
  bool onPlaybackEvent(RadioEvent event, CatalogItem item) {
    final key = item.primaryInterest;
    switch (event) {
      case RadioEvent.skip:
        _sessionBias[key] = (_sessionBias[key] ?? 0) - 0.1;
        return true;
      case RadioEvent.complete:
        _sessionBias[key] = (_sessionBias[key] ?? 0) + 0.05;
        return false;
      case RadioEvent.play:
        return false;
    }
  }

  /// Re-rank only the unplayed tail of a queue (cheap; never touches history).
  List<CatalogItem> rerankTail(
    List<CatalogItem> queue,
    int fromIndex,
    UserProfile profile,
    Map<String, ItemSignals> signals, {
    required DateTime now,
  }) {
    if (fromIndex >= queue.length) return queue;
    final head = queue.sublist(0, fromIndex);
    final tail = queue.sublist(fromIndex)
      ..sort((a, b) => _score(b, profile, signals, weights, now)
          .compareTo(_score(a, profile, signals, weights, now)));
    return [...head, ...tail];
  }

  // ---- Filter ---------------------------------------------------------------

  List<CatalogItem> _filter(List<CatalogItem> catalog, UserProfile profile) {
    final langs = profile.languages.toSet();
    final interests = profile.interests.toSet();
    return catalog
        .where((it) =>
            langs.contains(it.language) &&
            it.interests.any(interests.contains) &&
            it.reachable)
        .toList();
  }

  // ---- Scoring --------------------------------------------------------------

  double _score(
    CatalogItem it,
    UserProfile profile,
    Map<String, ItemSignals> signals,
    RadioWeights w,
    DateTime now,
  ) {
    final s = signals[it.id] ?? ItemSignals.empty(it.id);
    final interestCount = max(profile.interests.length, 1);
    final overlap =
        it.interests.where(profile.interests.contains).length / interestCount;

    final base = w.interest * overlap.clamp(0.0, 1.0) +
        w.freshness * _freshnessBoost(it, now) +
        w.popularity * (it.popularity / 100.0) +
        w.affinity * _affinityBoost(s) -
        w.noveltyPenalty * _recencyPenalty(s.lastPlayedAt, now) +
        (s.favorited ? w.favoriteBoost : 0.0);

    return base + (_sessionBias[it.primaryInterest] ?? 0.0);
  }

  double _freshnessBoost(CatalogItem it, DateTime now) {
    if (it.isDaily && it.date != null && _isSameDay(it.date!, now)) return 1.0;
    final published = it.publishedDate;
    if (published == null) return 0.3;
    final ageDays = now.difference(published).inDays;
    return (1.0 - ageDays / 90.0).clamp(0.0, 1.0);
  }

  double _recencyPenalty(DateTime? lastPlayedAt, DateTime now) {
    if (lastPlayedAt == null) return 0.0;
    final hours = now.difference(lastPlayedAt).inHours;
    if (hours < 6) return 1.0;
    if (hours < 24) return 0.6;
    if (hours < 72) return 0.3;
    return 0.0;
  }

  double _affinityBoost(ItemSignals s) {
    final plays = max(s.playCount, 1);
    final completeRate = s.completeCount / plays;
    final skipRate = s.skipCount / plays;
    return (0.5 + 0.5 * completeRate - 0.5 * skipRate).clamp(0.0, 1.0);
  }

  // ---- Sequencing -----------------------------------------------------------

  List<CatalogItem> _sequence(
      List<CatalogItem> ranked, UserProfile profile, DateTime now) {
    final queue = <CatalogItem>[];
    final used = <String>{};

    // (a) Lead with today's daily content, capped 1 per interest.
    final dailyPerInterest = <String, bool>{};
    for (final it in ranked) {
      if (it.isDaily && it.date != null && _isSameDay(it.date!, now)) {
        if (dailyPerInterest[it.primaryInterest] != true) {
          queue.add(it);
          used.add(it.id);
          dailyPerInterest[it.primaryInterest] = true;
        }
      }
    }

    // (b) Round-robin interleave by interest so no topic dominates.
    final buckets = <String, List<CatalogItem>>{};
    for (final interest in profile.interests) {
      buckets[interest] = [];
    }
    for (final it in ranked) {
      if (used.contains(it.id)) continue;
      final bucket = profile.interests
          .firstWhere(it.interests.contains, orElse: () => it.primaryInterest);
      (buckets[bucket] ??= []).add(it);
    }

    var rotation = 0;
    bool anyLeft() => buckets.values.any((b) => b.isNotEmpty);
    while (anyLeft()) {
      final order = _rotate(profile.interests, rotation++);
      var addedThisPass = false;

      // First pass: add the best item per interest that satisfies constraints.
      for (final interest in order) {
        final bucket = buckets[interest];
        if (bucket == null || bucket.isEmpty) continue;
        final it = bucket.first;
        if (used.contains(it.id)) {
          bucket.removeAt(0);
          continue;
        }
        if (_violatesConstraints(queue, it)) continue; // try later
        bucket.removeAt(0);
        queue.add(it);
        used.add(it.id);
        addedThisPass = true;
      }

      // Progress guard: if nothing could satisfy constraints this pass, the
      // remaining items are all "blocked" (e.g. a single-interest catalog).
      // Force-add the highest-ranked remaining item so we always terminate.
      if (!addedThisPass) {
        CatalogItem? forced;
        for (final interest in order) {
          final bucket = buckets[interest];
          if (bucket != null && bucket.isNotEmpty) {
            forced = bucket.removeAt(0);
            break;
          }
        }
        if (forced == null) break; // nothing left
        if (!used.contains(forced.id)) {
          queue.add(forced);
          used.add(forced.id);
        }
      }
    }
    return queue;
  }

  bool _violatesConstraints(List<CatalogItem> queue, CatalogItem it) {
    if (queue.any((x) => x.id == it.id)) return true;
    // Only block once there are 3 in a row already.
    if (queue.length >= 3) {
      final last3 = queue.sublist(queue.length - 3);
      if (last3.every((x) => x.primaryInterest == it.primaryInterest)) {
        return true;
      }
    }
    if (queue.isNotEmpty &&
        queue.last.durationSec > 600 &&
        it.durationSec > 600) {
      return true;
    }
    return false;
  }

  /// Cold start: ensure at least one item per selected interest in first 5.
  List<CatalogItem> _guaranteeCoverage(
    List<CatalogItem> queue,
    List<CatalogItem> ranked,
    List<String> interests,
  ) {
    if (queue.length < 2) return queue;
    final firstFive = queue.take(5).toList();
    final covered = firstFive.map((e) => e.primaryInterest).toSet();
    final missing = interests.where((i) => !covered.contains(i)).toList();
    if (missing.isEmpty) return queue;

    final result = [...queue];
    for (final interest in missing) {
      final pick = ranked.firstWhere(
        (it) => it.primaryInterest == interest,
        orElse: () => ranked.first,
      );
      result.remove(pick);
      final insertAt = min(4, result.length);
      result.insert(insertAt, pick);
    }
    return result;
  }

  // ---- helpers --------------------------------------------------------------

  List<String> _rotate(List<String> list, int by) {
    if (list.isEmpty) return list;
    final n = by % list.length;
    return [...list.sublist(n), ...list.sublist(0, n)];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

enum RadioEvent { play, complete, skip }
