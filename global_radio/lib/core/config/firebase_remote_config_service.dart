/// Firebase Remote Config implementation.
///
/// Active only when USE_REMOTE_CONFIG=true. Requires Firebase to be configured.
library;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'remote_config_service.dart';

/// Firebase Remote Config implementation.
class FirebaseRemoteConfigService implements RemoteConfigService {
  late final FirebaseRemoteConfig _remoteConfig;
  RemoteConfig _config = const RemoteConfig();

  @override
  RemoteConfig get config => _config;

  @override
  Future<void> init() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: kDebugMode
          ? const Duration(minutes: 5)
          : const Duration(hours: 12),
    ));

    // Set default values
    await _remoteConfig.setDefaults({
      RemoteConfigKeys.minAppVersion: '1.0.0',
      RemoteConfigKeys.forceUpdateEnabled: false,
      RemoteConfigKeys.maintenanceMode: false,
      RemoteConfigKeys.maintenanceMessage: 'We\'re performing maintenance. Please try again later.',
      RemoteConfigKeys.adsEnabled: true,
      RemoteConfigKeys.premiumPrice: '₹99/year',
      RemoteConfigKeys.maxOfflineItems: 50,
      RemoteConfigKeys.dailyPushEnabled: true,
      RemoteConfigKeys.referralEnabled: false,
      RemoteConfigKeys.voiceSearchEnabled: true,
      RemoteConfigKeys.parentalControlsEnabled: true,
    });

    // Fetch and activate
    try {
      await _remoteConfig.fetchAndActivate();
      _updateConfig();
    } catch (e) {
      debugPrint('[RemoteConfig] Fetch failed: $e');
    }
  }

  @override
  Future<void> fetch() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _updateConfig();
    } catch (e) {
      debugPrint('[RemoteConfig] Fetch failed: $e');
    }
  }

  void _updateConfig() {
    _config = RemoteConfig(
      minAppVersion: getString(RemoteConfigKeys.minAppVersion, defaultValue: '1.0.0'),
      forceUpdateEnabled: getBool(RemoteConfigKeys.forceUpdateEnabled),
      maintenanceMode: getBool(RemoteConfigKeys.maintenanceMode),
      maintenanceMessage: getString(RemoteConfigKeys.maintenanceMessage, 
          defaultValue: 'We\'re performing maintenance. Please try again later.'),
      adsEnabled: getBool(RemoteConfigKeys.adsEnabled, defaultValue: true),
      premiumPrice: getString(RemoteConfigKeys.premiumPrice, defaultValue: '₹99/year'),
      maxOfflineItems: getInt(RemoteConfigKeys.maxOfflineItems, defaultValue: 50),
      dailyPushEnabled: getBool(RemoteConfigKeys.dailyPushEnabled, defaultValue: true),
      referralEnabled: getBool(RemoteConfigKeys.referralEnabled),
      voiceSearchEnabled: getBool(RemoteConfigKeys.voiceSearchEnabled, defaultValue: true),
      parentalControlsEnabled: getBool(RemoteConfigKeys.parentalControlsEnabled, defaultValue: true),
    );
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return _remoteConfig.getBool(key);
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    final value = _remoteConfig.getString(key);
    return value.isEmpty ? defaultValue : value;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    return _remoteConfig.getInt(key);
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _remoteConfig.getDouble(key);
  }
}
