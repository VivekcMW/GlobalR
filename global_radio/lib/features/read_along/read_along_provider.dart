import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants.dart';
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

  void toggleShowTranslation() {
    state = state.copyWith(showTranslation: !state.showTranslation);
  }
}

/// In-memory transcript cache (session-scoped); null entries mean the CDN
/// has no transcript for that item, so we don't refetch.
final _transcriptCache = <String, SyncedTranscript?>{};

/// Provider for the transcript of the current item.
///
/// Transcripts follow the CDN convention
/// `{cdnBase}/transcripts/{language}/{itemId}.json` and are optional —
/// read-along is simply unavailable when the file doesn't exist.
final currentTranscriptProvider = FutureProvider<SyncedTranscript?>((ref) async {
  final radioState = ref.watch(radioControllerProvider);
  final currentItem = radioState.current;
  if (currentItem == null) return null;

  if (_transcriptCache.containsKey(currentItem.id)) {
    return _transcriptCache[currentItem.id];
  }

  SyncedTranscript? transcript;
  try {
    final url =
        '${AppConfig.cdnBase}/transcripts/${currentItem.language}/${currentItem.id}.json';
    final response = await Dio().get<Map<String, dynamic>>(
      url,
      options: Options(
        responseType: ResponseType.json,
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );
    final data = response.data;
    if (data != null) {
      transcript = SyncedTranscript.fromJson(data);
    }
  } catch (_) {
    // 404 / offline / malformed — read-along unavailable for this item.
    transcript = null;
  }

  _transcriptCache[currentItem.id] = transcript;
  return transcript;
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

  final position = positionAsync.value ?? Duration.zero;

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

  final position = positionAsync.value ?? Duration.zero;

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

  final position = positionAsync.value ?? Duration.zero;

  return transcriptAsync.maybeWhen(
    data: (transcript) {
      if (transcript == null) return 0.0;
      return transcript.progressAtPosition(position);
    },
    orElse: () => 0.0,
  );
});
