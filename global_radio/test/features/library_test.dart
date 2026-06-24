import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/features/library/library_screen.dart';
import 'package:global_radio/shared/providers/providers.dart';

void main() {
  group('LibraryScreen Widget', () {
    late GoRouter testRouter;

    setUp(() {
      testRouter = GoRouter(
        initialLocation: '/library',
        routes: [
          GoRoute(
            path: '/library',
            builder: (_, __) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/player',
            builder: (_, __) => const Scaffold(body: Text('Player')),
          ),
        ],
      );
    });

    Widget createTestWidget({
      List<CatalogItem> catalogItems = const [],
      List<String> favoriteIds = const [],
      List<String> recentIds = const [],
    }) {
      return ProviderScope(
        overrides: [
          catalogProvider.overrideWith(
            (ref) => AsyncValue.data(MockCatalog(items: catalogItems)),
          ),
          favoritesProvider.overrideWith(
            (ref) => favoriteIds.map((id) => FavoriteSignal(itemId: id)).toList(),
          ),
          recentlyPlayedProvider.overrideWith(
            (ref) => recentIds.map((id) => RecentSignal(itemId: id)).toList(),
          ),
        ],
        child: MaterialApp.router(routerConfig: testRouter),
      );
    }

    testWidgets('displays Saved title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsWidgets); // AppBar + Section
    });

    testWidgets('shows three sections: Saved, Recently Played, Downloads', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsWidgets);
      expect(find.text('Recently Played'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
    });

    testWidgets('shows empty state for favorites when none saved', (tester) async {
      await tester.pumpWidget(createTestWidget(favoriteIds: []));
      await tester.pumpAndSettle();

      expect(find.textContaining('save favorites'), findsOneWidget);
    });

    testWidgets('shows empty state for recent when none played', (tester) async {
      await tester.pumpWidget(createTestWidget(recentIds: []));
      await tester.pumpAndSettle();

      expect(find.textContaining('Items you play'), findsOneWidget);
    });

    testWidgets('shows empty state for downloads', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Downloaded content'), findsOneWidget);
    });

    testWidgets('displays saved items when present', (tester) async {
      final items = [
        CatalogItem(
          id: 'fav-1',
          title: 'Favorite Story',
          interests: ['kids'],
          language: 'hindi',
          availableVoices: ['male_story'],
          defaultVoice: 'male_story',
          durationSec: 180,
          sizeKb: 1440,
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        catalogItems: items,
        favoriteIds: ['fav-1'],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Favorite Story'), findsOneWidget);
    });

    testWidgets('displays recent items when present', (tester) async {
      final items = [
        CatalogItem(
          id: 'recent-1',
          title: 'Recent Story',
          interests: ['moral'],
          language: 'english',
          availableVoices: ['female_warm'],
          defaultVoice: 'female_warm',
          durationSec: 240,
          sizeKb: 1920,
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        catalogItems: items,
        recentIds: ['recent-1'],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Recent Story'), findsOneWidget);
    });

    testWidgets('has ListView for scrolling', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('LibraryScreen Icons', () {
    testWidgets('shows bookmark icon for Saved section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogProvider.overrideWith(
              (ref) => AsyncValue.data(MockCatalog(items: [])),
            ),
            favoritesProvider.overrideWith((ref) => []),
            recentlyPlayedProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: LibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('shows history icon for Recently Played section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogProvider.overrideWith(
              (ref) => AsyncValue.data(MockCatalog(items: [])),
            ),
            favoritesProvider.overrideWith((ref) => []),
            recentlyPlayedProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: LibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('shows download icon for Downloads section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogProvider.overrideWith(
              (ref) => AsyncValue.data(MockCatalog(items: [])),
            ),
            favoritesProvider.overrideWith((ref) => []),
            recentlyPlayedProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: LibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
    });
  });
}

/// Mock catalog for testing.
class MockCatalog {
  final List<CatalogItem> items;

  MockCatalog({required this.items});
}

/// Mock favorite signal for testing.
class FavoriteSignal {
  final String itemId;
  final DateTime timestamp;

  FavoriteSignal({required this.itemId, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

/// Mock recent signal for testing.
class RecentSignal {
  final String itemId;
  final DateTime timestamp;

  RecentSignal({required this.itemId, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}
