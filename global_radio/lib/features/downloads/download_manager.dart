import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/catalog_item.dart';
import 'download_repository.dart';

/// Download task status.
enum DownloadStatus { pending, downloading, completed, failed, cancelled }

/// A single download task.
class DownloadTask {
  final CatalogItem item;
  final String voice;
  DownloadStatus status;
  double progress;
  String? error;
  CancelToken? cancelToken;

  DownloadTask({
    required this.item,
    required this.voice,
    this.status = DownloadStatus.pending,
    this.progress = 0,
    this.error,
    this.cancelToken,
  });

  String get id => '${item.id}_$voice';
}

/// Manages download queue and WiFi-only downloads.
class DownloadManager {
  final DownloadRepository _repository;
  final Dio _dio = Dio();

  final List<DownloadTask> _queue = [];
  final _progressController = StreamController<DownloadTask>.broadcast();
  
  bool _isProcessing = false;
  bool _wifiOnly = true;
  int _maxConcurrent = 2;

  DownloadManager(this._repository);

  /// Stream of download progress updates.
  Stream<DownloadTask> get progressStream => _progressController.stream;

  /// Current download queue.
  List<DownloadTask> get queue => List.unmodifiable(_queue);

  /// Whether to download only on WiFi.
  bool get wifiOnly => _wifiOnly;
  set wifiOnly(bool value) => _wifiOnly = value;

  /// Add an item to the download queue.
  Future<void> enqueue(CatalogItem item, String voice) async {
    // Skip if already downloaded or in queue
    if (_repository.isDownloaded(item.id, voice)) return;
    if (_queue.any((t) => t.item.id == item.id && t.voice == voice)) return;

    final task = DownloadTask(item: item, voice: voice);
    _queue.add(task);
    _progressController.add(task);

    _processQueue();
  }

  /// Add multiple items to the download queue (for auto-download).
  Future<void> enqueueAll(List<CatalogItem> items, String voice) async {
    for (final item in items) {
      await enqueue(item, voice);
    }
  }

  /// Cancel a specific download.
  void cancel(String itemId, String voice) {
    final task = _queue.firstWhere(
      (t) => t.item.id == itemId && t.voice == voice,
      orElse: () => throw StateError('Task not found'),
    );
    
    task.cancelToken?.cancel('User cancelled');
    task.status = DownloadStatus.cancelled;
    _progressController.add(task);
    _queue.removeWhere((t) => t.item.id == itemId && t.voice == voice);
  }

  /// Cancel all downloads.
  void cancelAll() {
    for (final task in _queue) {
      task.cancelToken?.cancel('User cancelled all');
      task.status = DownloadStatus.cancelled;
      _progressController.add(task);
    }
    _queue.clear();
  }

  /// Check if we can download (WiFi check).
  Future<bool> _canDownload() async {
    if (!_wifiOnly) return true;
    
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity.contains(ConnectivityResult.wifi);
  }

  /// Process the download queue.
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queue.any((t) => t.status == DownloadStatus.pending)) {
      if (!await _canDownload()) {
        // Wait for WiFi
        await Future.delayed(const Duration(seconds: 30));
        continue;
      }

      // Get pending tasks up to max concurrent
      final pendingTasks = _queue
          .where((t) => t.status == DownloadStatus.pending)
          .take(_maxConcurrent - _queue.where((t) => t.status == DownloadStatus.downloading).length)
          .toList();

      if (pendingTasks.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      // Start downloads concurrently
      await Future.wait(pendingTasks.map(_downloadTask));
    }

    _isProcessing = false;
  }

  /// Download a single task.
  Future<void> _downloadTask(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    task.cancelToken = CancelToken();
    _progressController.add(task);

    try {
      final url = task.item.audioUrlFor(task.voice);
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${task.item.id}_${task.voice}.mp3';
      final filePath = '${dir.path}/downloads/$fileName';

      // Ensure downloads directory exists
      await Directory('${dir.path}/downloads').create(recursive: true);

      await _dio.download(
        url,
        filePath,
        cancelToken: task.cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            task.progress = received / total;
            _progressController.add(task);
          }
        },
      );

      // Save to repository
      final file = File(filePath);
      final size = await file.length();
      
      await _repository.save(DownloadedItem(
        itemId: task.item.id,
        language: task.item.language,
        voice: task.voice,
        localPath: filePath,
        sizeBytes: size,
        downloadedAt: DateTime.now(),
      ));

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      _progressController.add(task);

      // Remove from queue after completion
      _queue.removeWhere((t) => t.id == task.id);

    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        task.status = DownloadStatus.cancelled;
      } else {
        task.status = DownloadStatus.failed;
        task.error = e.message;
      }
      _progressController.add(task);
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      _progressController.add(task);
    }
  }

  /// Delete a downloaded file.
  Future<void> deleteDownload(String itemId, String voice) async {
    final path = _repository.getLocalPath(itemId, voice);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _repository.delete(itemId, voice);
  }

  /// Delete all downloaded files.
  Future<void> deleteAllDownloads() async {
    final items = _repository.getAll();
    for (final item in items) {
      final file = File(item.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _repository.deleteAll();
  }

  void dispose() {
    cancelAll();
    _progressController.close();
  }
}
