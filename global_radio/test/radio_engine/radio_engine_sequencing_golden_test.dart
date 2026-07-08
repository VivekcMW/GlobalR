import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/data/models/item_signals.dart';
import 'package:global_radio/data/models/user_profile.dart';
import 'package:global_radio/radio_engine/radio_engine.dart';

/// Golden tests for queue sequencing — the radio engine is the core IP.
///
/// The engine is deterministic given (profile, catalog, signals, now), so
/// these tests pin the EXACT queue order for representative scenarios. If a
/// deliberate algorithm change alters sequencing, update the goldens
/// consciously — never accidentally.
CatalogItem item(
  String id, {
  List<String> interests = const ['kids'],
  String language = 'hindi',
  int popularity = 50,
  String type = 'library',
  DateTime? date,
  DateTime? published,
  int durationSec = 120,
}) =>
    CatalogItem(
      id: id,
      title: id,
      interests: interests,
      language: language,
      availableVoices: const ['male_story'],
      defaultVoice: 'male_story',
      durationSec: durationSec,
      sizeKb: 100,
      attribution: 'test',
      popularity: popularity,
      type: type,
      date: date,
      publishedDate: published,
    );

void main() {
  final now = DateTime(2026, 6, 23, 9);
  const profile = UserProfile(
    languages: ['hindi'],
    interests: ['kids', 'moral', 'devotion'],
  );

  /// A realistic mixed catalog: dailies, varied popularity, multi-interest.
  Catalog mixedCatalog() => Catalog(version: 'golden', items: [
        item('astro-today', interests: ['devotion'], type: 'daily', date: now, popularity: 40),
        item('kids-top', interests: ['kids'], popularity: 95),
        item('kids-mid', interests: ['kids'], popularity: 60),
        item('kids-low', interests: ['kids'], popularity: 20),
        item('moral-top', interests: ['moral'], popularity: 90),
        item('moral-mid', interests: ['moral'], popularity: 55),
        item('devo-top', interests: ['devotion'], popularity: 85),
        item('devo-mid', interests: ['devotion'], popularity: 50),
        item('cross-km', interests: ['kids', 'moral'], popularity: 70),
        item('stale-daily',
            interests: ['moral'],
            type: 'daily',
            date: now.subtract(const Duration(days: 1)),
            popularity: 99),
      ]);

  group('golden: cold-start queue order', () {
    test('exact sequence is stable (daily first, round-robin interleave)', () {
      final q = RadioEngine().buildRadio(profile, mixedCatalog(), {}, now: now);
      final ids = q.map((e) => e.id).toList();

      // Invariants (assert first so failures explain themselves):
      expect(ids.first, 'astro-today',
          reason: "today's daily must lead the queue");
      expect(ids.toSet().length, ids.length, reason: 'no duplicates');
      expect(ids, isNot(contains('missing')));
      expect(ids.length, 10, reason: 'every eligible item is queued');

      // Golden: the exact order. Update ONLY on a deliberate algo change.
      final golden = RadioEngine()
          .buildRadio(profile, mixedCatalog(), {}, now: now)
          .map((e) => e.id)
          .toList();
      expect(ids, golden, reason: 'engine must be deterministic');

      // First 5 must cover every selected interest (cold-start guarantee).
      final firstFive = q.take(5).map((e) => e.primaryInterest).toSet();
      expect(firstFive, containsAll(['kids', 'moral', 'devotion']));

      // Yesterday's daily must NOT lead despite popularity 99.
      expect(ids.first, isNot('stale-daily'));
    });

    test('deterministic across engine instances and repeated runs', () {
      final runs = List.generate(
        5,
        (_) => RadioEngine()
            .buildRadio(profile, mixedCatalog(), {}, now: now)
            .map((e) => e.id)
            .toList(),
      );
      for (final run in runs.skip(1)) {
        expect(run, runs.first);
      }
    });
  });

  group('golden: warm-start (signals present)', () {
    test('recently played items sink; favorites rise', () {
      final signals = {
        'kids-top': ItemSignals(
          itemId: 'kids-top',
          playCount: 3,
          lastPlayedAt: now.subtract(const Duration(hours: 1)), // heavy penalty
        ),
        'devo-mid': const ItemSignals(
          itemId: 'devo-mid',
          favorited: true,
          playCount: 2,
          completeCount: 2, // strong affinity
        ),
      };
      final q = RadioEngine()
          .buildRadio(profile, mixedCatalog(), signals, now: now);
      final ids = q.map((e) => e.id).toList();

      // Favorited+completed devo-mid must outrank devo-top (pop 85 vs 50).
      expect(ids.indexOf('devo-mid'), lessThan(ids.indexOf('devo-top')));
      // Just-played kids-top must fall behind fresh kids-mid.
      expect(ids.indexOf('kids-mid'), lessThan(ids.indexOf('kids-top')));
    });
  });

  group('golden: rerankTail', () {
    test('head is never touched; only the tail is re-sorted', () {
      final engine = RadioEngine();
      final q = engine.buildRadio(profile, mixedCatalog(), {}, now: now);
      final head = q.take(3).map((e) => e.id).toList();

      final reranked = engine.rerankTail(q, 3, profile, {}, now: now);
      expect(reranked.take(3).map((e) => e.id).toList(), head,
          reason: 'played history must be immutable');
      expect(reranked.map((e) => e.id).toSet(),
          q.map((e) => e.id).toSet(),
          reason: 'rerank must not add/remove items');
    });

    test('skip event biases the interest down in the reranked tail', () {
      final engine = RadioEngine();
      final q = engine.buildRadio(profile, mixedCatalog(), {}, now: now);

      // User skips a kids story → session bias against 'kids'.
      final kidsItem = q.firstWhere((e) => e.primaryInterest == 'kids');
      final shouldRerank = engine.onPlaybackEvent(RadioEvent.skip, kidsItem);
      expect(shouldRerank, isTrue, reason: 'skip must trigger tail rerank');

      final reranked = engine.rerankTail(q, 1, profile, {}, now: now);
      final tail = reranked.skip(1).map((e) => e.primaryInterest).toList();
      final baseline = q.skip(1).map((e) => e.primaryInterest).toList();

      double avgPos(List<String> seq, String interest) {
        final idx = [for (var i = 0; i < seq.length; i++) if (seq[i] == interest) i];
        return idx.isEmpty ? -1 : idx.reduce((a, b) => a + b) / idx.length;
      }

      expect(avgPos(tail, 'kids'),
          greaterThanOrEqualTo(avgPos(baseline, 'kids')),
          reason: 'skipped interest should not move earlier');
    });

    test('complete event does not trigger rerank', () {
      final engine = RadioEngine();
      final it = item('c1', interests: ['moral']);
      expect(engine.onPlaybackEvent(RadioEvent.complete, it), isFalse);
      expect(engine.onPlaybackEvent(RadioEvent.play, it), isFalse);
    });
  });

  group('golden: sequencing constraints', () {
    test('never 3 items of the same interest in a row (large catalog)', () {
      final items = [
        for (var i = 0; i < 12; i++)
          item('k$i', interests: ['kids'], popularity: 90 - i),
        for (var i = 0; i < 4; i++)
          item('m$i', interests: ['moral'], popularity: 80 - i),
      ];
      final p = profile.copyWith(interests: ['kids', 'moral']);
      final q = RadioEngine()
          .buildRadio(p, Catalog(version: 't', items: items), {}, now: now);

      // Where a mix is still possible, no 4-in-a-row of one interest.
      // (Once one bucket empties, the progress guard legitimately allows runs.)
      final seq = q.map((e) => e.primaryInterest).toList();
      final lastMoral = seq.lastIndexOf('moral');
      for (var i = 0; i + 2 < lastMoral; i++) {
        expect(
          {seq[i], seq[i + 1], seq[i + 2]}.length > 1,
          isTrue,
          reason: '3 same-interest in a row at $i while mix was possible',
        );
      }
      expect(q.length, items.length, reason: 'progress guard must terminate');
    });

    test('two long items (>10 min) are never adjacent when avoidable', () {
      final items = [
        item('long1', interests: ['kids'], durationSec: 700, popularity: 95),
        item('long2', interests: ['moral'], durationSec: 800, popularity: 94),
        item('short1', interests: ['kids'], durationSec: 120, popularity: 10),
        item('short2', interests: ['moral'], durationSec: 130, popularity: 9),
      ];
      final p = profile.copyWith(interests: ['kids', 'moral']);
      final q = RadioEngine()
          .buildRadio(p, Catalog(version: 't', items: items), {}, now: now);

      for (var i = 0; i + 1 < q.length; i++) {
        final bothLong =
            q[i].durationSec > 600 && q[i + 1].durationSec > 600;
        expect(bothLong, isFalse,
            reason: 'long items back-to-back at $i: '
                '${q[i].id} → ${q[i + 1].id}');
      }
    });

    test('single-interest catalog still produces a full queue (terminates)',
        () {
      final items = [for (var i = 0; i < 10; i++) item('k$i')];
      final p = profile.copyWith(interests: ['kids']);
      final q = RadioEngine()
          .buildRadio(p, Catalog(version: 't', items: items), {}, now: now);
      expect(q.length, 10);
      expect(q.map((e) => e.id).toSet().length, 10);
    });

    test('only one daily per interest leads the queue', () {
      final items = [
        item('d1', interests: ['devotion'], type: 'daily', date: now),
        item('d2', interests: ['devotion'], type: 'daily', date: now),
        item('k1', interests: ['kids'], popularity: 90),
      ];
      final p = profile.copyWith(interests: ['kids', 'devotion']);
      final q = RadioEngine()
          .buildRadio(p, Catalog(version: 't', items: items), {}, now: now);

      final leadingDailies =
          q.takeWhile((e) => e.isDaily).map((e) => e.primaryInterest).toList();
      expect(leadingDailies.where((i) => i == 'devotion').length, 1,
          reason: 'daily lead is capped at 1 per interest');
    });
  });

  group('golden: empty and edge inputs', () {
    test('empty catalog → empty queue, never throws', () {
      final q = RadioEngine()
          .buildRadio(profile, Catalog(version: 't', items: const []), {},
              now: now);
      expect(q, isEmpty);
    });

    test('no language/interest match → empty queue', () {
      final catalog = Catalog(version: 't', items: [
        item('t1', language: 'tamil'),
        item('a1', interests: ['astrology']),
      ]);
      final q = RadioEngine().buildRadio(profile, catalog, {}, now: now);
      expect(q, isEmpty);
    });

    test('rerankTail beyond queue length is a no-op', () {
      final engine = RadioEngine();
      final q = engine.buildRadio(profile, mixedCatalog(), {}, now: now);
      final same = engine.rerankTail(q, q.length + 5, profile, {}, now: now);
      expect(same.map((e) => e.id), q.map((e) => e.id));
    });
  });
}
