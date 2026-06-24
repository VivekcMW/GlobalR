import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../player/providers/sleep_timer_provider.dart';
import 'intent_parser.dart';
import 'voice_search_service.dart';

export 'intent_parser.dart';
export 'voice_search_service.dart';

/// Provider for the voice search service.
final voiceSearchServiceProvider = Provider<VoiceSearchService>((ref) {
  final service = VoiceSearchService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for voice search state stream.
final voiceSearchStateProvider = StreamProvider<VoiceSearchState>((ref) {
  final service = ref.watch(voiceSearchServiceProvider);
  return service.stateStream;
});

/// Provider for voice search initialization.
final voiceSearchInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(voiceSearchServiceProvider);
  return service.initialize();
});

/// Provider for available voice languages.
final availableVoiceLanguagesProvider = FutureProvider<List<VoiceLanguage>>((ref) async {
  final service = ref.read(voiceSearchServiceProvider);
  await service.initialize();
  return service.getAvailableLanguages();
});

/// Provider for current voice language.
final voiceLanguageProvider = StateProvider<VoiceLanguage>((ref) {
  // Default to profile language
  final profile = ref.watch(profileProvider);
  final language = profile.languages.isNotEmpty ? profile.languages.first : 'english';
  return VoiceLanguage.fromLanguageCode(language);
});

/// Controller for voice search actions.
class VoiceSearchController {
  final Ref _ref;

  VoiceSearchController(this._ref);

  VoiceSearchService get _service => _ref.read(voiceSearchServiceProvider);

  /// Start listening for voice input.
  Future<void> startListening() async {
    final language = _ref.read(voiceLanguageProvider);
    _service.setLanguage(language);
    await _service.startListening();
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _service.stopListening();
  }

  /// Cancel voice search.
  Future<void> cancel() async {
    await _service.cancel();
  }

  /// Execute an intent.
  Future<void> executeIntent(VoiceIntent intent) async {
    switch (intent) {
      case ControlIntent(:final action):
        await _executeControl(action);
        
      case InterestIntent(:final interest, :final modifier):
        await _playInterest(interest, modifier);
        
      case PlayIntent(:final query, :final interest, :final language):
        await _playSearch(query, interest: interest, language: language);
        
      case SearchIntent(:final query):
        await _search(query);
        
      case TimerIntent(:final minutes):
        await _setTimer(minutes);
        
      case AdjustIntent(:final type, :final increase):
        await _adjust(type, increase);
        
      case UnknownIntent():
        // Do nothing or show error
        break;
    }
  }

  Future<void> _executeControl(ControlAction action) async {
    final audioHandler = _ref.read(audioHandlerProvider);
    
    switch (action) {
      case ControlAction.play:
        await audioHandler.play();
      case ControlAction.pause:
        await audioHandler.pause();
      case ControlAction.stop:
        await audioHandler.stop();
      case ControlAction.next:
        await audioHandler.skipToNext();
      case ControlAction.previous:
        await audioHandler.skipToPrevious();
      case ControlAction.repeat:
        // Set repeat mode
        break;
      case ControlAction.shuffle:
        // Toggle shuffle
        break;
    }
  }

  Future<void> _playInterest(String interest, String? modifier) async {
    final radioController = _ref.read(radioControllerProvider.notifier);
    
    // Get items for this interest
    final catalogAsync = _ref.read(catalogProvider);
    final catalog = catalogAsync.valueOrNull;
    if (catalog == null) return;
    
    final items = catalog.items.where((item) => item.primaryInterest == interest).toList();
    
    if (items.isNotEmpty) {
      // If modifier is "today's" for astrology, filter for today
      if (modifier != null && interest == 'astrology') {
        final today = DateTime.now();
        final todayItems = items.where((item) {
          final published = item.publishedDate;
          return published != null &&
              published.year == today.year &&
              published.month == today.month &&
              published.day == today.day;
        }).toList();
        
        if (todayItems.isNotEmpty) {
          await radioController.startRadio(onlyInterests: [interest]);
          return;
        }
      }
      
      // Play items for this interest
      await radioController.startRadio(onlyInterests: [interest]);
    }
  }

  Future<void> _playSearch(String query, {String? interest, String? language}) async {
    final catalogAsync = _ref.read(catalogProvider);
    final catalog = catalogAsync.valueOrNull;
    if (catalog == null) return;
    
    // Simple search - find items matching query
    final matches = catalog.items.where((item) {
      final titleMatch = item.title.toLowerCase().contains(query.toLowerCase());
      final interestMatch = interest == null || item.primaryInterest == interest;
      final langMatch = language == null || item.language == language;
      return titleMatch && interestMatch && langMatch;
    }).toList();
    
    if (matches.isNotEmpty) {
      final radioController = _ref.read(radioControllerProvider.notifier);
      await radioController.startRadio(onlyInterests: [matches.first.primaryInterest]);
    }
  }

  Future<void> _search(String query) async {
    // Navigate to search screen with query
    // This would typically update a search provider
  }

  Future<void> _setTimer(int minutes) async {
    final sleepTimer = _ref.read(sleepTimerProvider.notifier);
    // Find closest SleepOption
    final option = switch (minutes) {
      <= 15 => SleepOption.min15,
      <= 30 => SleepOption.min30,
      <= 45 => SleepOption.min45,
      <= 60 => SleepOption.min60,
      _ => SleepOption.min90,
    };
    sleepTimer.start(option);
  }

  Future<void> _adjust(AdjustType type, bool increase) async {
    switch (type) {
      case AdjustType.volume:
        // Adjust system volume - platform specific
        break;
        
      case AdjustType.speed:
        final audioHandler = _ref.read(audioHandlerProvider);
        final currentSpeed = audioHandler.speed;
        final newSpeed = increase
            ? (currentSpeed + 0.25).clamp(0.5, 2.0)
            : (currentSpeed - 0.25).clamp(0.5, 2.0);
        await audioHandler.setSpeed(newSpeed);
    }
  }
}

/// Provider for voice search controller.
final voiceSearchControllerProvider = Provider<VoiceSearchController>((ref) {
  return VoiceSearchController(ref);
});

/// Provider for whether voice search is active.
final isVoiceSearchActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(voiceSearchStateProvider);
  return state.maybeWhen(
    data: (s) => s is VoiceSearchListening || s is VoiceSearchProcessing,
    orElse: () => false,
  );
});
