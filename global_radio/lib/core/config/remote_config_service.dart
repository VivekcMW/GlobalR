/// Remote configuration service for feature flags and dynamic settings.
///
/// Uses Firebase Remote Config when enabled, otherwise falls back to defaults.
/// Provides feature flags, force update configuration, and A/B testing support.
library;

import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart' as frc;
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
  static const String adsMidrollEveryNItems = 'ads_midroll_every_n_items';
  static const String adsMidrollMinGapMinutes = 'ads_midroll_min_gap_minutes';
  static const String adsMaxPerSession = 'ads_max_per_session';
  static const String adsMaxPerHour = 'ads_max_per_hour';
  static const String adsPrerollEnabled = 'ads_preroll_enabled';
  static const String adsGracePeriodDays = 'ads_grace_period_days';
  static const String adsHouseRatio = 'ads_house_ratio';
  static const String adsBedtimeSuppress = 'ads_bedtime_suppress';
  static const String adsVastTagUrl = 'ads_vast_tag_url';
  static const String sponsoredStationJson = 'sponsored_station_json';
  static const String premiumPrice = 'premium_price';
  static const String maxOfflineItems = 'max_offline_items';
  static const String dailyPushEnabled = 'daily_push_enabled';
  static const String referralEnabled = 'referral_enabled';
  static const String voiceSearchEnabled = 'voice_search_enabled';
  static const String parentalControlsEnabled = 'parental_controls_enabled';
  static const String engageStreakRescueEnabled =
      'engage_streak_rescue_enabled';
  static const String engagePersonalPushEnabled =
      'engage_personal_push_enabled';
  static const String engageMilestonesEnabled = 'engage_milestones_enabled';
  static const String engageMysterySlotEnabled =
      'engage_mystery_slot_enabled';
  static const String engageWeeklyGoalDays = 'engage_weekly_goal_days';
  static const String engageJourneysJson = 'engage_journeys_json';
  static const String listenerCountsJson = 'listener_counts_json';
}

/// Remote configuration values.
class RemoteConfig {
  final String minAppVersion;
  final bool forceUpdateEnabled;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool adsEnabled;
  final int adsMidrollEveryNItems;
  final int adsMidrollMinGapMinutes;
  final int adsMaxPerSession;
  final int adsMaxPerHour;
  final bool adsPrerollEnabled;
  final int adsGracePeriodDays;
  final double adsHouseRatio;
  final bool adsBedtimeSuppress;
  final String adsVastTagUrl;
  final String sponsoredStationJson;
  final String premiumPrice;
  final int maxOfflineItems;
  final bool dailyPushEnabled;
  final bool referralEnabled;
  final bool voiceSearchEnabled;
  final bool parentalControlsEnabled;
  final bool engageStreakRescueEnabled;
  final bool engagePersonalPushEnabled;
  final bool engageMilestonesEnabled;
  final bool engageMysterySlotEnabled;
  final int engageWeeklyGoalDays;
  final String engageJourneysJson;
  final String listenerCountsJson;

  const RemoteConfig({
    this.minAppVersion = '1.0.0',
    this.forceUpdateEnabled = false,
    this.maintenanceMode = false,
    this.maintenanceMessage = 'We\'re performing maintenance. Please try again later.',
    // Ads ship dark: flipped on remotely in the Phase 2 monetization pilot.
    this.adsEnabled = false,
    this.adsMidrollEveryNItems = 4,
    this.adsMidrollMinGapMinutes = 12,
    this.adsMaxPerSession = 6,
    this.adsMaxPerHour = 4,
    this.adsPrerollEnabled = true,
    this.adsGracePeriodDays = 1,
    this.adsHouseRatio = 0.25,
    this.adsBedtimeSuppress = true,
    this.adsVastTagUrl = '',
    this.sponsoredStationJson = '',
    this.premiumPrice = '₹99/year',
    this.maxOfflineItems = 50,
    this.dailyPushEnabled = true,
    this.referralEnabled = false,
    this.voiceSearchEnabled = true,
    this.parentalControlsEnabled = true,
    this.engageStreakRescueEnabled = true,
    this.engagePersonalPushEnabled = true,
    this.engageMilestonesEnabled = true,
    this.engageMysterySlotEnabled = true,
    this.engageWeeklyGoalDays = 5,
    this.engageJourneysJson = '',
    this.listenerCountsJson = '',
  });

