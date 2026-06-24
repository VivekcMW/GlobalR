import 'package:hive/hive.dart';

/// Tracks download state for a catalog item.
class DownloadedItem {
  final String itemId;
  final String language;
  final String voice;
  final String localPath;
  final int sizeBytes;
  final DateTime downloadedAt;

  DownloadedItem({
    required this.itemId,
    required this.language,
    required this.voice,
    required this.localPath,
    required this.sizeBytes,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'language': language,
        'voice': voice,
        'localPath': localPath,
        'sizeBytes': sizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory DownloadedItem.fromJson(Map<String, dynamic> json) => DownloadedItem(
        itemId: json['itemId'] as String,
        language: json['language'] as String,
        voice: json['voice'] as String,
        localPath: json['localPath'] as String,
        sizeBytes: json['sizeBytes'] as int,
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      );
}

/// Hive-backed storage for downloaded items.
class DownloadRepository {
  static const _boxName = 'downloads';
  late Box<Map> _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  /// Get all downloaded items.
  List<DownloadedItem> getAll() {
    return _box.values.map((m) => DownloadedItem.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  /// Check if an item is downloaded for the given voice.
  bool isDownloaded(String itemId, String voice) {
    final key = '${itemId}_$voice';
    return _box.containsKey(key);
  }

  /// Get the local path for a downloaded item, or null if not downloaded.
  String? getLocalPath(String itemId, String voice) {
    final key = '${itemId}_$voice';
    final data = _box.get(key);
    if (data == null) return null;
    return DownloadedItem.fromJson(Map<String, dynamic>.from(data)).localPath;
  }

  /// Save a downloaded item.
  Future<void> save(DownloadedItem item) async {
    final key = '${item.itemId}_${item.voice}';
    await _box.put(key, item.toJson());
  }

  /// Delete a downloaded item.
  Future<void> delete(String itemId, String voice) async {
    final key = '${itemId}_$voice';
    await _box.delete(key);
  }

  /// Get total size of all downloads in bytes.
  int getTotalSizeBytes() {
    return getAll().fold(0, (sum, item) => sum + item.sizeBytes);
  }

  /// Delete all downloads.
  Future<void> deleteAll() async {
    await _box.clear();
  }
}
