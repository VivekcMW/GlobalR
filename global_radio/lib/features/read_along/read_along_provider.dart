import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import 'read_along_models.dart';

export 'read_along_models.dart';

/// Provider for read-along settings.
final readAlongSettingsProvider =
    StateNotifierProvider<ReadAlongSettingsNotifier, ReadAlongSettings>((ref) {
  return ReadAlongSettingsNotifier();
});

class ReadAlongSettingsNotifier extends StateNotifier<ReadAlongSettings> {
  ReadAlongSettingsNotifier() : super(const ReadAlongSettings());

  void setHighlightMode(HighlightMode mode) {
    state = state.copyWith(highlightMode: mode);
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size.clamp(12, 32));
  }

  void increaseFontSize() {
    state = state.copyWith(fontSize: (state.fontSize + 2).clamp(12, 32));
  }

  void decreaseFontSize() {
    state = state.copyWith(fontSize: (state.fontSize - 2).clamp(12, 32));
  }

  void toggleAutoScroll() {
    state = state.copyWith(autoScroll: !state.autoScroll);
  }

  void toggleShowProgress() {
    state = state.copyWith(showProgress: !state.showProgress);
  }
}

/// Provider for the transcript of the current item.
/// Note: Transcript sync is a premium feature and requires server-side support.
/// This provider returns null until transcript integration is implemented.
final currentTranscriptProvider = FutureProvider<SyncedTranscript?>((ref) async {
  final radioState = ref.watch(radioControllerProvider);
  final currentItem = radioState.current;
  if (currentItem == null) return null;

  // TODO: Implement transcript loading from backend or local cache.
  // For now, read-along feature is not available without transcript data.
  return null;
});

/// Provider for playback position stream.
/// Uses the audio handler's position stream converted to a StreamProvider.
final playbackPositionStreamProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionStream;
});

/// Provider for the current segment index based on playback position.
final currentSegmentIndexProvider = Provider<int?>((ref) {
  final transcriptAsync = ref.watch(currentTranscriptProvider);
  final positionAsync = ref.watch(playbackPositionStreamProvider);

  final position = positionAsync.valueOrNull ?? Duration.zero;

  return transcriptAsync.whenOrNull(
    data: (transcript) {
      if (transcript == null) return null;
      return transcript.segmentIndexAtPosition(position);
    },
  );
});

/// Provider for the current text segment.
final currentSegmentProvider = Provider<TextSegment?>((ref) {
  final transcriptAsync = ref.watch(currentTranscriptProvider);
  final positionAsync = ref.watch(playbackPositionStreamProvider);

  final position = positionAsync.valueOrNull ?? Duration.zero;

  return transcriptAsync.whenOrNull(
    data: (transcript) {
      if (transcript == null) return null;
      return transcript.segmentAtPosition(position);
    },
  );
});

/// Provider to check if read-along is available for current item.
final isReadAlongAvailableProvider = Provider<bool>((ref) {
  final transcriptAsync = ref.watch(currentTranscriptProvider);
  return transcriptAsync.maybeWhen(
    data: (transcript) => transcript != null,
    orElse: () => false,
  );
});

/// Provider for transcript progress (0.0 - 1.0).
final transcriptProgressProvider = Provider<double>((ref) {
  final transcriptAsync = ref.watch(currentTranscriptProvider);
  final positionAsync = ref.watch(playbackPositionStreamProvider);

  final position = positionAsync.valueOrNull ?? Duration.zero;

  return transcriptAsync.maybeWhen(
    data: (transcript) {
      if (transcript == null) return 0.0;
      return transcript.progressAtPosition(position);
    },
    orElse: () => 0.0,
  );
});
