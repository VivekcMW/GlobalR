import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/catalog_item.dart';
import '../../shared/providers/providers.dart';
import 'download_manager.dart';
import 'download_repository.dart';

/// State for the downloads feature.
class DownloadsState {
  final List<DownloadedItem> downloaded;
  final List<DownloadTask> queue;
  final int totalSizeBytes;
  final bool wifiOnly;
  final bool autoDownload;

  const DownloadsState({
    this.downloaded = const [],
    this.queue = const [],
    this.totalSizeBytes = 0,
    this.wifiOnly = true,
    this.autoDownload = true,
  });

  DownloadsState copyWith({
    List<DownloadedItem>? downloaded,
    List<DownloadTask>? queue,
    int? totalSizeBytes,
    bool? wifiOnly,
    bool? autoDownload,
  }) =>
      DownloadsState(
        downloaded: downloaded ?? this.downloaded,
        queue: queue ?? this.queue,
        totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
        wifiOnly: wifiOnly ?? this.wifiOnly,
        autoDownload: autoDownload ?? this.autoDownload,
      );

  /// Format total size for display.
  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Provider for download repository (initialized in main).
final downloadRepositoryProvider = Provider<DownloadRepository>(
  (ref) => throw UnimplementedError('downloadRepositoryProvider must be overridden'),
);

/// Provider for download manager.
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final repository = ref.read(downloadRepositoryProvider);
  final manager = DownloadManager(repository);
  ref.onDispose(manager.dispose);
  return manager;
});

/// Controller for downloads state.
class DownloadsController extends Notifier<DownloadsState> {
  DownloadManager get _manager => ref.read(downloadManagerProvider);
  DownloadRepository get _repository => ref.read(downloadRepositoryProvider);
  StreamSubscription? _subscription;

  @override
  DownloadsState build() {
    // Listen to download progress
    _subscription = _manager.progressStream.listen((_) => _refresh());
    ref.onDispose(() => _subscription?.cancel());

    return DownloadsState(
      downloaded: _repository.getAll(),
      queue: _manager.queue,
      totalSizeBytes: _repository.getTotalSizeBytes(),
    );
  }

  void _refresh() {
    state = state.copyWith(
      downloaded: _repository.getAll(),
      queue: _manager.queue,
      totalSizeBytes: _repository.getTotalSizeBytes(),
    );
  }

  /// Download a single item.
  Future<void> download(CatalogItem item, String voice) async {
    await _manager.enqueue(item, voice);
    _refresh();
  }

  /// Download multiple items (auto-download next N).
  Future<void> downloadAll(List<CatalogItem> items, String voice) async {
    await _manager.enqueueAll(items, voice);
    _refresh();
  }

  /// Auto-download next N items based on user's interests.
  Future<void> autoDownloadNext({int count = 5}) async {
    if (!state.autoDownload) return;
    
    final profile = ref.read(profileProvider);
    final catalog = ref.read(catalogProvider).valueOrNull;
    if (catalog == null) return;

    // Get items matching user's interests that aren't downloaded
    final candidates = catalog.items
        .where((item) =>
            profile.languages.contains(item.language) &&
            item.interests.any((i) => profile.interests.contains(i)) &&
            !_repository.isDownloaded(item.id, profile.preferredVoice))
        .take(count)
        .toList();

    await _manager.enqueueAll(candidates, profile.preferredVoice);
    _refresh();
  }

  /// Cancel a download.
  void cancel(String itemId, String voice) {
    _manager.cancel(itemId, voice);
    _refresh();
  }

  /// Cancel all downloads.
  void cancelAll() {
    _manager.cancelAll();
    _refresh();
  }

  /// Delete a downloaded item.
  Future<void> delete(String itemId, String voice) async {
    await _manager.deleteDownload(itemId, voice);
    _refresh();
  }

  /// Delete all downloads.
  Future<void> deleteAll() async {
    await _manager.deleteAllDownloads();
    _refresh();
  }

  /// Toggle WiFi-only setting.
  void setWifiOnly(bool value) {
    _manager.wifiOnly = value;
    state = state.copyWith(wifiOnly: value);
  }

  /// Toggle auto-download setting.
  void setAutoDownload(bool value) {
    state = state.copyWith(autoDownload: value);
    if (value) {
      autoDownloadNext();
    }
  }

  /// Check if an item is downloaded.
  bool isDownloaded(String itemId, String voice) {
    return _repository.isDownloaded(itemId, voice);
  }

  /// Get local path for a downloaded item.
  String? getLocalPath(String itemId, String voice) {
    return _repository.getLocalPath(itemId, voice);
  }
}

final downloadsProvider =
    NotifierProvider<DownloadsController, DownloadsState>(DownloadsController.new);
