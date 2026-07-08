import 'package:flutter_test/flutter_test.dart';

import 'package:global_radio/core/constants.dart';
import 'package:global_radio/shared/providers/radio_controller.dart';

import '../helpers/fake_controllers.dart';

/// Note: PlayerScreen widget tests require a real [GlobalRadioAudioHandler]
/// (seek bar / speed / transport read its streams), which needs platform
/// channels not available in widget tests. The screen is covered by the
/// on-simulator integration flow; the pure logic around it is tested here.
void main() {
  group('RadioState', () {
    test('current returns item at currentIndex', () {
      final state = RadioState(
        queue: [testItem(id: 'a'), testItem(id: 'b')],
        currentIndex: 1,
      );
      expect(state.current!.id, 'b');
    });

    test('current is null for empty queue', () {
      expect(const RadioState().current, isNull);
    });

    test('current is null when index out of range', () {
      final state = RadioState(queue: [testItem()], currentIndex: 5);
      expect(state.current, isNull);
    });

    test('copyWith preserves unset fields', () {
      final state = RadioState(
        queue: [testItem()],
        currentIndex: 0,
        isPlaying: true,
      );
      final copy = state.copyWith(isPlaying: false);
      expect(copy.queue, state.queue);
      expect(copy.currentIndex, 0);
      expect(copy.isPlaying, isFalse);
    });
  });

  group('Interest Display', () {
    test('Interest.byId returns correct interest', () {
      final kids = Interest.byId('kids');
      expect(kids, isNotNull);
      expect(kids!.id, 'kids');
    });

    test('Interest.byId returns null for unknown id', () {
      expect(Interest.byId('unknown_interest'), isNull);
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

  group('CatalogItem voice resolution', () {
    test('resolvedVoice prefers the user voice when available', () {
      final item = testItem(availableVoices: ['male_story', 'female_warm']);
      expect(item.resolvedVoice('female_warm'), 'female_warm');
    });

    test('resolvedVoice falls back to default voice', () {
      final item = testItem(
          availableVoices: ['male_story'], defaultVoice: 'male_story');
      expect(item.resolvedVoice('devotional'), 'male_story');
    });
  });
}
