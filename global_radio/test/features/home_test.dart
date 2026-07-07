import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/data/models/user_profile.dart';
import 'package:global_radio/features/home/home_screen.dart';
import 'package:global_radio/shared/providers/providers.dart';
import 'package:global_radio/shared/providers/radio_controller.dart';

import '../helpers/fake_controllers.dart';

void main() {
  group('HomeScreen Widget', () {
    late GoRouter testRouter;

    setUp(() {
      testRouter = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/player',
            builder: (_, __) => const Scaffold(body: Text('Player')),
          ),
        ],
      );
    });

    Widget createTestWidget({
      required UserProfile profile,
      required Catalog catalog,
      RadioState? radioState,
    }) {
      return ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(FakeLocalStore()),
          profileProvider.overrideWith(() => FakeProfileController(profile)),
          catalogProvider.overrideWith(() => FakeCatalogController(catalog)),
          radioControllerProvider
              .overrideWith(() => FakeRadioController(radioState)),
        ],
        child: MaterialApp.router(routerConfig: testRouter),
      );
    }

    testWidgets('displays app name when user has no name', (tester) async {
      await tester.pumpWidget(createTestWidget(
        profile: const UserProfile(languages: ['hindi'], interests: ['kids']),
        catalog: testCatalog([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Global Radio'), findsOneWidget);
    });

    testWidgets('displays greeting with user name', (tester) async {
      await tester.pumpWidget(createTestWidget(
        profile: const UserProfile(
          name: 'Test User',
          languages: ['hindi'],
          interests: ['kids'],
        ),
        catalog: testCatalog([]),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Namaste'), findsOneWidget);
      expect(find.textContaining('Test User'), findsOneWidget);
    });

    testWidgets('shows loading indicator when catalog is loading',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(FakeLocalStore()),
            profileProvider.overrideWith(() => FakeProfileController(
                const UserProfile(languages: ['hindi'], interests: ['kids']))),
            catalogProvider.overrideWith(FakeCatalogController.loading),
            radioControllerProvider.overrideWith(FakeRadioController.new),
          ],
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error when catalog fails to load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(FakeLocalStore()),
            profileProvider.overrideWith(() => FakeProfileController(
                const UserProfile(languages: ['hindi'], interests: ['kids']))),
            catalogProvider.overrideWith(
                () => FakeCatalogController.error('Network error')),
            radioControllerProvider.overrideWith(FakeRadioController.new),
          ],
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not load catalog'), findsOneWidget);
    });

    testWidgets('displays Your Stations section with interest counts',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        profile: const UserProfile(
          languages: ['hindi'],
          interests: ['kids', 'moral'],
        ),
        catalog: testCatalog([testItem(id: 'test-1', title: 'Test Story')]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Stations'), findsOneWidget);
      // One station card per interest (other home cards may also use Card).
      expect(find.text('Kids'), findsOneWidget);
      expect(find.text('Moral Stories'), findsOneWidget);
    });
  });

  group('HomeScreen Navigation', () {
    testWidgets('tapping a station starts radio and opens player',
        (tester) async {
      final fakeRadio = FakeRadioController();
      final testRouter = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/player',
            builder: (_, __) => const Scaffold(body: Text('Player')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(FakeLocalStore()),
            profileProvider.overrideWith(() => FakeProfileController(
                const UserProfile(languages: ['hindi'], interests: ['kids']))),
            catalogProvider.overrideWith(() =>
                FakeCatalogController(testCatalog([testItem()]))),
            radioControllerProvider.overrideWith(() => fakeRadio),
          ],
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(fakeRadio.calls, contains('startRadio'));
      expect(find.text('Player'), findsOneWidget);
    });
  });
}
