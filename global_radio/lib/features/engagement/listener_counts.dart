/// Real listener counts, fed via the `listener_counts_json` Remote Config
/// key. Format: `{"festival:diwali": 5120, "station:kids": 812}` — updated by
/// a small cron against analytics. Falls back to the deterministic simulated
/// count when no real number is available, so the UI never shows zero.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/remote_config_service.dart';

class ListenerCounts {
  /// Parse the RC JSON payload; bad input yields an empty map.
  static Map<String, int> parse(String json) {
    if (json.trim().isEmpty) return const {};
    try {
      final raw = jsonDecode(json);
      if (raw is! Map) return const {};
      return raw.map((k, v) =>
          MapEntry(k.toString(), v is num ? v.toInt() : 0))
        ..removeWhere((_, v) => v <= 0);
    } catch (e) {
      debugPrint('ListenerCounts: bad listener_counts_json: $e');
      return const {};
    }
  }
}

/// All real counts currently published via Remote Config.
final listenerCountsProvider = Provider<Map<String, int>>((ref) {
  final rc = ref.watch(remoteConfigProvider);
  return ListenerCounts.parse(rc.listenerCountsJson);
});

/// Real count for a key like `festival:diwali`, or null (caller falls back
/// to its simulated count).
final realListenerCountProvider =
    Provider.family<int?, String>((ref, key) {
  return ref.watch(listenerCountsProvider)[key];
});
