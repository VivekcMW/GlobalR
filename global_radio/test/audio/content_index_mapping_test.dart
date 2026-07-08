import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/audio/audio_handler.dart';

void main() {
  group('contentIndexForAdIndices (player index → content index)', () {
    test('identity mapping when there are no ads', () {
      for (var i = 0; i < 5; i++) {
        expect(
            GlobalRadioAudioHandler.contentIndexForAdIndices(i, {}), i);
      }
    });

    test('returns null for ad slots', () {
      expect(
          GlobalRadioAudioHandler.contentIndexForAdIndices(0, {0}), isNull);
      expect(
          GlobalRadioAudioHandler.contentIndexForAdIndices(3, {1, 3}), isNull);
    });

    test('pre-roll ad shifts all content down by one', () {
      // Player queue: [ad, c0, c1, c2]
      const ads = {0};
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(1, ads), 0);
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(2, ads), 1);
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(3, ads), 2);
    });

    test('mid-roll ad only shifts items after it', () {
      // Player queue: [c0, c1, ad, c2, c3]
      const ads = {2};
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(0, ads), 0);
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(1, ads), 1);
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(3, ads), 2);
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(4, ads), 3);
    });

    test('multiple ads accumulate offsets', () {
      // Player queue: [ad, c0, ad, c1, c2, ad, c3]
      const ads = {0, 2, 5};
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(1, ads), 0);
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(3, ads), 1);
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(4, ads), 2);
      expect(GlobalRadioAudioHandler.contentIndexForAdIndices(6, ads), 3);
    });
  });
}
