/// Remote configuration service for feature flags and dynamic settings.
///
/// Uses Firebase Remote Config when enabled, otherwise falls back to defaults.
/// Provides feature flags, force update configuration, and A/B testing support.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';

/// Remote configuration keys.
class RemoteConfigKeys {
  static const String minAppVersion = 'min_app_version';
  static const String forceUpdateEnabled = 'force_update_enabled';
  static const String maintenanceMode = 'maintenance_mode';
  static const String maintenanceMessage = 'maintenance_message';
  static const String adsEnabled = 'ads_enabled';
  static const String premiumPrice = 'premium_price';
  static const String maxOfflineItems = 'max_offline_items';
  static const String dailyPushEnabled = 'daily_push_enabled';
  static const String referralEnabled = 'referral_enabled';
  static const String voiceSearchEnabled = 'voice_search_enabled';
  static const String parentalControlsEnabled = 'parental_controls_enabled';
}

/// Remote configuration values.
class RemoteConfig {
  final String minAppVersion;
  final bool forceUpdateEnabled;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool adsEnabled;
  final String premiumPrice;
  final int maxOfflineItems;
  final bool dailyPushEnabled;
  final bool referralEnabled;
  final bool voiceSearchEnabled;
  final bool parentalControlsEnabled;

  const RemoteConfig({
    this.minAppVersion = '1.0.0',
    this.forceUpdateEnabled = false,
    this.maintenanceMode = false,
    this.maintenanceMessage = 'We\'re performing maintenance. Please try again later.',
    this.adsEnabled = true,
    this.premiumPrice = '₹99/year',
    this.maxOfflineItems = 50,
    this.dailyPushEnabled = true,
    this.referralEnabled = false,
    this.voiceSearchEnabled = true,
    this.parentalControlsEnabled = true,
  });

  RemoteConfig copyWith({
    String? minAppVersion,
    bool? forceUpdateEnabled,
    bool? maintenanceMode,
    String? maintenanceMessage,
    bool? adsEnabled,
    String? premiumPrice,
    int? maxOfflineItems,
    bool? dailyPushEnabled,
    bool? referralEnabled,
    bool? voiceSearchEnabled,
    bool? parentalControlsEnabled,
  }) {
    return RemoteConfig(
      minAppVersion: minAppVersion ?? this.minAppVersion,
      forceUpdateEnabled: forceUpdateEnabled ?? this.forceUpdateEnabled,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      premiumPrice: premiumPrice ?? this.premiumPrice,
      maxOfflineItems: maxOfflineItems ?? this.maxOfflineItems,
      dailyPushEnabled: dailyPushEnabled ?? this.dailyPushEnabled,
      referralEnabled: referralEnabled ?? this.referralEnabled,
      voiceSearchEnabled: voiceSearchEnabled ?? this.voiceSearchEnabled,
      parentalControlsEnabled: parentalControlsEnabled ?? this.parentalControlsEnabled,
    );
  }
}

/// Remote config service interface.
abstract class RemoteConfigService {
  Future<void> init();
  Future<void> fetch();
  RemoteConfig get config;
  bool getBool(String key, {bool defaultValue = false});
  String getString(String key, {String defaultValue = ''});
  int getInt(String key, {int defaultValue = 0});
  double getDouble(String key, {double defaultValue = 0.0});
}

/// Debug implementation using local defaults.
class DebugRemoteConfigService implements RemoteConfigService {
  RemoteConfig _config = const RemoteConfig();

  @override
  RemoteConfig get config => _config;

  @override
  Future<void> init() async {
    debugPrint('[RemoteConfig] Debug service initialized with defaults');
  }

  @override
  Future<void> fetch() async {
    debugPrint('[RemoteConfig] Fetch called (no-op in debug mode)');
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    switch (key) {
      case RemoteConfigKeys.forceUpdateEnabled:
        return _config.forceUpdateEnabled;
      case RemoteConfigKeys.maintenanceMode:
        return _config.maintenanceMode;
      case RemoteConfigKeys.adsEnabled:
        return _config.adsEnabled;
      case RemoteConfigKeys.dailyPushEnabled:
        return _config.dailyPushEnabled;
      case RemoteConfigKeys.referralEnabled:
        return _config.referralEnabled;
      case RemoteConfigKeys.voiceSearchEnabled:
        return _config.voiceSearchEnabled;
      case RemoteConfigKeys.parentalControlsEnabled:
        return _config.parentalControlsEnabled;
      default:
        return defaultValue;
    }
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    switch (key) {
      case RemoteConfigKeys.minAppVersion:
        return _config.minAppVersion;
      case RemoteConfigKeys.maintenanceMessage:
        return _config.maintenanceMessage;
      case RemoteConfigKeys.premiumPrice:
        return _config.premiumPrice;
      default:
        return defaultValue;
    }
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    switch (key) {
      case RemoteConfigKeys.maxOfflineItems:
        return _config.maxOfflineItems;
      default:
        return defaultValue;
    }
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    return defaultValue;
  }
}

/// Remote config provider.
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  // TODO: Return FirebaseRemoteConfigService when USE_REMOTE_CONFIG is true
  return DebugRemoteConfigService();
});

/// Remote config values provider.
final remoteConfigProvider = Provider<RemoteConfig>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.config;
});
