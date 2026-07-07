import 'dart:convert';

import 'package:dio/dio.dart';
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

/// Parses a VTT file content into a SyncedTranscript.
SyncedTranscript? _parseVtt(String vttContent, String itemId) {
  final lines = vttContent.split('\n');
  final segments = <TextSegment>[];
  int index = 0;

  Duration? currentStart;
  Duration? currentEnd;
  final textBuffer = StringBuffer();

  Duration parseTime(String time) {
    final parts = time.trim().split(':');
    if (parts.length == 3) {
      final secParts = parts[2].split('.');
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(secParts[0]),
        milliseconds: secParts.length > 1 ? int.parse(secParts[1]) : 0,
      );
    } else if (parts.length == 2) {
      final secParts = parts[1].split('.');
      return Duration(
        minutes: int.parse(parts[0]),
        seconds: int.parse(secParts[0]),
        milliseconds: secParts.length > 1 ? int.parse(secParts[1]) : 0,
      );
    }
    return Duration.zero;
  }

  for (var line in lines) {
    line = line.trim();
    if (line == 'WEBVTT') continue;

    if (line.isEmpty) {
      if (currentStart != null && textBuffer.isNotEmpty) {
        segments.add(TextSegment(
          index: index++,
          text: textBuffer.toString().trim(),
          startTime: currentStart!,
          endTime: currentEnd ?? currentStart! + const Duration(seconds: 2),
        ));
        textBuffer.clear();
        currentStart = null;
        currentEnd = null;
      }
      continue;
    }

    if (line.contains('-->')) {
      final times = line.split('-->');
      currentStart = parseTime(times[0]);
      currentEnd = parseTime(times[1]);
      textBuffer.clear();
    } else if (currentStart != null) {
      if (textBuffer.isNotEmpty) textBuffer.write(' ');
      textBuffer.write(line);
    }
  }

  if (currentStart != null && textBuffer.isNotEmpty) {
    segments.add(TextSegment(
      index: index++,
      text: textBuffer.toString().trim(),
      startTime: currentStart!,
      endTime: currentEnd ?? currentStart! + const Duration(seconds: 2),
    ));
  }

  if (segments.isEmpty) return null;

  return SyncedTranscript(
    itemId: itemId,
    language: 'en',
    segments: segments,
    fullText: segments.map((s) => s.text).join(' '),
    totalDuration: segments.last.endTime,
  );
}

/// Provider for the transcript of the current item.
final currentTranscriptProvider = FutureProvider<SyncedTranscript?>((ref) async {
  final radioState = ref.watch(radioControllerProvider);
  final currentItem = radioState.current;
  if (currentItem == null) return null;

  try {
    final dio = Dio();
    final audioId = currentItem.id;
    final url = 'https://api.globalradio.app/transcripts/$audioId.vtt';
    
    final response = await dio.get<String>(url);
    if (response.statusCode == 200 && response.data != null) {
      try {
        final json = jsonDecode(response.data!);
        return SyncedTranscript.fromJson(json);
      } catch (_) {
        return _parseVtt(response.data!, audioId);
      }
    }
  } catch (e) {
    // Return null if transcript not available or network error
    return null;
  }
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
