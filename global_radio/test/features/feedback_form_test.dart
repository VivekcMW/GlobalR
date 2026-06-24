import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/features/settings/feedback_screen.dart';

void main() {
  group('FeedbackFormState', () {
    test('has correct default values', () {
      const state = FeedbackFormState();

      expect(state.type, FeedbackType.bug);
      expect(state.message, '');
      expect(state.rating, isNull);
      expect(state.includeDeviceInfo, true);
      expect(state.isSubmitting, false);
      expect(state.error, isNull);
    });

    test('copyWith creates a new state with updated values', () {
      const original = FeedbackFormState();
      final updated = original.copyWith(
        type: FeedbackType.feature,
        message: 'Great app!',
        rating: 5,
      );

      expect(updated.type, FeedbackType.feature);
      expect(updated.message, 'Great app!');
      expect(updated.rating, 5);
      expect(updated.includeDeviceInfo, true); // Unchanged
    });

    test('copyWith with null error clears the error', () {
      final stateWithError = const FeedbackFormState().copyWith(
        error: 'Some error',
      );
      expect(stateWithError.error, 'Some error');

      final clearedState = stateWithError.copyWith(error: null);
      expect(clearedState.error, isNull);
    });
  });

  group('FeedbackFormNotifier', () {
    late FeedbackFormNotifier notifier;

    setUp(() {
      notifier = FeedbackFormNotifier();
    });

    test('setType updates the feedback type', () {
      expect(notifier.state.type, FeedbackType.bug);

      notifier.setType(FeedbackType.feature);
      expect(notifier.state.type, FeedbackType.feature);

      notifier.setType(FeedbackType.question);
      expect(notifier.state.type, FeedbackType.question);
    });

    test('setMessage updates the message', () {
      expect(notifier.state.message, '');

      notifier.setMessage('This is my feedback');
      expect(notifier.state.message, 'This is my feedback');
    });

    test('setRating updates the rating', () {
      expect(notifier.state.rating, isNull);

      notifier.setRating(4);
      expect(notifier.state.rating, 4);

      notifier.setRating(5);
      expect(notifier.state.rating, 5);
    });

    test('setIncludeDeviceInfo toggles device info inclusion', () {
      expect(notifier.state.includeDeviceInfo, true);

      notifier.setIncludeDeviceInfo(false);
      expect(notifier.state.includeDeviceInfo, false);

      notifier.setIncludeDeviceInfo(true);
      expect(notifier.state.includeDeviceInfo, true);
    });

    test('reset restores default state', () {
      notifier.setType(FeedbackType.feature);
      notifier.setMessage('Test message');
      notifier.setRating(5);
      notifier.setIncludeDeviceInfo(false);

      notifier.reset();

      expect(notifier.state.type, FeedbackType.bug);
      expect(notifier.state.message, '');
      expect(notifier.state.rating, isNull);
      expect(notifier.state.includeDeviceInfo, true);
    });
  });

  group('FeedbackType', () {
    test('has correct label values', () {
      expect(FeedbackType.bug.label, 'Bug Report');
      expect(FeedbackType.feature.label, 'Feature Request');
      expect(FeedbackType.question.label, 'Question');
      expect(FeedbackType.other.label, 'Other');
    });

    test('values contains all feedback types', () {
      expect(FeedbackType.values.length, 4);
      expect(FeedbackType.values, contains(FeedbackType.bug));
      expect(FeedbackType.values, contains(FeedbackType.feature));
      expect(FeedbackType.values, contains(FeedbackType.question));
      expect(FeedbackType.values, contains(FeedbackType.other));
    });
  });
}
