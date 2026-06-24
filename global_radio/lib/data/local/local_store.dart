import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/item_signals.dart';
import '../models/user_profile.dart';

/// Thin Hive wrapper. Values are JSON-encoded maps, so no generated adapters
/// are needed — keeps the build codegen-free and the schema flexible.
class LocalStore {
  static const _profileBox = 'profile';
  static const _signalsBox = 'signals';
  static const _catalogBox = 'catalog_cache';
  static const _settingsBox = 'settings';

  static const _profileKey = 'me';

  late final Box _profile;
  late final Box _signals;
  late final Box _catalog;
  late final Box _settings;

  Future<void> init() async {
    await Hive.initFlutter();
    _profile = await Hive.openBox(_profileBox);
    _signals = await Hive.openBox(_signalsBox);
    _catalog = await Hive.openBox(_catalogBox);
    _settings = await Hive.openBox(_settingsBox);
  }

  // ---- profile --------------------------------------------------------------

  UserProfile loadProfile() {
    final raw = _profile.get(_profileKey);
    if (raw is String) {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    return const UserProfile();
  }

  Future<void> saveProfile(UserProfile profile) =>
      _profile.put(_profileKey, jsonEncode(profile.toJson()));

  /// Wipe all on-device data (profile + signals + cached catalog). Used by
  /// "Delete account & data".
  Future<void> clearAll() async {
    await _profile.clear();
    await _signals.clear();
    await _catalog.clear();
  }

  // ---- signals --------------------------------------------------------------

  Map<String, ItemSignals> loadAllSignals() {
    final map = <String, ItemSignals>{};
    for (final key in _signals.keys) {
      final raw = _signals.get(key);
      if (raw is String) {
        final s = ItemSignals.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        map[s.itemId] = s;
      }
    }
    return map;
  }

  ItemSignals signalsFor(String itemId) {
    final raw = _signals.get(itemId);
    if (raw is String) {
      return ItemSignals.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    return ItemSignals.empty(itemId);
  }

  Future<void> saveSignals(ItemSignals s) =>
      _signals.put(s.itemId, jsonEncode(s.toJson()));

  List<ItemSignals> favorites() =>
      loadAllSignals().values.where((s) => s.favorited).toList()
        ..sort((a, b) => (b.lastPlayedAt ?? DateTime(0))
            .compareTo(a.lastPlayedAt ?? DateTime(0)));

  List<ItemSignals> recentlyPlayed({int limit = 50}) {
    final played = loadAllSignals()
        .values
        .where((s) => s.lastPlayedAt != null)
        .toList()
      ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
    return played.take(limit).toList();
  }

  // ---- catalog cache --------------------------------------------------------

  String? cachedCatalogJson() => _catalog.get('json') as String?;
  String? cachedCatalogVersion() => _catalog.get('version') as String?;

  Future<void> cacheCatalog(String json, String version) async {
    await _catalog.put('json', json);
    await _catalog.put('version', version);
  }

  // ---- settings / generic key-value storage ---------------------------------

  /// Get a JSON-serializable value from settings storage.
  T? getSetting<T>(String key) {
    final raw = _settings.get(key);
    if (raw is String) {
      return jsonDecode(raw) as T?;
    }
    return raw as T?;
  }

  /// Put a JSON-serializable value into settings storage.
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      await _settings.delete(key);
    } else {
      await _settings.put(key, jsonEncode(value));
    }
  }

  // ---- intro / first-launch flag -------------------------------------------

  /// Returns true if user has seen the intro slides.
  bool get introSeen => _settings.get('introSeen', defaultValue: false) as bool;

  /// Mark intro slides as seen (called when user completes or skips intro).
  Future<void> markIntroSeen() => _settings.put('introSeen', true);

  // ---- referral code -------------------------------------------------------

  /// Store a referral code that brought the user to the app.
  Future<void> setReferralCode(String code) => putSetting('referralCode', code);

  /// Get the stored referral code (from deep link), if any.
  String? get referralCode => getSetting<String>('referralCode');

  /// Clear the referral code after it's been used.
  Future<void> clearReferralCode() => _settings.delete('referralCode');
}
