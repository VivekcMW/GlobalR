import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:global_radio/data/models/user_profile.dart';
import 'package:global_radio/features/engagement/engagement_cards.dart';
import 'package:global_radio/features/engagement/journeys.dart';
import 'package:global_radio/features/engagement/mystery_slot.dart';
import 'package:global_radio/shared/providers/providers.dart';
import 'package:global_radio/shared/providers/radio_controller.dart';

import '../helpers/fake_controllers.dart';

void main() {
  Widget wrap(Widget child, {required FakeLocalStore store}) {
    final catalog = testCatalog([
      testItem(id: 'kids-monkey-and-crocodile-hi', title: 'Monkey & Crocodile'),
      testItem(id: 'kids-blue-jackal-hi', title: 'Blue Jackal'),
    ]);
    return ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        profileProvider.overrideWith(() => FakeProfileController(
            const UserProfile(languages: ['hindi'], interests: ['kids']))),
        catalogProvider.overrideWith(() => FakeCatalogController(catalog)),
        radioControllerProvider.overrideWith(() => FakeRadioController()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('JourneyCard', () {
    testWidgets('shows first unlocked episode of the default journey',
        (tester) async {
      await tester.pumpWidget(
          wrap(const JourneyCard(), store: FakeLocalStore()));
      await tester.pumpAndSettle();

      expect(find.text('Panchatantra Journey'), findsOneWidget);
      expect(find.textContaining('Episode 1 of 12'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    });

    testWidgets('locks the next episode until tomorrow after playing',
        (tester) async {
      final store = FakeLocalStore();
      await store.putSetting(Journeys.storeKey, {
        'panchatantra-12': JourneyProgress(
          episodesDone: 1,
          lastPlayedDay: Journeys.dayKey(DateTime.now()),
        ).toJson(),
      });
      await tester.pumpWidget(wrap(const JourneyCard(), store: store));
      await tester.pumpAndSettle();

      expect(find.textContaining('unlocks tomorrow'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock), findsOneWidget);
    });
  });

  group('MysteryCard', () {
    testWidgets('hides the pick until revealed, then offers playback',
        (tester) async {
      await tester.pumpWidget(
          wrap(const MysteryCard(), store: FakeLocalStore()));
      await tester.pumpAndSettle();

      expect(find.text("Today's Mystery Story"), findsOneWidget);

      await tester.tap(find.byType(MysteryCard));
      await tester.pumpAndSettle();

      // Revealed: shows the real title of the deterministic pick.
      expect(find.text("Today's Mystery Story"), findsNothing);
      expect(find.text('Tap to listen'), findsOneWidget);
    });

    testWidgets('reveal persists for the day', (tester) async {
      final store = FakeLocalStore();
      final now = DateTime.now();
      await store.putSetting(MysteryRevealController.storeKey,
          '${now.year}-${now.month}-${now.day}');
      await tester.pumpWidget(wrap(const MysteryCard(), store: store));
      await tester.pumpAndSettle();

      expect(find.text('Tap to listen'), findsOneWidget);
    });
  });

  group('WeeklyGoalCard', () {
    testWidgets('renders goal progress', (tester) async {
      await tester.pumpWidget(
          wrap(const WeeklyGoalCard(), store: FakeLocalStore()));
      await tester.pumpAndSettle();

      expect(find.text('Weekly goal'), findsOneWidget);
      expect(find.textContaining('of 7 days'), findsOneWidget);
    });
  });
}
