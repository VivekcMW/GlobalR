import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants.dart';
import '../local/local_store.dart';
import '../models/catalog_item.dart';

/// Loads the catalog with a resilient fallback chain:
///   remote CDN (delta by version) → on-device cache → bundled seed asset.
/// Works on a first slow connection and fully offline.
class CatalogRepository {
  final Dio _dio;
  final LocalStore _store;

  CatalogRepository(this._store, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ));

  /// Returns the best catalog available immediately (cache or bundled), without
  /// blocking on the network. Call [refresh] separately to update.
  Future<Catalog> loadInitial() async {
    final cached = _store.cachedCatalogJson();
    if (cached != null) {
      try {
        return Catalog.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {/* fall through to bundled */}
    }
    return _loadBundled();
  }

  /// Fetch the remote catalog; cache it if the version changed. Returns null if
  /// the network failed or the version is unchanged (caller keeps current).
  Future<Catalog?> refresh() async {
    try {
      final res = await _dio.get<String>(
        AppConfig.catalogUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final body = res.data;
      if (body == null || body.isEmpty) return null;
      final json = jsonDecode(body) as Map<String, dynamic>;
      final version = json['version'] as String? ?? 'unknown';
      if (version == _store.cachedCatalogVersion()) return null; // no delta
      await _store.cacheCatalog(body, version);
      return Catalog.fromJson(json);
    } catch (_) {
      return null; // offline / CDN down → caller keeps cached catalog
    }
  }

  Future<Catalog> _loadBundled() async {
    try {
      final body = await rootBundle.loadString(AppConfig.bundledCatalogAsset);
      return Catalog.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } catch (_) {
      return Catalog.empty;
    }
  }
}