  RemoteConfig copyWith({
    String? minAppVersion,
    bool? forceUpdateEnabled,
    bool? maintenanceMode,
    String? maintenanceMessage,
    bool? adsEnabled,
    int? adsMidrollEveryNItems,
    int? adsMidrollMinGapMinutes,
    int? adsMaxPerSession,
    int? adsMaxPerHour,
    bool? adsPrerollEnabled,
    int? adsGracePeriodDays,
    double? adsHouseRatio,
    bool? adsBedtimeSuppress,
    String? adsVastTagUrl,
    String? sponsoredStationJson,
    String? premiumPrice,
    int? maxOfflineItems,
    bool? dailyPushEnabled,
    bool? referralEnabled,
    bool? voiceSearchEnabled,
    bool? parentalControlsEnabled,
    bool? engageStreakRescueEnabled,
    bool? engagePersonalPushEnabled,
    bool? engageMilestonesEnabled,
    bool? engageMysterySlotEnabled,
    int? engageWeeklyGoalDays,
    String? engageJourneysJson,
    String? listenerCountsJson,
  }) {
    return RemoteConfig(
      minAppVersion: minAppVersion ?? this.minAppVersion,
      forceUpdateEnabled: forceUpdateEnabled ?? this.forceUpdateEnabled,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      adsMidrollEveryNItems:
          adsMidrollEveryNItems ?? this.adsMidrollEveryNItems,
      adsMidrollMinGapMinutes:
          adsMidrollMinGapMinutes ?? this.adsMidrollMinGapMinutes,
      adsMaxPerSession: adsMaxPerSession ?? this.adsMaxPerSession,
      adsMaxPerHour: adsMaxPerHour ?? this.adsMaxPerHour,
      adsPrerollEnabled: adsPrerollEnabled ?? this.adsPrerollEnabled,
      adsGracePeriodDays: adsGracePeriodDays ?? this.adsGracePeriodDays,
      adsHouseRatio: adsHouseRatio ?? this.adsHouseRatio,
      adsBedtimeSuppress: adsBedtimeSuppress ?? this.adsBedtimeSuppress,
      adsVastTagUrl: adsVastTagUrl ?? this.adsVastTagUrl,
      sponsoredStationJson: sponsoredStationJson ?? this.sponsoredStationJson,
      premiumPrice: premiumPrice ?? this.premiumPrice,
      maxOfflineItems: maxOfflineItems ?? this.maxOfflineItems,
      dailyPushEnabled: dailyPushEnabled ?? this.dailyPushEnabled,
      referralEnabled: referralEnabled ?? this.referralEnabled,
      voiceSearchEnabled: voiceSearchEnabled ?? this.voiceSearchEnabled,
      parentalControlsEnabled: parentalControlsEnabled ?? this.parentalControlsEnabled,
      engageStreakRescueEnabled:
          engageStreakRescueEnabled ?? this.engageStreakRescueEnabled,
      engagePersonalPushEnabled:
          engagePersonalPushEnabled ?? this.engagePersonalPushEnabled,
      engageMilestonesEnabled:
          engageMilestonesEnabled ?? this.engageMilestonesEnabled,
      engageMysterySlotEnabled:
          engageMysterySlotEnabled ?? this.engageMysterySlotEnabled,
      engageWeeklyGoalDays: engageWeeklyGoalDays ?? this.engageWeeklyGoalDays,
      engageJourneysJson: engageJourneysJson ?? this.engageJourneysJson,
      listenerCountsJson: listenerCountsJson ?? this.listenerCountsJson,
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
      case RemoteConfigKeys.adsPrerollEnabled:
        return _config.adsPrerollEnabled;
      case RemoteConfigKeys.adsBedtimeSuppress:
        return _config.adsBedtimeSuppress;
      case RemoteConfigKeys.dailyPushEnabled:
        return _config.dailyPushEnabled;
      case RemoteConfigKeys.referralEnabled:
        return _config.referralEnabled;
      case RemoteConfigKeys.voiceSearchEnabled:
        return _config.voiceSearchEnabled;
      case RemoteConfigKeys.parentalControlsEnabled:
        return _config.parentalControlsEnabled;
      case RemoteConfigKeys.engageStreakRescueEnabled:
        return _config.engageStreakRescueEnabled;
      case RemoteConfigKeys.engagePersonalPushEnabled:
        return _config.engagePersonalPushEnabled;
      case RemoteConfigKeys.engageMilestonesEnabled:
        return _config.engageMilestonesEnabled;
      case RemoteConfigKeys.engageMysterySlotEnabled:
        return _config.engageMysterySlotEnabled;
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
      case RemoteConfigKeys.adsVastTagUrl:
        return _config.adsVastTagUrl;
      case RemoteConfigKeys.sponsoredStationJson:
        return _config.sponsoredStationJson;
      case RemoteConfigKeys.engageJourneysJson:
        return _config.engageJourneysJson;
      case RemoteConfigKeys.listenerCountsJson:
        return _config.listenerCountsJson;
      default:
        return defaultValue;
    }
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    switch (key) {
      case RemoteConfigKeys.maxOfflineItems:
        return _config.maxOfflineItems;
      case RemoteConfigKeys.adsMidrollEveryNItems:
        return _config.adsMidrollEveryNItems;
      case RemoteConfigKeys.adsMidrollMinGapMinutes:
        return _config.adsMidrollMinGapMinutes;
      case RemoteConfigKeys.adsMaxPerSession:
        return _config.adsMaxPerSession;
      case RemoteConfigKeys.adsMaxPerHour:
        return _config.adsMaxPerHour;
      case RemoteConfigKeys.adsGracePeriodDays:
        return _config.adsGracePeriodDays;
      case RemoteConfigKeys.engageWeeklyGoalDays:
        return _config.engageWeeklyGoalDays;
      default:
        return defaultValue;
    }
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    switch (key) {
      case RemoteConfigKeys.adsHouseRatio:
        return _config.adsHouseRatio;
      default:
        return defaultValue;
    }
  }
}

