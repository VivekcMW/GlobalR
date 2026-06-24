import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/audio_handler.dart';
import '../../../shared/providers/providers.dart';

/// Sleep timer options in minutes (0 = disabled, -1 = end of episode).
enum SleepOption {
  off(0, 'Off'),
  min15(15, '15 minutes'),
  min30(30, '30 minutes'),
  min45(45, '45 minutes'),
  min60(60, '60 minutes'),
  min90(90, '90 minutes'),
  endOfEpisode(-1, 'End of episode');

  final int minutes;
  final String label;
  const SleepOption(this.minutes, this.label);
}

/// State for the sleep timer.
class SleepTimerState {
  final SleepOption option;
  final Duration? remaining;
  final bool isFading;

  const SleepTimerState({
    this.option = SleepOption.off,
    this.remaining,
    this.isFading = false,
  });

  bool get isActive => option != SleepOption.off && remaining != null;

  SleepTimerState copyWith({
    SleepOption? option,
    Duration? remaining,
    bool? isFading,
    bool clearRemaining = false,
  }) =>
      SleepTimerState(
        option: option ?? this.option,
        remaining: clearRemaining ? null : (remaining ?? this.remaining),
        isFading: isFading ?? this.isFading,
      );
}

/// Controls the sleep timer countdown and audio fade-out.
class SleepTimerController extends Notifier<SleepTimerState> {
  Timer? _timer;
  Timer? _fadeTimer;

  GlobalRadioAudioHandler get _handler => ref.read(audioHandlerProvider);

  @override
  SleepTimerState build() {
    ref.onDispose(_dispose);
    return const SleepTimerState();
  }

  void _dispose() {
    _timer?.cancel();
    _fadeTimer?.cancel();
  }

  /// Start a sleep timer with the given option.
  void start(SleepOption option) {
    _timer?.cancel();
    _fadeTimer?.cancel();

    if (option == SleepOption.off) {
      state = const SleepTimerState();
      return;
    }

    if (option == SleepOption.endOfEpisode) {
      // Will be triggered by onComplete in RadioController
      state = SleepTimerState(option: option, remaining: null);
      return;
    }

    final duration = Duration(minutes: option.minutes);
    state = SleepTimerState(option: option, remaining: duration);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remaining;
      if (remaining == null) return;

      final newRemaining = remaining - const Duration(seconds: 1);
      if (newRemaining <= Duration.zero) {
        _startFadeOut();
      } else if (newRemaining <= const Duration(seconds: 30) && !state.isFading) {
        _startFadeOut();
      } else {
        state = state.copyWith(remaining: newRemaining);
      }
    });
  }

  /// Called when current episode completes (for "end of episode" mode).
  void onEpisodeComplete() {
    if (state.option == SleepOption.endOfEpisode) {
      _startFadeOut();
    }
  }

  void _startFadeOut() {
    state = state.copyWith(isFading: true);
    _timer?.cancel();

    // Fade volume over 10 seconds then stop
    const fadeSteps = 10;
    var step = 0;
    
    _fadeTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      step++;
      final volume = 1.0 - (step / fadeSteps);
      
      if (step >= fadeSteps) {
        timer.cancel();
        await _handler.pause();
        // Reset volume for next play
        state = const SleepTimerState();
      } else {
        state = state.copyWith(
          remaining: Duration(seconds: fadeSteps - step),
        );
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    state = const SleepTimerState();
  }

  String formatRemaining() {
    final r = state.remaining;
    if (r == null) {
      return state.option == SleepOption.endOfEpisode
          ? 'Until episode ends'
          : '';
    }
    final mins = r.inMinutes;
    final secs = r.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerController, SleepTimerState>(
        SleepTimerController.new);
