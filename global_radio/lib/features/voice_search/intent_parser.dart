import 'voice_search_service.dart';

/// Parsed voice command intent.
sealed class VoiceIntent {}

/// Play content by search query.
class PlayIntent extends VoiceIntent {
  final String query;
  final String? interest;
  final String? language;
  
  PlayIntent({
    required this.query,
    this.interest,
    this.language,
  });
  
  @override
  String toString() => 'PlayIntent(query: $query, interest: $interest, language: $language)';
}

/// Search for content.
class SearchIntent extends VoiceIntent {
  final String query;
  
  SearchIntent(this.query);
  
  @override
  String toString() => 'SearchIntent(query: $query)';
}

/// Control playback (play, pause, stop, next, previous).
class ControlIntent extends VoiceIntent {
  final ControlAction action;
  
  ControlIntent(this.action);
  
  @override
  String toString() => 'ControlIntent(action: $action)';
}

enum ControlAction { play, pause, stop, next, previous, repeat, shuffle }

/// Adjust volume or speed.
class AdjustIntent extends VoiceIntent {
  final AdjustType type;
  final double? value;
  final bool increase;
  
  AdjustIntent({
    required this.type,
    this.value,
    this.increase = true,
  });
  
  @override
  String toString() => 'AdjustIntent(type: $type, value: $value, increase: $increase)';
}

enum AdjustType { volume, speed }

/// Play a specific interest category.
class InterestIntent extends VoiceIntent {
  final String interest;
  final String? modifier; // "today's", "morning", etc.
  
  InterestIntent(this.interest, {this.modifier});
  
  @override
  String toString() => 'InterestIntent(interest: $interest, modifier: $modifier)';
}

/// Set a timer.
class TimerIntent extends VoiceIntent {
  final int minutes;
  
  TimerIntent(this.minutes);
  
  @override
  String toString() => 'TimerIntent(minutes: $minutes)';
}

/// Unknown or unrecognized intent.
class UnknownIntent extends VoiceIntent {
  final String transcript;
  
  UnknownIntent(this.transcript);
  
  @override
  String toString() => 'UnknownIntent(transcript: $transcript)';
}

/// Parses voice transcripts into structured intents.
class IntentParser {
  /// Parse a transcript into an intent.
  static VoiceIntent parse(String transcript, VoiceLanguage language) {
    final text = transcript.toLowerCase().trim();
    
    // Try Hindi patterns first if Hindi, otherwise English
    if (language == VoiceLanguage.hindi) {
      final intent = _parseHindi(text);
      if (intent != null) return intent;
    }
    
    // Try English patterns (also works for Hinglish)
    final intent = _parseEnglish(text);
    if (intent != null) return intent;
    
    // Default to search
    if (text.isNotEmpty) {
      return SearchIntent(transcript);
    }
    
    return UnknownIntent(transcript);
  }
  
  static VoiceIntent? _parseHindi(String text) {
    // Control commands - Hindi
    if (_matches(text, ['रुको', 'रुक जाओ', 'बंद करो', 'स्टॉप'])) {
      return ControlIntent(ControlAction.stop);
    }
    if (_matches(text, ['चलाओ', 'प्ले करो', 'शुरू करो', 'बजाओ'])) {
      return ControlIntent(ControlAction.play);
    }
    if (_matches(text, ['रोको', 'पॉज करो', 'थामो'])) {
      return ControlIntent(ControlAction.pause);
    }
    if (_matches(text, ['अगला', 'नेक्स्ट', 'आगे'])) {
      return ControlIntent(ControlAction.next);
    }
    if (_matches(text, ['पिछला', 'पीछे', 'प्रीवियस'])) {
      return ControlIntent(ControlAction.previous);
    }
    
    // Interest categories - Hindi
    if (_contains(text, ['राशिफल', 'राशि', 'ज्योतिष', 'कुंडली'])) {
      final modifier = _extractModifier(text, ['आज का', 'आज की', 'कल का']);
      return InterestIntent('astrology', modifier: modifier);
    }
    if (_contains(text, ['भजन', 'आरती', 'चालीसा', 'भक्ति', 'पूजा'])) {
      return InterestIntent('devotion');
    }
    if (_contains(text, ['कहानी', 'कथा', 'किस्सा', 'बच्चों की'])) {
      if (_contains(text, ['बच्चों', 'बच्चे'])) {
        return InterestIntent('kids');
      }
      return InterestIntent('moral');
    }
    if (_contains(text, ['समाचार', 'खबर', 'न्यूज़'])) {
      return InterestIntent('news');
    }
    
    // Timer - Hindi
    final timerMatch = RegExp(r'(\d+)\s*(मिनट|घंटा|घंटे)').firstMatch(text);
    if (timerMatch != null && _contains(text, ['टाइमर', 'सोने', 'स्लीप'])) {
      int minutes = int.parse(timerMatch.group(1)!);
      if (_contains(text, ['घंटा', 'घंटे'])) {
        minutes *= 60;
      }
      return TimerIntent(minutes);
    }
    
    // Play specific content - Hindi
    if (text.startsWith('सुनाओ') || text.startsWith('बजाओ')) {
      final query = text.replaceFirst(RegExp(r'^(सुनाओ|बजाओ)\s*'), '');
      if (query.isNotEmpty) {
        return PlayIntent(query: query);
      }
    }
    
    return null;
  }
  
