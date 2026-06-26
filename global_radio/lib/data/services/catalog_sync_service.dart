import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../local/local_store.dart';
import '../models/catalog_item.dart';

/// Configuration for catalog sync behavior.
class CatalogSyncConfig {
  /// How often to check for catalog updates (default: 6 hours).
  final Duration syncInterval;

  /// How often to run health checks on audio URLs (default: 24 hours).
  final Duration healthCheckInterval;

  /// Number of URLs to check per health check batch.
  final int healthCheckBatchSize;

  /// Timeout for health check requests.
  final Duration healthCheckTimeout;

  /// CDN fallback URLs (tried in order if primary fails).
  final List<String> cdnFallbackUrls;

  /// Whether to run health checks on metered connections.
  final bool healthCheckOnMetered;

  const CatalogSyncConfig({
    this.syncInterval = const Duration(hours: 6),
    this.healthCheckInterval = const Duration(hours: 24),
    this.healthCheckBatchSize = 20,
    this.healthCheckTimeout = const Duration(seconds: 10),
    this.cdnFallbackUrls = const [],
    this.healthCheckOnMetered = false,
  });

  /// Production config with sensible defaults.
  static const production = CatalogSyncConfig(
    syncInterval: Duration(hours: 6),
    healthCheckInterval: Duration(hours: 24),
    healthCheckBatchSize: 20,
    cdnFallbackUrls: [
      // Add your fallback CDN URLs here
      // 'https://cdn2.globalradio.app',
      // 'https://backup.globalradio.app',
    ],
  );

  /// Development config with faster intervals.
  static const development = CatalogSyncConfig(
    syncInterval: Duration(minutes: 5),
    healthCheckInterval: Duration(hours: 1),
    healthCheckBatchSize: 50,
  );
}

/// Result of a catalog sync operation.
class CatalogSyncResult {
  final bool success;
  final String? newVersion;
  final int itemCount;
  final int newItemsCount;
  final String? error;
  final DateTime timestamp;

  const CatalogSyncResult({
    required this.success,
    this.newVersion,
    this.itemCount = 0,
    this.newItemsCount = 0,
    this.error,
    required this.timestamp,
  });

  factory CatalogSyncResult.success({
    required String version,
    required int itemCount,
    int newItemsCount = 0,
  }) {
    return CatalogSyncResult(
      success: true,
      newVersion: version,
      itemCount: itemCount,
      newItemsCount: newItemsCount,
      timestamp: DateTime.now(),
    );
  }

  factory CatalogSyncResult.unchanged() {
    return CatalogSyncResult(
      success: true,
      timestamp: DateTime.now(),
    );
  }

  factory CatalogSyncResult.failure(String error) {
    return CatalogSyncResult(
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }
}

/// Result of a URL health check.
class HealthCheckResult {
  final String url;
  final bool reachable;
  final int statusCode;
  final int latencyMs;
  final DateTime checkedAt;

  const HealthCheckResult({
    required this.url,
    required this.reachable,
    this.statusCode = 0,
    this.latencyMs = 0,
    required this.checkedAt,
  });
}

/// Manages catalog synchronization with health checking and fallback.
///
/// **Features:**
/// - Periodic catalog sync from CDN with delta updates
/// - Background health checking of audio URLs
/// - Automatic failover to fallback CDNs
/// - Marks unreachable items to avoid playback failures
/// - Respects metered connections (WiFi-only health checks)
class CatalogSyncService {
  final Dio _dio;
  final LocalStore _store;
  final CatalogSyncConfig config;

  Timer? _syncTimer;
  Timer? _healthCheckTimer;
  StreamSubscription? _connectivitySubscription;

  /// Current catalog version.
  String? _currentVersion;

  /// URLs that failed health checks (item ID -> failure count).
  final Map<String, int> _failedUrls = {};

  /// Callback when catalog is updated.
  void Function(Catalog catalog)? onCatalogUpdated;

  /// Callback when health check finds dead URLs.
  void Function(List<String> deadItemIds)? onDeadUrlsFound;

  /// Callback for sync status updates (for UI).
  void Function(CatalogSyncResult result)? onSyncResult;

  /// Whether a sync is currently in progress.
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Last sync result.
  CatalogSyncResult? _lastSyncResult;
  CatalogSyncResult? get lastSyncResult => _lastSyncResult;

