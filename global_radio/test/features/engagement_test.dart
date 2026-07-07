import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/features/engagement/engagement_notifications.dart';
import 'package:global_radio/features/engagement/habit_clock.dart';
import 'package:global_radio/features/engagement/journeys.dart';
import 'package:global_radio/features/engagement/listener_counts.dart';
import 'package:global_radio/features/engagement/milestones.dart';
import 'package:global_radio/features/engagement/mystery_slot.dart';
import 'package:global_radio/features/engagement/weekly_goal.dart';

CatalogItem item(String id, {String language = 'hindi', String type = 'library', bool reachable = true, List<String> interests = const ['kids']}) {
  return CatalogItem(
    id: id,
    title: id,
    interests: interests,
    language: language,
    availableVoices: const ['v1'],
    defaultVoice: 'v1',
    durationSec: 180,
    sizeKb: 900,
    attribution: 'test',
    type: type,
    reachable: reachable,
  );
}

void main() {
  group('HabitClock', () {
    test('needs at least 3 samples before suggesting a habit hour', () {
      expect(HabitClock.habitHour([]), isNull);
      expect(HabitClock.habitHour([8, 9]), isNull);
      expect(HabitClock.habitHour([8, 9, 10]), 9);
    });

    test('uses the median so outliers do not move the nudge', () {
      expect(HabitClock.habitHour([7, 7, 8, 8, 23]), 8);
      expect(HabitClock.habitHour([6, 20, 20, 20, 21]), 20);
    });

    test('rolling window keeps only the newest samples', () {
      var samples = <int>[];
      for (var i = 0; i < 40; i++) {
        samples = HabitClock.addSample(samples, i % 24);
      }
      expect(samples.length, HabitClock.maxSamples);
      // The oldest entries (0..11) were evicted.
      expect(samples.first, (40 - HabitClock.maxSamples) % 24);
    });

    test('clamps out-of-range hours', () {
      expect(HabitClock.addSample([], 99).single, 23);
      expect(HabitClock.addSample([], -5).single, 0);
    });
  });

  group('QuietHours', () {
    test('22:00–07:00 is quiet, the rest is not', () {
      expect(QuietHours.isQuiet(22), isTrue);
      expect(QuietHours.isQuiet(23), isTrue);
      expect(QuietHours.isQuiet(0), isTrue);
      expect(QuietHours.isQuiet(6), isTrue);
      expect(QuietHours.isQuiet(7), isFalse);
      expect(QuietHours.isQuiet(12), isFalse);
      expect(QuietHours.isQuiet(21), isFalse);
    });

    test('clamp moves quiet-hour notifications to 07:30', () {
      expect(QuietHours.clamp(23, 45), (7, 30));
      expect(QuietHours.clamp(3, 0), (7, 30));
      expect(QuietHours.clamp(19, 0), (19, 0));
      expect(QuietHours.clamp(8, 45), (8, 45));
    });
  });

  group('Milestones', () {
    test('crossing a threshold triggers exactly once', () {
      expect(Milestones.newlyCrossed(0, 2), isNull);
      expect(Milestones.newlyCrossed(0, 3), 3);
      expect(Milestones.newlyCrossed(3, 3), isNull); // already celebrated
      expect(Milestones.newlyCrossed(3, 7), 7);
      expect(Milestones.newlyCrossed(7, 29), isNull);
      expect(Milestones.newlyCrossed(7, 30), 30);
    });

    test('jumping over several thresholds celebrates the highest', () {
      expect(Milestones.newlyCrossed(0, 100), 100);
      expect(Milestones.newlyCrossed(30, 365), 365);
    });

    test('every threshold has celebration copy', () {
      for (final t in Milestones.thresholds) {
        expect(Milestones.messageFor(t), isNotEmpty);
      }
    });
  });

  group('Journeys', () {
    test('default journeys are well-formed', () {
      expect(Journey.defaults, hasLength(2));
      for (final j in Journey.defaults) {
        expect(j.baseIds, isNotEmpty);
        expect(j.baseIds.toSet().length, j.baseIds.length,
            reason: '${j.id} has duplicate episodes');
      }
    });

    test('bad remote JSON falls back to defaults', () {
      expect(Journeys.parse(''), Journey.defaults);
      expect(Journeys.parse('not json'), Journey.defaults);
      expect(Journeys.parse('{"a":1}'), Journey.defaults);
      expect(Journeys.parse('[]'), Journey.defaults);
    });

    test('valid remote JSON overrides defaults', () {
      final parsed = Journeys.parse(
          '[{"id":"x","title":"X","baseIds":["kids-blue-jackal"]}]');
      expect(parsed, hasLength(1));
      expect(parsed.first.id, 'x');
    });

    test('one episode unlocks per calendar day', () {
      final today = DateTime(2026, 7, 4);
      const fresh = JourneyProgress();
      expect(Journeys.nextUnlocked(fresh, today), isTrue);
      final playedToday =
          JourneyProgress(episodesDone: 1, lastPlayedDay: '2026-07-04');
      expect(Journeys.nextUnlocked(playedToday, today), isFalse);
      expect(
          Journeys.nextUnlocked(playedToday, DateTime(2026, 7, 5)), isTrue);
    });

    test('resolveItem prefers the first profile language', () {
      final catalog = [
        item('kids-blue-jackal-hi', language: 'hindi'),
        item('kids-blue-jackal-ta', language: 'tamil'),
      ];
      final it = Journeys.resolveItem(
          'kids-blue-jackal', catalog, ['tamil', 'hindi']);
      expect(it!.language, 'tamil');
      // Unknown language falls back to any available match.
      final fallback =
          Journeys.resolveItem('kids-blue-jackal', catalog, ['urdu']);
      expect(fallback, isNotNull);
      // Missing base id resolves to nothing.
      expect(Journeys.resolveItem('kids-nope', catalog, ['hindi']), isNull);
    });
  });

  group('MysterySlot', () {
    final items = [
      item('a-story-hi'),
      item('b-story-hi'),
      item('c-story-hi'),
      item('daily-astro-hi', type: 'daily'),
      item('dead-hi', reachable: false),
    ];

    test('pick is deterministic for a given day', () {
      final day = DateTime(2026, 7, 4);
      expect(MysterySlot.pick(items, day)!.id,
          MysterySlot.pick([...items.reversed], day)!.id);
    });

    test('changes across days and skips daily/unreachable items', () {
      final ids = <String>{};
      for (var d = 1; d <= 3; d++) {
        final picked = MysterySlot.pick(items, DateTime(2026, 7, d))!;
        expect(picked.type, 'library');
        expect(picked.reachable, isTrue);
        ids.add(picked.id);
      }
      expect(ids.length, greaterThan(1));
    });

    test('empty eligible list yields null', () {
      expect(MysterySlot.pick([], DateTime(2026, 7, 4)), isNull);
      expect(
          MysterySlot.pick(
              [item('x', type: 'daily')], DateTime(2026, 7, 4)),
          isNull);
    });
  });

  group('WeeklyGoal', () {
    test('counts distinct days within the trailing 7-day window', () {
      final now = DateTime(2026, 7, 10, 20);
      final sessions = [
        DateTime(2026, 7, 10, 8), // today
        DateTime(2026, 7, 10, 21), // same day — counted once
        DateTime(2026, 7, 8),
        DateTime(2026, 7, 4), // window edge (today-6) — counts
        DateTime(2026, 7, 3), // outside window
        DateTime(2026, 6, 1), // way outside
      ];
      expect(WeeklyGoal.daysListened(sessions, now), 3);
    });

    test('goal state math', () {
      const met = WeeklyGoalState(daysListened: 5, goalDays: 5);
      expect(met.met, isTrue);
      expect(met.progress, 1.0);
      const partial = WeeklyGoalState(daysListened: 2, goalDays: 5);
      expect(partial.met, isFalse);
      expect(partial.progress, closeTo(0.4, 0.001));
    });
  });

  group('ListenerCounts', () {
    test('parses valid payloads and drops junk', () {
      final counts = ListenerCounts.parse(
          '{"festival:diwali": 5120, "station:kids": 812.7, "bad": -3, "zero": 0}');
      expect(counts['festival:diwali'], 5120);
      expect(counts['station:kids'], 812);
      expect(counts.containsKey('bad'), isFalse);
      expect(counts.containsKey('zero'), isFalse);
    });

    test('bad input yields empty map (simulated fallback kicks in)', () {
      expect(ListenerCounts.parse(''), isEmpty);
      expect(ListenerCounts.parse('nope'), isEmpty);
      expect(ListenerCounts.parse('[1,2]'), isEmpty);
      expect(ListenerCounts.parse('{"x": "NaN"}'), isEmpty);
    });
  });
}
