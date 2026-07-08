import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/data/models/item_signals.dart';
import 'package:global_radio/features/library/library_screen.dart';
import 'package:global_radio/shared/providers/providers.dart';
import 'package:global_radio/shared/providers/radio_controller.dart';

import '../helpers/fake_controllers.dart';

void main() {
  Widget createTestWidget({
    List<CatalogItem> catalogItems = const [],
    List<String> favoriteIds = const [],
    List<String> recentIds = const [],
  }) {
    final testRouter = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
        GoRoute(
          path: '/player',
          builder: (_, __) => const Scaffold(body: Text('Player')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(FakeLocalStore()),
        catalogProvider.overrideWith(
            () => FakeCatalogController(testCatalog(catalogItems))),
        favoritesProvider.overrideWithValue(
            favoriteIds.map((id) => ItemSignals(itemId: id)).toList()),
        recentlyPlayedProvider.overrideWithValue(
            recentIds.map((id) => ItemSignals(itemId: id)).toList()),
        radioControllerProvider.overrideWith(FakeRadioController.new),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  group('LibraryScreen Widget', () {
    testWidgets('displays Saved title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsWidgets); // AppBar + section header
    });

    testWidgets('shows three sections: Saved, Recently Played, Downloads',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsWidgets);
      expect(find.text('Recently Played'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
    });

    testWidgets('shows empty state for favorites when none saved',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('save favorites'), findsOneWidget);
    });

    testWidgets('shows empty state for recent when none played',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Items you play'), findsOneWidget);
    });

    testWidgets('shows empty state for downloads', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Downloaded content'), findsOneWidget);
    });

    testWidgets('displays saved items when present', (tester) async {
      await tester.pumpWidget(createTestWidget(
        catalogItems: [testItem(id: 'fav-1', title: 'Favorite Story')],
        favoriteIds: ['fav-1'],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Favorite Story'), findsOneWidget);
    });

    testWidgets('displays recent items when present', (tester) async {
      await tester.pumpWidget(createTestWidget(
        catalogItems: [
          testItem(
            id: 'recent-1',
            title: 'Recent Story',
            interests: ['moral'],
            language: 'english',
            availableVoices: ['female_warm'],
            defaultVoice: 'female_warm',
          ),
        ],
        recentIds: ['recent-1'],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Recent Story'), findsOneWidget);
    });

    testWidgets('caps saved list at 5 with expandable See all',
        (tester) async {
      final items = List.generate(
          7, (i) => testItem(id: 'fav-$i', title: 'Story $i'));
      await tester.pumpWidget(createTestWidget(
        catalogItems: items,
        favoriteIds: items.map((it) => it.id).toList(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Story 4'), findsOneWidget);
      expect(find.text('Story 6'), findsNothing);

      await tester.scrollUntilVisible(find.text('See all 7 saved'), 100,
          scrollable: find.byType(Scrollable).first);
      // Nudge further so the button is fully inside the viewport.
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See all 7 saved'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Story 6'), 100,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Story 6'), findsOneWidget);
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('has ListView for scrolling', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('LibraryScreen Icons', () {
    testWidgets('shows section icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
    });
  });
}