  static VoiceIntent? _parseEnglish(String text) {
    // Control commands - English
    if (_matches(text, ['stop', 'stop it', 'stop playing'])) {
      return ControlIntent(ControlAction.stop);
    }
    if (_matches(text, ['play', 'resume', 'start', 'continue'])) {
      return ControlIntent(ControlAction.play);
    }
    if (_matches(text, ['pause', 'hold', 'wait'])) {
      return ControlIntent(ControlAction.pause);
    }
    if (_matches(text, ['next', 'skip', 'next one', 'skip this'])) {
      return ControlIntent(ControlAction.next);
    }
    if (_matches(text, ['previous', 'go back', 'back', 'last one'])) {
      return ControlIntent(ControlAction.previous);
    }
    if (_matches(text, ['repeat', 'again', 'replay', 'one more time'])) {
      return ControlIntent(ControlAction.repeat);
    }
    if (_matches(text, ['shuffle', 'mix', 'random'])) {
      return ControlIntent(ControlAction.shuffle);
    }
    
    // Volume/Speed - English
    if (_contains(text, ['volume'])) {
      if (_contains(text, ['up', 'increase', 'louder', 'higher'])) {
        return AdjustIntent(type: AdjustType.volume, increase: true);
      }
      if (_contains(text, ['down', 'decrease', 'lower', 'softer'])) {
        return AdjustIntent(type: AdjustType.volume, increase: false);
      }
    }
    if (_contains(text, ['speed', 'faster', 'slower'])) {
      if (_contains(text, ['faster', 'increase', 'up'])) {
        return AdjustIntent(type: AdjustType.speed, increase: true);
      }
      if (_contains(text, ['slower', 'decrease', 'down'])) {
        return AdjustIntent(type: AdjustType.speed, increase: false);
      }
    }
    
    // Interest categories - English
    if (_contains(text, ['horoscope', 'astrology', 'zodiac', 'rashi', 'rashifal'])) {
      final modifier = _extractModifier(text, ["today's", 'today', 'daily', 'morning']);
      return InterestIntent('astrology', modifier: modifier);
    }
    if (_contains(text, ['bhajan', 'devotional', 'prayer', 'aarti', 'chalisa', 'mantra'])) {
      return InterestIntent('devotion');
    }
    if (_contains(text, ['story', 'stories', 'tale', 'moral'])) {
      if (_contains(text, ['kids', 'children', 'child'])) {
        return InterestIntent('kids');
      }
      return InterestIntent('moral');
    }
    if (_contains(text, ['news', 'headlines', 'bulletin'])) {
      return InterestIntent('news');
    }
    if (_contains(text, ['poem', 'poetry', 'kavita', 'shayari', 'ghazal'])) {
      return InterestIntent('poems');
    }
    if (_contains(text, ['health', 'fitness', 'yoga', 'exercise', 'wellness'])) {
      return InterestIntent('health');
    }
    
    // Timer - English
    final timerMatch = RegExp(r'(\d+)\s*(minute|minutes|hour|hours|min|mins|hr|hrs)').firstMatch(text);
    if (timerMatch != null && _contains(text, ['timer', 'sleep', 'set'])) {
      int minutes = int.parse(timerMatch.group(1)!);
      if (_contains(text, ['hour', 'hours', 'hr', 'hrs'])) {
        minutes *= 60;
      }
      return TimerIntent(minutes);
    }
    
    // Play specific content - English
    if (text.startsWith('play ')) {
      final query = text.substring(5).trim();
      if (query.isNotEmpty) {
        // Check if it's an interest
        for (final interest in ['astrology', 'devotion', 'kids', 'moral', 'news']) {
          if (query.contains(interest)) {
            return InterestIntent(interest);
          }
        }
        return PlayIntent(query: query);
      }
    }
    
    // Search - English
    if (text.startsWith('search ') || text.startsWith('find ') || text.startsWith('look for ')) {
      final query = text.replaceFirst(RegExp(r'^(search|find|look for)\s+'), '');
      if (query.isNotEmpty) {
        return SearchIntent(query);
      }
    }
    
    return null;
  }
  
  static bool _matches(String text, List<String> patterns) {
    return patterns.any((p) => text == p || text.startsWith('$p '));
  }
  
  static bool _contains(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
  
  static String? _extractModifier(String text, List<String> modifiers) {
    for (final mod in modifiers) {
      if (text.contains(mod)) {
        return mod;
      }
    }
    return null;
  }
}
