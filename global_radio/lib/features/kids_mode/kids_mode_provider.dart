import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';

/// Kids Mode: when enabled, every radio queue is restricted to kid-safe
/// interests regardless of the profile's interests or the tapped station.
class KidsModeController extends Notifier<bool> {
  static const _key = 'kids_mode_enabled';

  /// Interests considered safe for children.
  static const kidSafeInterests = <String>[
    'kids',
    'moral',
    'fairytales',
    'bedtime',
    'mythology',
  ];

  @override
  bool build() =>
      ref.read(localStoreProvider).getSetting<bool>(_key) ?? false;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(localStoreProvider).putSetting(_key, enabled);
  }
}

final kidsModeProvider =
    NotifierProvider<KidsModeController, bool>(KidsModeController.new);
