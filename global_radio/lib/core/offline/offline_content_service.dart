/// Offline content management for downloading and playing content offline.
///
/// Features:
/// - Download queue management
/// - Progress tracking
/// - Storage management
/// - Automatic cleanup
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Download status.
enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  cancelled,
}

/// Download task.
class DownloadTask {
  final String id;
  final String url;
  final String localPath;
  DownloadStatus status;
  double progress;
  int bytesDownloaded;
  int totalBytes;
  String? error;

  DownloadTask({
    required this.id,
    required this.url,
    required this.localPath,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.error,
  });

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progress,
    int? bytesDownloaded,
    int? totalBytes,
    String? error,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      localPath: localPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
    );
  }
}

/// Offline content item.
class OfflineContent {
  final String id;
  final String title;
  final String interest;
  final String localPath;
  final int sizeBytes;
  final DateTime downloadedAt;

  const OfflineContent({
    required this.id,
    required this.title,
    required this.interest,
    required this.localPath,
    required this.sizeBytes,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'interest': interest,
        'localPath': localPath,
        'sizeBytes': sizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory OfflineContent.fromJson(Map<String, dynamic> json) => OfflineContent(
        id: json['id'] as String,
        title: json['title'] as String,
        interest: json['interest'] as String,
        localPath: json['localPath'] as String,
        sizeBytes: json['sizeBytes'] as int,
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      );
}

/// Storage info.
class StorageInfo {
  final int usedBytes;
  final int availableBytes;
  final int downloadedCount;

  const StorageInfo({
    required this.usedBytes,
    required this.availableBytes,
    required this.downloadedCount,
  });

  String get usedFormatted => _formatBytes(usedBytes);
  String get availableFormatted => _formatBytes(availableBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Offline content service.
class OfflineContentService {
  final Map<String, DownloadTask> _activeTasks = {};
  final List<OfflineContent> _downloadedContent = [];
  final _downloadProgressController = StreamController<Map<String, DownloadTask>>.broadcast();
  
  Stream<Map<String, DownloadTask>> get downloadProgress => _downloadProgressController.stream;
  List<OfflineContent> get downloadedContent => List.unmodifiable(_downloadedContent);

  /// Get the downloads directory.
  Future<Directory> get _downloadsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDir.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  /// Download content.
  Future<void> download({
    required String id,
    required String url,
    required String title,
    required String interest,
  }) async {
    final dir = await _downloadsDir;
    final fileName = '${id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final localPath = '${dir.path}/$fileName';

    final task = DownloadTask(
      id: id,
      url: url,
      localPath: localPath,
    );

    _activeTasks[id] = task;
    _notifyProgress();

    try {
      task.status = DownloadStatus.downloading;
      _notifyProgress();

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      task.totalBytes = response.contentLength;
      _notifyProgress();

      final file = File(localPath);
      final sink = file.openWrite();
      int downloaded = 0;

      await for (final chunk in response) {
        if (task.status == DownloadStatus.cancelled) {
          await sink.close();
          await file.delete();
          return;
        }

        sink.add(chunk);
        downloaded += chunk.length;
        
        task.bytesDownloaded = downloaded;
        if (task.totalBytes > 0) {
          task.progress = downloaded / task.totalBytes;
        }
        _notifyProgress();
      }

      await sink.close();

      // Save to downloaded content list
      final content = OfflineContent(
        id: id,
        title: title,
        interest: interest,
        localPath: localPath,
        sizeBytes: downloaded,
        downloadedAt: DateTime.now(),
      );
      _downloadedContent.add(content);

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      _notifyProgress();

      debugPrint('[Offline] Downloaded: $title ($downloaded bytes)');
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      _notifyProgress();
      debugPrint('[Offline] Download failed: $e');
    }
  }

  /// Cancel a download.
  void cancelDownload(String id) {
    final task = _activeTasks[id];
    if (task != null && task.status == DownloadStatus.downloading) {
      task.status = DownloadStatus.cancelled;
      _notifyProgress();
    }
  }

  /// Delete downloaded content.
  Future<void> deleteContent(String id) async {
    final index = _downloadedContent.indexWhere((c) => c.id == id);
    if (index != -1) {
      final content = _downloadedContent[index];
      final file = File(content.localPath);
      if (await file.exists()) {
        await file.delete();
      }
      _downloadedContent.removeAt(index);
    }
    _activeTasks.remove(id);
    _notifyProgress();
  }

  /// Check if content is downloaded.
  bool isDownloaded(String id) {
    return _downloadedContent.any((c) => c.id == id);
  }

  /// Get local path for content.
  String? getLocalPath(String id) {
    final content = _downloadedContent.cast<OfflineContent?>().firstWhere(
      (c) => c?.id == id,
      orElse: () => null,
    );
    return content?.localPath;
  }

  /// Get storage info.
  Future<StorageInfo> getStorageInfo() async {
    int usedBytes = 0;
    for (final content in _downloadedContent) {
      final file = File(content.localPath);
      if (await file.exists()) {
        usedBytes += await file.length();
      }
    }

    // Get available storage (approximate)
    final dir = await _downloadsDir;
    final stat = await dir.stat();
    // Note: Getting actual free space requires platform-specific code
    const availableBytes = 1024 * 1024 * 1024; // Placeholder 1GB

    return StorageInfo(
      usedBytes: usedBytes,
      availableBytes: availableBytes,
      downloadedCount: _downloadedContent.length,
    );
  }

  /// Clear all downloads.
  Future<void> clearAll() async {
    for (final content in _downloadedContent) {
      final file = File(content.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _downloadedContent.clear();
    _activeTasks.clear();
    _notifyProgress();
  }

  void _notifyProgress() {
    _downloadProgressController.add(Map.from(_activeTasks));
  }

  void dispose() {
    _downloadProgressController.close();
  }
}

/// Offline content service provider.
final offlineContentServiceProvider = Provider<OfflineContentService>((ref) {
  final service = OfflineContentService();
  ref.onDispose(service.dispose);
  return service;
});

/// Active downloads provider.
final activeDownloadsProvider = StreamProvider<Map<String, DownloadTask>>((ref) {
  final service = ref.watch(offlineContentServiceProvider);
  return service.downloadProgress;
});

/// Downloaded content provider.
final downloadedContentProvider = Provider<List<OfflineContent>>((ref) {
  final service = ref.watch(offlineContentServiceProvider);
  return service.downloadedContent;
});

/// Storage info provider.
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final service = ref.watch(offlineContentServiceProvider);
  return service.getStorageInfo();
});
