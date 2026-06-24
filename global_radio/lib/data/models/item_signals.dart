/// Per-item personalization signals, stored locally only (never relayed).
/// Drives affinity, recency penalty and favorites (docs algorithm §0, §3).
class ItemSignals {
  final String itemId;
  final int playCount;
  final int completeCount;
  final int skipCount;
  final DateTime? lastPlayedAt;
  final bool favorited;
  final int dwellMs;

  const ItemSignals({
    required this.itemId,
    this.playCount = 0,
    this.completeCount = 0,
    this.skipCount = 0,
    this.lastPlayedAt,
    this.favorited = false,
    this.dwellMs = 0,
  });

  ItemSignals copyWith({
    int? playCount,
    int? completeCount,
    int? skipCount,
    DateTime? lastPlayedAt,
    bool? favorited,
    int? dwellMs,
  }) =>
      ItemSignals(
        itemId: itemId,
        playCount: playCount ?? this.playCount,
        completeCount: completeCount ?? this.completeCount,
        skipCount: skipCount ?? this.skipCount,
        lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
        favorited: favorited ?? this.favorited,
        dwellMs: dwellMs ?? this.dwellMs,
      );

  factory ItemSignals.fromJson(Map<String, dynamic> j) => ItemSignals(
        itemId: j['itemId'] as String,
        playCount: (j['playCount'] as num?)?.toInt() ?? 0,
        completeCount: (j['completeCount'] as num?)?.toInt() ?? 0,
        skipCount: (j['skipCount'] as num?)?.toInt() ?? 0,
        lastPlayedAt: j['lastPlayedAt'] is String
            ? DateTime.tryParse(j['lastPlayedAt'] as String)
            : null,
        favorited: j['favorited'] as bool? ?? false,
        dwellMs: (j['dwellMs'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'playCount': playCount,
        'completeCount': completeCount,
        'skipCount': skipCount,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'favorited': favorited,
        'dwellMs': dwellMs,
      };

  static ItemSignals empty(String itemId) => ItemSignals(itemId: itemId);
}
