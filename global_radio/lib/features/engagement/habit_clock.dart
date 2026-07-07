/// Habit clock: learns *when* the listener usually opens the radio, entirely
/// on-device. We keep a rolling window of recent session-start hours and use
/// the median as the "habitual hour" for the personal daily nudge.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';

class HabitClock {
  static const storeKey = 'session_start_hours';
  static const maxSamples = 28;
  static const minSamples = 3;

  /// Append [hour] (0-23) to the rolling sample window.
  static List<int> addSample(List<int> samples, int hour) {
    final next = [...samples, hour.clamp(0, 23)];
    if (next.length > maxSamples) {
      next.removeRange(0, next.length - maxSamples);
    }
    return next;
  }

  /// Median session-start hour, or null when we have too few samples to be
  /// confident (< [minSamples]).
  static int? habitHour(List<int> samples) {
    if (samples.length < minSamples) return null;
    final sorted = [...samples]..sort();
    return sorted[sorted.length ~/ 2];
  }
}

/// Records session starts and exposes the learned habitual hour.
class HabitClockController {
  HabitClockController(this._ref);
  final Ref _ref;

  List<int> _load() {
    final raw = _ref
        .read(localStoreProvider)
        .getSetting<List<dynamic>>(HabitClock.storeKey);
    return raw?.whereType<num>().map((n) => n.toInt()).toList() ?? const [];
  }

  Future<void> recordSessionStart(DateTime now) async {
    final samples = HabitClock.addSample(_load(), now.hour);
    await _ref.read(localStoreProvider).putSetting(HabitClock.storeKey, samples);
  }

  int? get habitHour => HabitClock.habitHour(_load());
}

final habitClockProvider =
    Provider<HabitClockController>((ref) => HabitClockController(ref));
