/// Riverpod 3 test fakes for widget tests.
///
/// The real controllers touch the local store and audio handler in `build()`;
/// these fakes override `build()` (and the side-effecting methods) so screens
/// can be pumped with seeded state and no platform dependencies.
library;

import 'dart:async';

import 'package:global_radio/data/local/local_store.dart';
import 'package:global_radio/data/models/catalog_item.dart';
import 'package:global_radio/data/models/item_signals.dart';
import 'package:global_radio/data/models/user_profile.dart';
import 'package:global_radio/shared/providers/providers.dart';
import 'package:global_radio/shared/providers/radio_controller.dart';

/// In-memory settings store for tests (no Hive/platform dependencies).
class FakeLocalStore extends LocalStore {
  final Map<String, dynamic> _kv = {};
  UserProfile _fakeProfile = const UserProfile();
  final Map<String, ItemSignals> _fakeSignals = {};

  @override
  T? getSetting<T>(String key) => _kv[key] as T?;

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _kv.remove(key);
    } else {
      _kv[key] = value;
    }
  }

  @override
  UserProfile loadProfile() => _fakeProfile;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _fakeProfile = profile;
  }

  @override
  Map<String, ItemSignals> loadAllSignals() => Map.of(_fakeSignals);

  @override
  ItemSignals signalsFor(String itemId) =>
      _fakeSignals[itemId] ?? ItemSignals.empty(itemId);

  @override
  Future<void> saveSignals(ItemSignals s) async {
    _fakeSignals[s.itemId] = s;
  }
}

class FakeProfileController extends ProfileController {
  FakeProfileController(this._profile);
  final UserProfile _profile;

  @override
  UserProfile build() => _profile;
}

class FakeCatalogController extends CatalogController {
  FakeCatalogController(Catalog catalog) : _build = (() async => catalog);
  FakeCatalogController.loading()
      : _build = (() => Completer<Catalog>().future);
  FakeCatalogController.error(Object error)
      : _build = (() => Future.error(error));

  final Future<Catalog> Function() _build;

  @override
  Future<Catalog> build() => _build();
}

class FakeRadioController extends RadioController {
  FakeRadioController([RadioState? initial])
      : _initial = initial ?? const RadioState();

  final RadioState _initial;

  /// Records calls for assertions.
  final List<String> calls = [];

  @override
  RadioState build() => _initial;

  @override
  Future<void> startRadio({List<String>? onlyInterests}) async {
    calls.add('startRadio');
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> togglePlayPause() async => calls.add('togglePlayPause');

  @override
  Future<void> skipNext() async => calls.add('skipNext');

  @override
  Future<void> skipPrevious() async => calls.add('skipPrevious');

  @override
  Future<void> playAt(int index) async => calls.add('playAt:$index');

  @override
  void toggleFavorite(String itemId) => calls.add('toggleFavorite:$itemId');

  @override
  bool isFavorite(String itemId) => false;
}

/// A minimal valid [CatalogItem] for tests.
CatalogItem testItem({
  String id = 'test-1',
  String title = 'Test Story',
  List<String> interests = const ['kids'],
  String language = 'hindi',
  List<String> availableVoices = const ['male_story'],
  String defaultVoice = 'male_story',
  int durationSec = 180,
}) {
  return CatalogItem(
    id: id,
    title: title,
    interests: interests,
    language: language,
    availableVoices: availableVoices,
    defaultVoice: defaultVoice,
    durationSec: durationSec,
    sizeKb: durationSec * 8,
    attribution: 'Test attribution',
  );
}

/// A catalog wrapping [items].
Catalog testCatalog(List<CatalogItem> items) =>
    Catalog(version: 'test', items: items);
