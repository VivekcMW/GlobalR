import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';

/// Current [Daypart], re-evaluated every minute so the theme accent and
/// gradients follow the Indian day (prabhat/din/sandhya/ratri).
final daypartProvider = StreamProvider<Daypart>((ref) async* {
  yield Daypart.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => Daypart.now());
});

/// Synchronous convenience: latest daypart with a safe fallback.
final currentDaypartProvider = Provider<Daypart>((ref) {
  return ref.watch(daypartProvider).value ?? Daypart.now();
});