/// Firebase-backed implementation. Falls back to the compiled-in defaults
/// whenever a fetch fails or a key is missing remotely.
class FirebaseRemoteConfigService extends DebugRemoteConfigService {
  frc.FirebaseRemoteConfig get _remote => frc.FirebaseRemoteConfig.instance;

  @override
  Future<void> init() async {
    const defaults = RemoteConfig();
    try {
      await _remote.setConfigSettings(frc.RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remote.setDefaults({
        RemoteConfigKeys.minAppVersion: defaults.minAppVersion,
        RemoteConfigKeys.forceUpdateEnabled: defaults.forceUpdateEnabled,
        RemoteConfigKeys.maintenanceMode: defaults.maintenanceMode,
        RemoteConfigKeys.maintenanceMessage: defaults.maintenanceMessage,
        RemoteConfigKeys.adsEnabled: defaults.adsEnabled,
        RemoteConfigKeys.adsMidrollEveryNItems: defaults.adsMidrollEveryNItems,
        RemoteConfigKeys.adsMidrollMinGapMinutes:
            defaults.adsMidrollMinGapMinutes,
        RemoteConfigKeys.adsMaxPerSession: defaults.adsMaxPerSession,
        RemoteConfigKeys.adsMaxPerHour: defaults.adsMaxPerHour,
        RemoteConfigKeys.adsPrerollEnabled: defaults.adsPrerollEnabled,
        RemoteConfigKeys.adsGracePeriodDays: defaults.adsGracePeriodDays,
        RemoteConfigKeys.adsHouseRatio: defaults.adsHouseRatio,
        RemoteConfigKeys.adsBedtimeSuppress: defaults.adsBedtimeSuppress,
        RemoteConfigKeys.adsVastTagUrl: defaults.adsVastTagUrl,
        RemoteConfigKeys.sponsoredStationJson: defaults.sponsoredStationJson,
        RemoteConfigKeys.premiumPrice: defaults.premiumPrice,
        RemoteConfigKeys.maxOfflineItems: defaults.maxOfflineItems,
        RemoteConfigKeys.dailyPushEnabled: defaults.dailyPushEnabled,
        RemoteConfigKeys.referralEnabled: defaults.referralEnabled,
        RemoteConfigKeys.voiceSearchEnabled: defaults.voiceSearchEnabled,
        RemoteConfigKeys.parentalControlsEnabled:
            defaults.parentalControlsEnabled,
        RemoteConfigKeys.engageStreakRescueEnabled:
            defaults.engageStreakRescueEnabled,
        RemoteConfigKeys.engagePersonalPushEnabled:
            defaults.engagePersonalPushEnabled,
        RemoteConfigKeys.engageMilestonesEnabled:
            defaults.engageMilestonesEnabled,
        RemoteConfigKeys.engageMysterySlotEnabled:
            defaults.engageMysterySlotEnabled,
        RemoteConfigKeys.engageWeeklyGoalDays: defaults.engageWeeklyGoalDays,
        RemoteConfigKeys.engageJourneysJson: defaults.engageJourneysJson,
        RemoteConfigKeys.listenerCountsJson: defaults.listenerCountsJson,
      });
      await fetch();
    } catch (e) {
      debugPrint('[RemoteConfig] Init failed, using defaults: $e');
    }
  }

  @override
  Future<void> fetch() async {
    try {
      await _remote.fetchAndActivate();
      _config = RemoteConfig(
        minAppVersion: _remote.getString(RemoteConfigKeys.minAppVersion),
        forceUpdateEnabled:
            _remote.getBool(RemoteConfigKeys.forceUpdateEnabled),
        maintenanceMode: _remote.getBool(RemoteConfigKeys.maintenanceMode),
        maintenanceMessage:
            _remote.getString(RemoteConfigKeys.maintenanceMessage),
        adsEnabled: _remote.getBool(RemoteConfigKeys.adsEnabled),
        adsMidrollEveryNItems:
            _remote.getInt(RemoteConfigKeys.adsMidrollEveryNItems),
        adsMidrollMinGapMinutes:
            _remote.getInt(RemoteConfigKeys.adsMidrollMinGapMinutes),
        adsMaxPerSession: _remote.getInt(RemoteConfigKeys.adsMaxPerSession),
        adsMaxPerHour: _remote.getInt(RemoteConfigKeys.adsMaxPerHour),
        adsPrerollEnabled: _remote.getBool(RemoteConfigKeys.adsPrerollEnabled),
        adsGracePeriodDays:
            _remote.getInt(RemoteConfigKeys.adsGracePeriodDays),
        adsHouseRatio: _remote.getDouble(RemoteConfigKeys.adsHouseRatio),
        adsBedtimeSuppress:
            _remote.getBool(RemoteConfigKeys.adsBedtimeSuppress),
        adsVastTagUrl: _remote.getString(RemoteConfigKeys.adsVastTagUrl),
        sponsoredStationJson:
            _remote.getString(RemoteConfigKeys.sponsoredStationJson),
        premiumPrice: _remote.getString(RemoteConfigKeys.premiumPrice),
        maxOfflineItems: _remote.getInt(RemoteConfigKeys.maxOfflineItems),
        dailyPushEnabled: _remote.getBool(RemoteConfigKeys.dailyPushEnabled),
        referralEnabled: _remote.getBool(RemoteConfigKeys.referralEnabled),
        voiceSearchEnabled:
            _remote.getBool(RemoteConfigKeys.voiceSearchEnabled),
        parentalControlsEnabled:
            _remote.getBool(RemoteConfigKeys.parentalControlsEnabled),
        engageStreakRescueEnabled:
            _remote.getBool(RemoteConfigKeys.engageStreakRescueEnabled),
        engagePersonalPushEnabled:
            _remote.getBool(RemoteConfigKeys.engagePersonalPushEnabled),
        engageMilestonesEnabled:
            _remote.getBool(RemoteConfigKeys.engageMilestonesEnabled),
        engageMysterySlotEnabled:
            _remote.getBool(RemoteConfigKeys.engageMysterySlotEnabled),
        engageWeeklyGoalDays:
            _remote.getInt(RemoteConfigKeys.engageWeeklyGoalDays),
        engageJourneysJson:
            _remote.getString(RemoteConfigKeys.engageJourneysJson),
        listenerCountsJson:
            _remote.getString(RemoteConfigKeys.listenerCountsJson),
      );
      debugPrint('[RemoteConfig] Fetched and activated remote values');
    } catch (e) {
      debugPrint('[RemoteConfig] Fetch failed, keeping current values: $e');
    }
  }
}

/// Remote config provider.
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  final service = AppConfig.useRemoteConfig
      ? FirebaseRemoteConfigService()
      : DebugRemoteConfigService();
  // Fire-and-forget: fetch fresh values in the background; consumers keep
  // safe defaults until the fetch completes.
  unawaited(service.init());
  return service;
});

/// Remote config values provider.
final remoteConfigProvider = Provider<RemoteConfig>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.config;
});
