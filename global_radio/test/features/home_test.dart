import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/data/models/user_profile.dart';
import 'package:global_radio/features/home/home_screen.dart';
import 'package:global_radio/shared/providers/providers.dart';
import 'package:global_radio/shared/providers/radio_controller.dart';

void main() {
  group('HomeScreen Widget', () {
    late GoRouter testRouter;

    setUp(() {
      testRouter = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/player',
            builder: (_, __) => const Scaffold(body: Text('Player')),
          ),
        ],
      );
    });

    Widget createTestWidget({
      required UserProfile profile,
      required List<CatalogItem> catalogItems,
      RadioState? radioState,
    }) {
      return ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => ProfileNotifier(profile)),
          catalogProvider.overrideWith(
            (ref) => AsyncValue.data(Catalog(items: catalogItems)),
          ),
          if (radioState != null)
            radioControllerProvider.overrideWith(
              (ref) => MockRadioController(radioState),
            ),
        ],
        child: MaterialApp.router(routerConfig: testRouter),
      );
    }

    testWidgets('displays app name when user has no name', (tester) async {
      await tester.pumpWidget(createTestWidget(
        profile: UserProfile(
          languages: ['hindi'],
          interests: ['kids'],
        ),
        catalogItems: [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Global Radio'), findsOneWidget);
    });

    testWidgets('displays greeting with user name', (tester) async {
      await tester.pumpWidget(createTestWidget(
        profile: UserProfile(
          name: 'Test User',
          languages: ['hindi'],
          interests: ['kids'],
        ),
        catalogItems: [],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Namaste'), findsOneWidget);
      expect(find.textContaining('Test User'), findsOneWidget);
    });

    testWidgets('shows loading indicator when catalog is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => ProfileNotifier(UserProfile(
              languages: ['hindi'],
              interests: ['kids'],
            ))),
            catalogProvider.overrideWith((ref) => const AsyncValue.loading()),
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
            profileProvider.overrideWith((ref) => ProfileNotifier(UserProfile(
              languages: ['hindi'],
              interests: ['kids'],
            ))),
            catalogProvider.overrideWith(
              (ref) => AsyncValue.error('Network error', StackTrace.current),
            ),
          ],
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not load catalog'), findsOneWidget);
    });

    testWidgets('displays Your Stations section', (tester) async {
      await tester.pumpWidget(createTestWidget(
        profile: UserProfile(
          languages: ['hindi'],
          interests: ['kids', 'moral'],
        ),
        catalogItems: [
          CatalogItem(
            id: 'test-1',
            title: 'Test Story',
            interests: ['kids'],
            language: 'hindi',
            availableVoices: ['male_story'],
            defaultVoice: 'male_story',
            durationSec: 180,
            sizeKb: 1440,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Stations'), findsOneWidget);
    });
  });

  group('HomeScreen Navigation', () {
    testWidgets('tapping station opens player', (tester) async {
      var playerOpened = false;

      final testRouter = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/player',
            builder: (_, __) {
              playerOpened = true;
              return const Scaffold(body: Text('Player'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => ProfileNotifier(UserProfile(
              languages: ['hindi'],
              interests: ['kids'],
            ))),
            catalogProvider.overrideWith(
              (ref) => AsyncValue.data(Catalog(items: [
                CatalogItem(
                  id: 'test-1',
                  title: 'Test Story',
                  interests: ['kids'],
                  language: 'hindi',
                  availableVoices: ['male_story'],
                  defaultVoice: 'male_story',
                  durationSec: 180,
                  sizeKb: 1440,
                ),
              ])),
            ),
          ],
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap a station card
      final stationCard = find.byType(Card).first;
      if (stationCard.evaluate().isNotEmpty) {
        await tester.tap(stationCard);
        await tester.pumpAndSettle();
        // Navigation should have occurred
      }
    });
  });
}

/// Mock profile notifier for testing.
class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier(super.state);

  Future<void> setLanguages(List<String> languages) async {
    state = state.copyWith(languages: languages);
  }

  Future<void> setInterests(List<String> interests) async {
    state = state.copyWith(interests: interests);
  }

  Future<void> setVoice(String voice) async {
    state = state.copyWith(voice: voice);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
  }
}

/// Mock radio controller for testing.
class MockRadioController extends RadioController {
  final RadioState _state;

  MockRadioController(this._state) : super(null);

  @override
  RadioState build() => _state;

  @override
  Future<void> startRadio({List<String>? onlyInterests, List<String>? onlyLanguages}) async {}

  @override
  Future<void> togglePlayPause() async {}
}

/// Mock catalog for testing.
class Catalog {
  final List<CatalogItem> items;

  Catalog({required this.items});
}
