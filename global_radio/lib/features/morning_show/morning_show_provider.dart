import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import 'morning_show_generator.dart';

export 'morning_show_generator.dart';

/// Provider for generating the daily show based on time of day.
final dailyShowProvider = Provider<SequencedShow?>((ref) {
  final catalogAsync = ref.watch(catalogProvider);
  final profile = ref.watch(profileProvider);
  
  final catalog = catalogAsync.valueOrNull;
  if (catalog == null) return null;
  
  final generator = MorningShowGenerator(
    catalog: catalog.items,
    language: profile.languages.isNotEmpty ? profile.languages.first : 'english',
    userInterests: profile.interests.toSet(),
    userSign: null, // astroSign not yet implemented in profile
  );
  
  return generator.generateShow();
});

/// Provider for the current day segment.
final daySegmentProvider = Provider<DaySegment>((ref) {
  final hour = DateTime.now().hour;
  if (hour >= 4 && hour < 6) return DaySegment.earlyMorning;
  if (hour >= 6 && hour < 10) return DaySegment.morning;
  if (hour >= 10 && hour < 12) return DaySegment.lateMorning;
  if (hour >= 12 && hour < 16) return DaySegment.afternoon;
  if (hour >= 16 && hour < 19) return DaySegment.evening;
  if (hour >= 19 && hour < 22) return DaySegment.night;
  return DaySegment.lateNight;
});

/// Provider for show title based on time of day.
final showTitleProvider = Provider<String>((ref) {
  final segment = ref.watch(daySegmentProvider);
  switch (segment) {
    case DaySegment.earlyMorning:
    case DaySegment.morning:
      return 'Good Morning India';
    case DaySegment.lateMorning:
    case DaySegment.afternoon:
      return 'Afternoon Break';
    case DaySegment.evening:
      return 'Good Evening India';
    case DaySegment.night:
    case DaySegment.lateNight:
      return 'Good Night India';
  }
});

/// Provider for show icon based on time of day.
final showIconProvider = Provider<String>((ref) {
  final segment = ref.watch(daySegmentProvider);
  switch (segment) {
    case DaySegment.earlyMorning:
    case DaySegment.morning:
      return '🌅';
    case DaySegment.lateMorning:
    case DaySegment.afternoon:
      return '☀️';
    case DaySegment.evening:
      return '🌆';
    case DaySegment.night:
    case DaySegment.lateNight:
      return '🌙';
  }
});

/// Controller for playing the daily show.
class DailyShowController {
  final Ref _ref;

  DailyShowController(this._ref);

  /// Play the entire daily show sequence.
  Future<void> playDailyShow() async {
    final show = _ref.read(dailyShowProvider);
    if (show == null) return;
    
    final radioController = _ref.read(radioControllerProvider.notifier);
    
    // Queue all items from all segments
    final items = show.allItems;
    if (items.isEmpty) return;
    
    // Play via radio controller
    await radioController.startRadio(onlyInterests: items.map((i) => i.primaryInterest).toList());
  }

  /// Play a specific segment from the show.
  Future<void> playSegment(ShowSegment segment) async {
    final radioController = _ref.read(radioControllerProvider.notifier);
    
    if (segment.items.isEmpty) return;
    await radioController.startRadio(onlyInterests: segment.items.map((i) => i.primaryInterest).toList());
  }
}

final dailyShowControllerProvider = Provider<DailyShowController>((ref) {
  return DailyShowController(ref);
});
