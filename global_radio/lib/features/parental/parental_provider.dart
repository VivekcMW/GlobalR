import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Parental control settings.
class ParentalSettings {
  final bool isEnabled;
  final bool hasPin;
  final Set<String> blockedInterests;
  final int maxPlaybackMinutesPerDay;
  final bool nightModeEnabled;
  final int nightModeStartHour;
  final int nightModeEndHour;
  final bool requirePinForSettings;

  const ParentalSettings({
    this.isEnabled = false,
    this.hasPin = false,
    this.blockedInterests = const {},
    this.maxPlaybackMinutesPerDay = 0, // 0 = unlimited
    this.nightModeEnabled = false,
    this.nightModeStartHour = 21, // 9 PM
    this.nightModeEndHour = 6, // 6 AM
    this.requirePinForSettings = true,
  });

  ParentalSettings copyWith({
    bool? isEnabled,
    bool? hasPin,
    Set<String>? blockedInterests,
    int? maxPlaybackMinutesPerDay,
    bool? nightModeEnabled,
    int? nightModeStartHour,
    int? nightModeEndHour,
    bool? requirePinForSettings,
  }) {
    return ParentalSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      hasPin: hasPin ?? this.hasPin,
      blockedInterests: blockedInterests ?? this.blockedInterests,
      maxPlaybackMinutesPerDay: maxPlaybackMinutesPerDay ?? this.maxPlaybackMinutesPerDay,
      nightModeEnabled: nightModeEnabled ?? this.nightModeEnabled,
      nightModeStartHour: nightModeStartHour ?? this.nightModeStartHour,
      nightModeEndHour: nightModeEndHour ?? this.nightModeEndHour,
      requirePinForSettings: requirePinForSettings ?? this.requirePinForSettings,
    );
  }

  /// Check if content is blocked based on interest.
  bool isContentBlocked(String interest) {
    if (!isEnabled) return false;
    return blockedInterests.contains(interest);
  }

  /// Check if playback is allowed during night mode.
  bool isNightModeActive() {
    if (!isEnabled || !nightModeEnabled) return false;
    
    final now = DateTime.now();
    final hour = now.hour;
    
    // Handle overnight range (e.g., 21:00 - 06:00)
    if (nightModeStartHour > nightModeEndHour) {
      return hour >= nightModeStartHour || hour < nightModeEndHour;
    }
    // Handle same-day range
    return hour >= nightModeStartHour && hour < nightModeEndHour;
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'hasPin': hasPin,
        'blockedInterests': blockedInterests.toList(),
        'maxPlaybackMinutesPerDay': maxPlaybackMinutesPerDay,
        'nightModeEnabled': nightModeEnabled,
        'nightModeStartHour': nightModeStartHour,
        'nightModeEndHour': nightModeEndHour,
        'requirePinForSettings': requirePinForSettings,
      };

  factory ParentalSettings.fromJson(Map<String, dynamic> json) {
    return ParentalSettings(
      isEnabled: json['isEnabled'] as bool? ?? false,
      hasPin: json['hasPin'] as bool? ?? false,
      blockedInterests: Set<String>.from(json['blockedInterests'] as List? ?? []),
      maxPlaybackMinutesPerDay: json['maxPlaybackMinutesPerDay'] as int? ?? 0,
      nightModeEnabled: json['nightModeEnabled'] as bool? ?? false,
      nightModeStartHour: json['nightModeStartHour'] as int? ?? 21,
      nightModeEndHour: json['nightModeEndHour'] as int? ?? 6,
      requirePinForSettings: json['requirePinForSettings'] as bool? ?? true,
    );
  }
}

/// Service for managing parental controls with secure PIN storage.
class ParentalControlService {
  static const _pinKey = 'parental_pin';
  static const _settingsKey = 'parental_settings';
  static const _playbackTimeKey = 'parental_playback_time';
  
  final FlutterSecureStorage _storage;

