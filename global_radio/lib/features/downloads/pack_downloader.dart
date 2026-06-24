import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// A downloadable content pack.
class DownloadPack {
  final String id;
  final String name;
  final String description;
  final String language;
  final String category;
  final String icon;
  final int sizeMb;
  final int itemCount;
  final int durationMinutes;
  final List<String> tags;
  final bool featured;

  const DownloadPack({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.category,
    required this.icon,
    required this.sizeMb,
    required this.itemCount,
    required this.durationMinutes,
    required this.tags,
    this.featured = false,
  });

  factory DownloadPack.fromJson(Map<String, dynamic> json) {
    return DownloadPack(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String? ?? '📦',
      sizeMb: json['size_mb'] as int,
      itemCount: json['item_count'] as int,
      durationMinutes: json['duration_minutes'] as int,
      tags: List<String>.from(json['tags'] ?? []),
      featured: json['featured'] as bool? ?? false,
    );
  }

  String get sizeFormatted {
    if (sizeMb >= 1000) {
      return '${(sizeMb / 1000).toStringAsFixed(1)} GB';
    }
    return '$sizeMb MB';
  }

  String get durationFormatted {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

/// Pack category definition.
class PackCategory {
  final String id;
  final String name;
  final String icon;

  const PackCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory PackCategory.fromJson(Map<String, dynamic> json) {
    return PackCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }
}

/// Download status for a pack.
enum PackDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
}

/// Download progress info.
class PackDownloadProgress {
  final String packId;
  final PackDownloadStatus status;
  final double progress;
  final String? error;

  const PackDownloadProgress({
    required this.packId,
    required this.status,
    this.progress = 0,
    this.error,
  });

  PackDownloadProgress copyWith({
    PackDownloadStatus? status,
    double? progress,
    String? error,
  }) {
    return PackDownloadProgress(
      packId: packId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

/// Service for managing download packs.
class PackDownloaderService {
  static const _boxName = 'downloaded_packs';

  Box? _box;
  Directory? _downloadDir;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final appDir = await getApplicationDocumentsDirectory();
    _downloadDir = Directory('${appDir.path}/packs');
    if (!await _downloadDir!.exists()) {
      await _downloadDir!.create(recursive: true);
    }
  }

  /// Check if a pack is downloaded.
  bool isDownloaded(String packId) {
    return _box?.get(packId) != null;
  }

  /// Get all downloaded pack IDs.
  Set<String> get downloadedPackIds {
    return _box?.keys.cast<String>().toSet() ?? {};
  }

  /// Get total size of downloaded packs in MB.
  int get totalDownloadedSizeMb {
    return _box?.values.fold<int>(0, (sum, v) => sum + (v['sizeMb'] as int? ?? 0)) ?? 0;
  }

  /// Download a pack.
  Stream<PackDownloadProgress> downloadPack(DownloadPack pack) async* {
    yield PackDownloadProgress(
      packId: pack.id,
      status: PackDownloadStatus.downloading,
      progress: 0,
    );

    try {
      // Simulate download (in real app, would download from CDN)
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        yield PackDownloadProgress(
          packId: pack.id,
          status: PackDownloadStatus.downloading,
          progress: i / 10,
        );
      }

      // Mark as downloaded
      await _box?.put(pack.id, {
        'downloadedAt': DateTime.now().toIso8601String(),
        'sizeMb': pack.sizeMb,
        'itemCount': pack.itemCount,
      });

      yield PackDownloadProgress(
        packId: pack.id,
        status: PackDownloadStatus.downloaded,
        progress: 1,
      );
    } catch (e) {
      yield PackDownloadProgress(
        packId: pack.id,
        status: PackDownloadStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Delete a downloaded pack.
  Future<void> deletePack(String packId) async {
    await _box?.delete(packId);

    // Delete files
    final packDir = Directory('${_downloadDir!.path}/$packId');
    if (await packDir.exists()) {
      await packDir.delete(recursive: true);
    }
  }

  /// Get download info for a pack.
  Map<String, dynamic>? getDownloadInfo(String packId) {
    final data = _box?.get(packId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }
}

/// Provider for the pack downloader service.
final packDownloaderServiceProvider = Provider<PackDownloaderService>((ref) {
  final service = PackDownloaderService();
  service.init();
  return service;
});

/// Provider for available download packs.
final downloadPacksProvider = FutureProvider<List<DownloadPack>>((ref) async {
  try {
    final jsonString =
        await rootBundle.loadString('assets/catalog/download_packs.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final packsList = json['packs'] as List<dynamic>;
    return packsList
        .map((p) => DownloadPack.fromJson(p as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Provider for pack categories.
final packCategoriesProvider = FutureProvider<List<PackCategory>>((ref) async {
  try {
    final jsonString =
        await rootBundle.loadString('assets/catalog/download_packs.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final cats = json['categories'] as List<dynamic>;
    return cats
        .map((c) => PackCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Provider for featured packs.
final featuredPacksProvider = Provider<List<DownloadPack>>((ref) {
  final packsAsync = ref.watch(downloadPacksProvider);
  return packsAsync.maybeWhen(
    data: (packs) => packs.where((p) => p.featured).toList(),
    orElse: () => [],
  );
});

/// Provider for packs by language.
final packsByLanguageProvider =
    Provider.family<List<DownloadPack>, String>((ref, language) {
  final packsAsync = ref.watch(downloadPacksProvider);
  return packsAsync.maybeWhen(
    data: (packs) => packs.where((p) => p.language == language).toList(),
    orElse: () => [],
  );
});

/// Provider for downloaded pack IDs.
final downloadedPackIdsProvider = Provider<Set<String>>((ref) {
  final service = ref.watch(packDownloaderServiceProvider);
  return service.downloadedPackIds;
});

/// Provider for checking if a pack is downloaded.
final isPackDownloadedProvider = Provider.family<bool, String>((ref, packId) {
  final service = ref.watch(packDownloaderServiceProvider);
  return service.isDownloaded(packId);
});

/// Provider for total downloaded size.
final totalDownloadedSizeProvider = Provider<int>((ref) {
  final service = ref.watch(packDownloaderServiceProvider);
  return service.totalDownloadedSizeMb;
});

/// State notifier for tracking active downloads.
final activeDownloadsProvider = StateNotifierProvider<
    ActiveDownloadsNotifier, Map<String, PackDownloadProgress>>((ref) {
  return ActiveDownloadsNotifier(ref);
});

class ActiveDownloadsNotifier
    extends StateNotifier<Map<String, PackDownloadProgress>> {
  final Ref _ref;

  ActiveDownloadsNotifier(this._ref) : super({});

  Future<void> startDownload(DownloadPack pack) async {
    final service = _ref.read(packDownloaderServiceProvider);

    await for (final progress in service.downloadPack(pack)) {
      state = {...state, pack.id: progress};

      // Clean up completed downloads
      if (progress.status == PackDownloadStatus.downloaded ||
          progress.status == PackDownloadStatus.error) {
        await Future.delayed(const Duration(seconds: 2));
        state = Map.from(state)..remove(pack.id);
      }
    }
  }

  void cancelDownload(String packId) {
    state = Map.from(state)..remove(packId);
  }
}
