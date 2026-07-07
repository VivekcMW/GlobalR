import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Display preferences: global text scale and localized numerals.
class DisplaySettings {
  /// 1.0, 1.15, or 1.3 — multiplied with the OS text scale.
  final double textScale;

  /// Render digits in the app language's script (e.g. १२:३०).
  final bool localizedNumerals;

  const DisplaySettings({
    this.textScale = 1.0,
    this.localizedNumerals = false,
  });

  DisplaySettings copyWith({double? textScale, bool? localizedNumerals}) =>
      DisplaySettings(
        textScale: textScale ?? this.textScale,
        localizedNumerals: localizedNumerals ?? this.localizedNumerals,
      );
}

class DisplaySettingsController extends Notifier<DisplaySettings> {
  static const _scaleKey = 'text_scale_pct';
  static const _numeralsKey = 'localized_numerals';

  @override
  DisplaySettings build() {
    final store = ref.read(localStoreProvider);
    final pct = store.getSetting<int>(_scaleKey) ?? 100;
    return DisplaySettings(
      textScale: pct / 100,
      localizedNumerals: store.getSetting<bool>(_numeralsKey) ?? false,
    );
  }

  Future<void> setTextScalePct(int pct) async {
    state = state.copyWith(textScale: pct / 100);
    await ref.read(localStoreProvider).putSetting(_scaleKey, pct);
  }

  Future<void> setLocalizedNumerals(bool on) async {
    state = state.copyWith(localizedNumerals: on);
    await ref.read(localStoreProvider).putSetting(_numeralsKey, on);
  }
}

final displaySettingsProvider =
    NotifierProvider<DisplaySettingsController, DisplaySettings>(
        DisplaySettingsController.new);
