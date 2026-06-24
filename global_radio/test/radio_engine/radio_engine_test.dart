import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/data/models/item_signals.dart';
import 'package:global_radio/data/models/user_profile.dart';
import 'package:global_radio/radio_engine/radio_engine.dart';

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
  final profile = const UserProfile(
    languages: ['hindi'],
    interests: ['kids', 'moral', 'devotion'],
  );

  group('filter', () {
    test('keeps only matching language + interest + reachable', () {
      final catalog = Catalog(version: 't', items: [
        item('a', interests: ['kids']),
        item('b', language: 'tamil'), // wrong language
        item('c', interests: ['astrology']), // not selected
      ]);
      final q = RadioEngine().buildRadio(profile, catalog, {}, now: now);
      expect(q.map((e) => e.id), contains('a'));
      expect(q.map((e) => e.id), isNot(contains('b')));
      expect(q.map((e) => e.id), isNot(contains('c')));
    });
  });

  group('sequencing', () {
    test("today's daily content leads the queue", () {
      final catalog = Catalog(version: 't', items: [
        item('story1', interests: ['kids'], popularity: 90),
        item('story2', interests: ['moral'], popularity: 85),
        item('astro-today',
            interests: ['devotion'], type: 'daily', date: now),
      ]);
      final p = profile.copyWith(interests: ['kids', 'moral', 'devotion']);
      final q = RadioEngine().buildRadio(p, catalog, {}, now: now);
      expect(q.first.id, 'astro-today');
    });

    test('avoids 3 same-interest items in a row', () {
      final items = [
        for (var i = 0; i < 5; i++) item('k$i', interests: ['kids']),
        for (var i = 0; i < 5; i++) item('m$i', interests: ['moral']),
      ];
      final p = profile.copyWith(interests: ['kids', 'moral']);
      final q = RadioEngine()
          .buildRadio(p, Catalog(version: 't', items: items), {}, now: now);
      for (var i = 0; i + 2 < q.length; i++) {
        final trio = [q[i], q[i + 1], q[i + 2]].map((e) => e.primaryInterest);
        expect(trio.toSet().length, greaterThan(1),
            reason: '3 same-interest in a row at $i');
      }
    });

    test('no duplicate items in queue', () {
      final items = [for (var i = 0; i < 8; i++) item('x$i')];
      final q = RadioEngine().buildRadio(
          profile, Catalog(version: 't', items: items), {},
          now: now);
      expect(q.map((e) => e.id).toSet().length, q.length);
    });
  });

  group('cold start coverage', () {
    test('first 5 items cover every selected interest when available', () {
      final items = [
        for (var i = 0; i < 6; i++) item('k$i', interests: ['kids'], popularity: 90),
        item('m0', interests: ['moral'], popularity: 10),
        item('d0', interests: ['devotion'], popularity: 10),
      ];
      final q = RadioEngine().buildRadio(
          profile, Catalog(version: 't', items: items), {},
          now: now);
      final firstFive = q.take(5).map((e) => e.primaryInterest).toSet();
      expect(firstFive, containsAll(['kids', 'moral', 'devotion']));
    });
  });

  group('scoring', () {
    test('favorited + recently completed item ranks above a stale one', () {
      final items = [
        item('fav', interests: ['kids'], popularity: 50),
        item('plain', interests: ['kids'], popularity: 50),
      ];
      final signals = {
        'fav': const ItemSignals(
            itemId: 'fav', favorited: true, playCount: 2, completeCount: 2),
      };
      final p = profile.copyWith(interests: ['kids']);
      final q = RadioEngine()
          .buildRadio(p, Catalog(version: 't', items: items), signals, now: now);
      expect(q.first.id, 'fav');
    });
  });

  group('voice resolution', () {
    test('falls back to default voice when preferred is unavailable', () {
      final it = item('v').copyOf(availableVoices: ['female_warm']);
      expect(it.audioUrlFor('male_story'), endsWith('/female_warm/v.mp3'));
      expect(it.audioUrlFor('female_warm'), endsWith('/female_warm/v.mp3'));
    });
  });
}

extension on CatalogItem {
  CatalogItem copyOf({List<String>? availableVoices}) => CatalogItem(
        id: id,
        title: title,
        interests: interests,
        language: language,
        availableVoices: availableVoices ?? this.availableVoices,
        defaultVoice: (availableVoices ?? this.availableVoices).first,
        durationSec: durationSec,
        sizeKb: sizeKb,
        attribution: attribution,
        popularity: popularity,
        type: type,
      );
}