  CatalogSyncService(
    this._store, {
    Dio? dio,
    this.config = CatalogSyncConfig.production,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// Start automatic catalog sync and health checking.
  void startAutoSync() {
    // Initial sync
    syncNow();

    // Schedule periodic sync
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(config.syncInterval, (_) => syncNow());

    // Schedule periodic health checks
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      config.healthCheckInterval,
      (_) => runHealthCheck(),
    );

    // Listen for connectivity changes to trigger sync on reconnect
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);

    print('[CatalogSync] Auto-sync started (interval: ${config.syncInterval.inHours}h)');
  }

  /// Stop automatic sync.
  void stopAutoSync() {
    _syncTimer?.cancel();
    _healthCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncTimer = null;
    _healthCheckTimer = null;
    _connectivitySubscription = null;
    print('[CatalogSync] Auto-sync stopped');
  }

  /// Handle connectivity changes.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    if (result != ConnectivityResult.none) {
      // Reconnected - trigger a sync
      print('[CatalogSync] Network reconnected, triggering sync');
      syncNow();
    }
  }

  /// Sync catalog now.
  Future<CatalogSyncResult> syncNow() async {
    if (_isSyncing) {
      print('[CatalogSync] Sync already in progress, skipping');
      return CatalogSyncResult.unchanged();
    }

    _isSyncing = true;
    print('[CatalogSync] Starting catalog sync...');

    try {
      // Try primary CDN first
      var result = await _fetchCatalog(AppConfig.catalogUrl);

      // If primary fails, try fallbacks
      if (!result.success && config.cdnFallbackUrls.isNotEmpty) {
        for (final fallbackUrl in config.cdnFallbackUrls) {
          print('[CatalogSync] Trying fallback: $fallbackUrl');
          result = await _fetchCatalog(fallbackUrl);
          if (result.success) break;
        }
      }

      _lastSyncResult = result;
      onSyncResult?.call(result);

      if (result.success) {
        print('[CatalogSync] Sync completed: ${result.itemCount} items, version ${result.newVersion}');
      } else {
        print('[CatalogSync] Sync failed: ${result.error}');
      }

      return result;
    } finally {
      _isSyncing = false;
    }
  }

  /// Fetch catalog from a specific URL.
  Future<CatalogSyncResult> _fetchCatalog(String url) async {
    try {
      final res = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      final body = res.data;
      if (body == null || body.isEmpty) {
        return CatalogSyncResult.failure('Empty response');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final version = json['version'] as String? ?? 'unknown';

      // Check if version changed
      if (version == _currentVersion) {
        return CatalogSyncResult.unchanged();
      }

      // Parse catalog
      final catalog = Catalog.fromJson(json);

      // Calculate new items (for notification)
      final oldVersion = _store.cachedCatalogVersion();
      int newItemsCount = 0;
      if (oldVersion != null && oldVersion != version) {
        final oldCatalogJson = _store.cachedCatalogJson();
        if (oldCatalogJson != null) {
          try {
            final oldCatalog = Catalog.fromJson(
              jsonDecode(oldCatalogJson) as Map<String, dynamic>,
            );
            final oldIds = oldCatalog.items.map((i) => i.id).toSet();
            newItemsCount = catalog.items.where((i) => !oldIds.contains(i.id)).length;
          } catch (_) {}
        }
      }

      // Cache the new catalog
      await _store.cacheCatalog(body, version);
      _currentVersion = version;

      // Notify listeners
      onCatalogUpdated?.call(catalog);

      return CatalogSyncResult.success(
        version: version,
        itemCount: catalog.items.length,
        newItemsCount: newItemsCount,
      );
    } on DioException catch (e) {
      return CatalogSyncResult.failure('Network error: ${e.message}');
    } catch (e) {
      return CatalogSyncResult.failure('Parse error: $e');
    }
  }

  /// Run health check on catalog URLs.
  Future<void> runHealthCheck() async {
    // Check if we should run on current connection
    final connectivity = await Connectivity().checkConnectivity();
    final isMetered = connectivity.any((c) => c == ConnectivityResult.mobile);
    if (isMetered && !config.healthCheckOnMetered) {
      print('[HealthCheck] Skipping on metered connection');
      return;
    }

    print('[HealthCheck] Starting health check...');

    // Load current catalog
    final catalogJson = _store.cachedCatalogJson();
    if (catalogJson == null) {
      print('[HealthCheck] No cached catalog');
      return;
    }

    try {
      final catalog = Catalog.fromJson(
        jsonDecode(catalogJson) as Map<String, dynamic>,
      );

      // Sample URLs to check (prioritize items not recently checked)
      final itemsToCheck = catalog.items
          .where((i) => i.reachable)
          .take(config.healthCheckBatchSize)
          .toList();

      final deadItemIds = <String>[];

      for (final item in itemsToCheck) {
        final result = await _checkUrl(item.audioUrlFor('male_story'));
        if (!result.reachable) {
          _failedUrls[item.id] = (_failedUrls[item.id] ?? 0) + 1;

          // Mark as dead after 3 consecutive failures
          if (_failedUrls[item.id]! >= 3) {
            deadItemIds.add(item.id);
            print('[HealthCheck] Dead URL: ${item.id}');
          }
        } else {
          // Reset failure count on success
          _failedUrls.remove(item.id);
        }
      }

      if (deadItemIds.isNotEmpty) {
        // Update catalog to mark items as unreachable
        await _markItemsUnreachable(deadItemIds);
        onDeadUrlsFound?.call(deadItemIds);
      }

      print('[HealthCheck] Completed: ${itemsToCheck.length} checked, ${deadItemIds.length} dead');
    } catch (e) {
      print('[HealthCheck] Error: $e');
    }
  }

  /// Check if a URL is reachable.
  Future<HealthCheckResult> _checkUrl(String url) async {
    final stopwatch = Stopwatch()..start();
    try {
      final res = await _dio.head(
        url,
        options: Options(
          receiveTimeout: config.healthCheckTimeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      stopwatch.stop();

      return HealthCheckResult(
        url: url,
        reachable: res.statusCode == 200,
        statusCode: res.statusCode ?? 0,
        latencyMs: stopwatch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      return HealthCheckResult(
        url: url,
        reachable: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
      );
    }
  }

  /// Mark items as unreachable in cached catalog.
  Future<void> _markItemsUnreachable(List<String> itemIds) async {
    final catalogJson = _store.cachedCatalogJson();
    if (catalogJson == null) return;

    try {
      final json = jsonDecode(catalogJson) as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>;

      for (final item in items) {
        if (itemIds.contains(item['id'])) {
          item['reachable'] = false;
        }
      }

      // Save updated catalog
      await _store.cacheCatalog(
        jsonEncode(json),
        json['version'] as String? ?? 'unknown',
      );
    } catch (e) {
      print('[HealthCheck] Failed to update catalog: $e');
    }
  }

  /// Force refresh catalog (bypass version check).
  Future<CatalogSyncResult> forceRefresh() async {
    _currentVersion = null;
    return syncNow();
  }

  /// Get health status for an item.
  bool isItemHealthy(String itemId) {
    return (_failedUrls[itemId] ?? 0) < 3;
  }

  /// Dispose resources.
  void dispose() {
    stopAutoSync();
  }
}

/// Provider-friendly wrapper for CatalogSyncService.
///
/// Use with Riverpod to integrate into the app's state management.
class CatalogSyncNotifier {
  final CatalogSyncService _service;
  final void Function(Catalog) _onCatalogUpdated;

  CatalogSyncNotifier({
    required LocalStore store,
    required void Function(Catalog) onCatalogUpdated,
    CatalogSyncConfig config = CatalogSyncConfig.production,
  })  : _onCatalogUpdated = onCatalogUpdated,
        _service = CatalogSyncService(store, config: config) {
    _service.onCatalogUpdated = onCatalogUpdated;
  }

  void startAutoSync() => _service.startAutoSync();
  void stopAutoSync() => _service.stopAutoSync();
  Future<CatalogSyncResult> syncNow() => _service.syncNow();
  Future<CatalogSyncResult> forceRefresh() => _service.forceRefresh();
  Future<void> runHealthCheck() => _service.runHealthCheck();

  bool get isSyncing => _service.isSyncing;
  CatalogSyncResult? get lastSyncResult => _service.lastSyncResult;

  void dispose() => _service.dispose();
}
