import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'intent_parser.dart';

/// Supported languages for voice recognition.
enum VoiceLanguage {
  hindi('hi_IN', 'Hindi'),
  english('en_IN', 'English'),
  tamil('ta_IN', 'Tamil'),
  telugu('te_IN', 'Telugu'),
  kannada('kn_IN', 'Kannada'),
  malayalam('ml_IN', 'Malayalam'),
  marathi('mr_IN', 'Marathi'),
  gujarati('gu_IN', 'Gujarati'),
  bengali('bn_IN', 'Bengali');

  final String localeId;
  final String displayName;

  const VoiceLanguage(this.localeId, this.displayName);

  static VoiceLanguage fromLanguageCode(String code) {
    return VoiceLanguage.values.firstWhere(
      (v) => v.localeId.startsWith(code),
      orElse: () => VoiceLanguage.hindi,
    );
  }
}

/// Voice search result states.
sealed class VoiceSearchState {}

class VoiceSearchIdle extends VoiceSearchState {}

class VoiceSearchListening extends VoiceSearchState {
  final String partialResult;
  VoiceSearchListening({this.partialResult = ''});
}

class VoiceSearchProcessing extends VoiceSearchState {
  final String transcript;
  VoiceSearchProcessing(this.transcript);
}

class VoiceSearchResult extends VoiceSearchState {
  final String transcript;
  final VoiceIntent intent;
  VoiceSearchResult(this.transcript, this.intent);
}

class VoiceSearchError extends VoiceSearchState {
  final String message;
  VoiceSearchError(this.message);
}

/// Service for voice recognition.
class VoiceSearchService {
  final SpeechToText _speech;
  final StreamController<VoiceSearchState> _stateController;
  VoiceLanguage _language;
  bool _isInitialized = false;

  VoiceSearchService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText(),
        _stateController = StreamController<VoiceSearchState>.broadcast(),
        _language = VoiceLanguage.hindi;

  /// Stream of voice search states.
  Stream<VoiceSearchState> get stateStream => _stateController.stream;

  /// Current state.
  VoiceSearchState get currentState => _lastState;
  VoiceSearchState _lastState = VoiceSearchIdle();

  /// Whether speech recognition is available.
  bool get isAvailable => _isInitialized && _speech.isAvailable;

  /// Whether currently listening.
  bool get isListening => _speech.isListening;

  /// Current language setting.
  VoiceLanguage get language => _language;

  void _setState(VoiceSearchState state) {
    _lastState = state;
    _stateController.add(state);
  }

  /// Initialize the speech recognition service.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      return _isInitialized;
    } catch (e) {
      _setState(VoiceSearchError('Failed to initialize: $e'));
      return false;
    }
  }

  /// Set the language for voice recognition.
  void setLanguage(VoiceLanguage language) {
    _language = language;
  }

  /// Get available locales.
  Future<List<VoiceLanguage>> getAvailableLanguages() async {
    if (!_isInitialized) return [];

    final locales = await _speech.locales();
    final available = <VoiceLanguage>[];

    for (final lang in VoiceLanguage.values) {
      if (locales.any((l) => l.localeId.startsWith(lang.localeId.split('_')[0]))) {
        available.add(lang);
      }
    }

    return available.isEmpty ? [VoiceLanguage.english] : available;
  }

  /// Start listening for voice input.
  Future<void> startListening() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (_speech.isListening) {
      await _speech.stop();
    }

    _setState(VoiceSearchListening());

    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: _language.localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );
    } catch (e) {
      _setState(VoiceSearchError('Failed to start listening: $e'));
    }
  }

  /// Stop listening.
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Cancel listening.
  Future<void> cancel() async {
    await _speech.cancel();
    _setState(VoiceSearchIdle());
  }

  void _onResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      final transcript = result.recognizedWords;
      _setState(VoiceSearchProcessing(transcript));
      
      // Parse intent
      final intent = IntentParser.parse(transcript, _language);
      _setState(VoiceSearchResult(transcript, intent));
    } else {
      _setState(VoiceSearchListening(partialResult: result.recognizedWords));
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      // Only go idle if we're still in listening state (no result received)
      if (_lastState is VoiceSearchListening) {
        final partial = (_lastState as VoiceSearchListening).partialResult;
        if (partial.isEmpty) {
          _setState(VoiceSearchIdle());
        }
      }
    }
  }

  void _onError(dynamic error) {
    _setState(VoiceSearchError(error.toString()));
  }

  /// Dispose resources.
  void dispose() {
    _stateController.close();
    _speech.cancel();
  }
}