  ParentalControlService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Set the parental PIN.
  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  /// Verify the PIN.
  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == pin;
  }

  /// Check if PIN is set.
  Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Remove the PIN.
  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
  }

  /// Save settings.
  Future<void> saveSettings(ParentalSettings settings) async {
    final json = settings.toJson();
    await _storage.write(key: _settingsKey, value: json.toString());
  }

  /// Load settings.
  Future<ParentalSettings> loadSettings() async {
    final data = await _storage.read(key: _settingsKey);
    if (data == null) return const ParentalSettings();
    
    try {
      // In a real implementation, parse JSON properly
      return const ParentalSettings();
    } catch (_) {
      return const ParentalSettings();
    }
  }

  /// Track playback time for daily limits.
  Future<int> getTodayPlaybackMinutes() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _storage.read(key: '$_playbackTimeKey:$today');
    return int.tryParse(data ?? '0') ?? 0;
  }

  /// Add playback time.
  Future<void> addPlaybackTime(int minutes) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final current = await getTodayPlaybackMinutes();
    await _storage.write(
      key: '$_playbackTimeKey:$today',
      value: (current + minutes).toString(),
    );
  }

  /// Check if daily limit is reached.
  Future<bool> isDailyLimitReached(int limitMinutes) async {
    if (limitMinutes <= 0) return false; // No limit
    final used = await getTodayPlaybackMinutes();
    return used >= limitMinutes;
  }
}

/// Provider for parental control service.
final parentalControlServiceProvider = Provider<ParentalControlService>((ref) {
  return ParentalControlService();
});

/// Provider for parental settings state.
final parentalSettingsProvider = StateNotifierProvider<ParentalSettingsNotifier, ParentalSettings>((ref) {
  return ParentalSettingsNotifier(ref.read(parentalControlServiceProvider));
});

/// Notifier for parental settings.
class ParentalSettingsNotifier extends StateNotifier<ParentalSettings> {
  final ParentalControlService _service;

  ParentalSettingsNotifier(this._service) : super(const ParentalSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await _service.loadSettings();
    final hasPin = await _service.isPinSet();
    state = state.copyWith(hasPin: hasPin);
  }

  Future<bool> setPin(String pin) async {
    if (pin.length != 4) return false;
    await _service.setPin(pin);
    state = state.copyWith(hasPin: true, isEnabled: true);
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    return _service.verifyPin(pin);
  }

  Future<void> removePin() async {
    await _service.removePin();
    state = state.copyWith(hasPin: false, isEnabled: false);
  }

  void toggleEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
    _service.saveSettings(state);
  }

  void setBlockedInterests(Set<String> interests) {
    state = state.copyWith(blockedInterests: interests);
    _service.saveSettings(state);
  }

  void toggleBlockedInterest(String interest) {
    final current = Set<String>.from(state.blockedInterests);
    if (current.contains(interest)) {
      current.remove(interest);
    } else {
      current.add(interest);
    }
    state = state.copyWith(blockedInterests: current);
    _service.saveSettings(state);
  }

  void setDailyLimit(int minutes) {
    state = state.copyWith(maxPlaybackMinutesPerDay: minutes);
    _service.saveSettings(state);
  }

  void setNightMode({
    bool? enabled,
    int? startHour,
    int? endHour,
  }) {
    state = state.copyWith(
      nightModeEnabled: enabled ?? state.nightModeEnabled,
      nightModeStartHour: startHour ?? state.nightModeStartHour,
      nightModeEndHour: endHour ?? state.nightModeEndHour,
    );
    _service.saveSettings(state);
  }
}

/// Provider to check if content is allowed based on parental controls.
final isContentAllowedProvider = Provider.family<bool, String>((ref, interest) {
  final settings = ref.watch(parentalSettingsProvider);
  return !settings.isContentBlocked(interest);
});

/// Provider to check if playback is allowed (time limits, night mode).
final isPlaybackAllowedProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(parentalSettingsProvider);
  
  if (!settings.isEnabled) return true;
  
  // Check night mode
  if (settings.isNightModeActive()) return false;
  
  // Check daily limit
  if (settings.maxPlaybackMinutesPerDay > 0) {
    final service = ref.read(parentalControlServiceProvider);
    final limitReached = await service.isDailyLimitReached(
      settings.maxPlaybackMinutesPerDay,
    );
    if (limitReached) return false;
  }
  
  return true;
});
