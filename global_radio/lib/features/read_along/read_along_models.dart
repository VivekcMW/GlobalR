import 'dart:convert';

/// A single timed segment of text for read-along sync.
class TextSegment {
  final int index;
  final String text;
  final Duration startTime;
  final Duration endTime;
  final bool isParagraphStart;

  const TextSegment({
    required this.index,
    required this.text,
    required this.startTime,
    required this.endTime,
    this.isParagraphStart = false,
  });

  bool containsPosition(Duration position) {
    return position >= startTime && position < endTime;
  }

  factory TextSegment.fromJson(Map<String, dynamic> json) {
    return TextSegment(
      index: json['index'] as int,
      text: json['text'] as String,
      startTime: Duration(milliseconds: json['startMs'] as int),
      endTime: Duration(milliseconds: json['endMs'] as int),
      isParagraphStart: json['isParagraphStart'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'text': text,
        'startMs': startTime.inMilliseconds,
        'endMs': endTime.inMilliseconds,
        'isParagraphStart': isParagraphStart,
      };
}

/// Complete transcript with timing information.
class SyncedTranscript {
  final String itemId;
  final String language;
  final List<TextSegment> segments;
  final String fullText;
  final Duration totalDuration;

  const SyncedTranscript({
    required this.itemId,
    required this.language,
    required this.segments,
    required this.fullText,
    required this.totalDuration,
  });

  /// Find the segment at a given position.
  TextSegment? segmentAtPosition(Duration position) {
    for (final segment in segments) {
      if (segment.containsPosition(position)) {
        return segment;
      }
    }
    return null;
  }

  /// Find the segment index at a given position.
  int? segmentIndexAtPosition(Duration position) {
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].containsPosition(position)) {
        return i;
      }
    }
    return null;
  }

  /// Get progress through the transcript (0.0 - 1.0).
  double progressAtPosition(Duration position) {
    if (totalDuration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / totalDuration.inMilliseconds;
  }

  /// Get all text up to and including the current position.
  String textUpToPosition(Duration position) {
    final buffer = StringBuffer();
    for (final segment in segments) {
      if (segment.startTime <= position) {
        if (segment.isParagraphStart && buffer.isNotEmpty) {
          buffer.write('\n\n');
        } else if (buffer.isNotEmpty) {
          buffer.write(' ');
        }
        buffer.write(segment.text);
      } else {
        break;
      }
    }
    return buffer.toString();
  }

  factory SyncedTranscript.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as List<dynamic>;
    return SyncedTranscript(
      itemId: json['itemId'] as String,
      language: json['language'] as String,
      segments: segmentsJson
          .map((s) => TextSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      fullText: json['fullText'] as String,
      totalDuration: Duration(milliseconds: json['durationMs'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'language': language,
        'segments': segments.map((s) => s.toJson()).toList(),
        'fullText': fullText,
        'durationMs': totalDuration.inMilliseconds,
      };

  /// Generate a simple transcript from plain text (for items without timing data).
  /// Estimates timing based on average reading speed.
  factory SyncedTranscript.fromPlainText({
    required String itemId,
    required String language,
    required String text,
    required Duration audioDuration,
  }) {
    final sentences = _splitIntoSentences(text);
    final segments = <TextSegment>[];

    if (sentences.isEmpty) {
      return SyncedTranscript(
        itemId: itemId,
        language: language,
        segments: [],
        fullText: text,
        totalDuration: audioDuration,
      );
    }

    // Calculate time per character
    final totalChars = sentences.fold<int>(0, (sum, s) => sum + s.length);
    final msPerChar = audioDuration.inMilliseconds / totalChars;

    var currentMs = 0;
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final sentenceDuration = (sentence.length * msPerChar).round();

      segments.add(TextSegment(
        index: i,
        text: sentence,
        startTime: Duration(milliseconds: currentMs),
        endTime: Duration(milliseconds: currentMs + sentenceDuration),
        isParagraphStart: i == 0 || sentences[i - 1].endsWith('\n'),
      ));

      currentMs += sentenceDuration;
    }

    return SyncedTranscript(
      itemId: itemId,
      language: language,
      segments: segments,
      fullText: text,
      totalDuration: audioDuration,
    );
  }

  static List<String> _splitIntoSentences(String text) {
    // Split on sentence-ending punctuation
    final sentences = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);

      // Check for sentence end
      if (char == '.' || char == '!' || char == '?' || char == '।' || char == '॥') {
        // Make sure it's not an abbreviation
        final sentence = buffer.toString().trim();
        if (sentence.isNotEmpty) {
          sentences.add(sentence);
          buffer.clear();
        }
      }
    }

    // Add remaining text
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      sentences.add(remaining);
    }

    return sentences;
  }
}

/// Highlight mode for read-along display.
enum HighlightMode {
  /// Highlight only the current word/segment
  word,

  /// Highlight the current sentence
  sentence,

  /// Karaoke style - dim past text, highlight current, show upcoming
  karaoke,
}

/// Reading along display settings.
class ReadAlongSettings {
  final HighlightMode highlightMode;
  final double fontSize;
  final bool autoScroll;
  final double lineSpacing;
  final bool showProgress;

  const ReadAlongSettings({
    this.highlightMode = HighlightMode.karaoke,
    this.fontSize = 18,
    this.autoScroll = true,
    this.lineSpacing = 1.5,
    this.showProgress = true,
  });

  ReadAlongSettings copyWith({
    HighlightMode? highlightMode,
    double? fontSize,
    bool? autoScroll,
    double? lineSpacing,
    bool? showProgress,
  }) {
    return ReadAlongSettings(
      highlightMode: highlightMode ?? this.highlightMode,
      fontSize: fontSize ?? this.fontSize,
      autoScroll: autoScroll ?? this.autoScroll,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      showProgress: showProgress ?? this.showProgress,
    );
  }
}
