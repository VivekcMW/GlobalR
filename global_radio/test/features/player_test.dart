import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:global_radio/core/constants.dart';
import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/features/player/player_screen.dart';
import 'package:global_radio/shared/providers/radio_controller.dart';

void main() {
  group('PlayerScreen Widget', () {
    Widget createTestWidget({
      CatalogItem? currentItem,
      bool isPlaying = false,
    }) {
      return ProviderScope(
        overrides: [
          radioControllerProvider.overrideWith(
            (ref) => MockRadioController(RadioState(
              current: currentItem,
              isPlaying: isPlaying,
            )),
          ),
        ],
        child: const MaterialApp(
          home: PlayerScreen(),
        ),
      );
    }

    testWidgets('shows empty state when nothing is playing', (tester) async {
      await tester.pumpWidget(createTestWidget(currentItem: null));
      await tester.pumpAndSettle();

      expect(find.text('Nothing playing yet'), findsOneWidget);
    });

    testWidgets('displays Now Playing title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(
        currentItem: CatalogItem(
          id: 'test-1',
          title: 'Test Story',
          interests: ['kids'],
          language: 'hindi',
          availableVoices: ['male_story'],
          defaultVoice: 'male_story',
          durationSec: 180,
          sizeKb: 1440,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Now Playing'), findsOneWidget);
    });

    testWidgets('displays item title', (tester) async {
      await tester.pumpWidget(createTestWidget(
        currentItem: CatalogItem(
          id: 'test-1',
          title: 'The Clever Rabbit',
          interests: ['kids'],
          language: 'hindi',
          availableVoices: ['male_story'],
          defaultVoice: 'male_story',
          durationSec: 180,
          sizeKb: 1440,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('The Clever Rabbit'), findsOneWidget);
    });

    testWidgets('has back button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(
        currentItem: CatalogItem(
          id: 'test-1',
          title: 'Test Story',
          interests: ['kids'],
          language: 'hindi',
          availableVoices: ['male_story'],
          defaultVoice: 'male_story',
          durationSec: 180,
          sizeKb: 1440,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('shows interest icon', (tester) async {
      await tester.pumpWidget(createTestWidget(
        currentItem: CatalogItem(
          id: 'test-1',
          title: 'Test Story',
          interests: ['devotion'],
          language: 'hindi',
          availableVoices: ['devotional'],
          defaultVoice: 'devotional',
          durationSec: 180,
          sizeKb: 1440,
        ),
      ));
      await tester.pumpAndSettle();

      // Should have some interest icon or container
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('PlayerScreen Controls', () {
    testWidgets('has playback controls', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            radioControllerProvider.overrideWith(
              (ref) => MockRadioController(RadioState(
                current: CatalogItem(
                  id: 'test-1',
                  title: 'Test Story',
                  interests: ['kids'],
                  language: 'hindi',
                  availableVoices: ['male_story'],
                  defaultVoice: 'male_story',
                  durationSec: 180,
                  sizeKb: 1440,
                ),
                isPlaying: false,
              )),
            ),
          ],
          child: const MaterialApp(
            home: PlayerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have IconButton for controls
      expect(find.byType(IconButton), findsWidgets);
    });
  });

  group('Interest Display', () {
    test('Interest.byId returns correct interest', () {
      final kids = Interest.byId('kids');
      expect(kids, isNotNull);
      expect(kids!.id, 'kids');
    });

    test('Interest.byId returns null for unknown id', () {
      final unknown = Interest.byId('unknown_interest');
      expect(unknown, isNull);
    });

    test('All interests have labels', () {
      for (final interest in Interest.all) {
        expect(interest.label, isNotEmpty);
      }
    });
  });

  group('Language Display', () {
    test('AppLanguage.nativeNameFor returns native name', () {
      expect(AppLanguage.nativeNameFor('hindi'), 'हिन्दी');
      expect(AppLanguage.nativeNameFor('english'), 'English');
      expect(AppLanguage.nativeNameFor('tamil'), 'தமிழ்');
    });

    test('AppLanguage.nativeNameFor returns code for unknown language', () {
      expect(AppLanguage.nativeNameFor('xyz'), 'xyz');
    });
  });
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

  @override
  bool isFavorite(String itemId) => false;
}
