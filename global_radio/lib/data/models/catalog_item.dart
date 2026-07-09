import '../../core/constants.dart';

/// One playable item in the catalog (story / devotion / daily astrology).
/// Mirrors the schema in docs/technical-build-spec.md §4.
class CatalogItem {
  final String id;
  final String title;
  final List<String> interests;
  final String language;
  final List<String> availableVoices;
  final String defaultVoice;
  final int durationSec;
  final int sizeKb;
  final String attribution;
  final int popularity; // 0..100
  final String type; // "library" | "daily"
  final DateTime? date; // for daily items
  final String? sign; // for astrology
  final DateTime? publishedDate;
  final bool reachable; // health-check flag; hides dead URLs
  final String text; // full story text in [language], for the "Read" sheet
  final String? imageUrl; // relative path under cdnBase; null if none generated
  final int imagePanelCount; // panels in the imageUrl strip, 0 if no image

  const CatalogItem({
    required this.id,
    required this.title,
    required this.interests,
    required this.language,
    required this.availableVoices,
    required this.defaultVoice,
    required this.durationSec,
    required this.sizeKb,
    required this.attribution,
    this.popularity = 50,
    this.type = 'library',
    this.date,
    this.sign,
    this.publishedDate,
    this.reachable = true,
    this.text = '',
    this.imageUrl,
    this.imagePanelCount = 0,
  });

  bool get isDaily => type == 'daily';

  /// Whether this item has a story-image strip to show on the Read sheet.
  bool get hasImage => imageUrl != null && imagePanelCount > 0;

  /// Full URL for the (possibly multi-panel) story-image strip.
  String? get imageUrlResolved =>
      imageUrl == null ? null : '${AppConfig.cdnBase}/$imageUrl';

  /// Which panel (0-indexed) to show for a given playback position, based
  /// on how far through the item we are.
  int panelIndexFor(Duration position) {
    if (imagePanelCount <= 1 || durationSec <= 0) return 0;
    final frac = (position.inSeconds / durationSec).clamp(0.0, 0.999);
    return (frac * imagePanelCount).floor().clamp(0, imagePanelCount - 1);
  }

  /// Primary interest used for round-robin sequencing / bucketing.
  String get primaryInterest => interests.isNotEmpty ? interests.first : 'misc';

  /// The voice actually used for playback: the user's preference if this item
  /// offers it, else the item's default voice (docs algorithm §7).
  String resolvedVoice(String preferredVoice) =>
      availableVoices.contains(preferredVoice) ? preferredVoice : defaultVoice;

  /// Resolve the playable URL for a user's preferred voice, falling back to
  /// the item's default voice so playback never breaks (docs algorithm §7).
  String audioUrlFor(String preferredVoice) =>
      '${AppConfig.cdnBase}/$language/${resolvedVoice(preferredVoice)}/$id.mp3';

  /// Bundled demo clip for this item's language + resolved voice (used when
  /// [AppConfig.demoAudio] is on, so sound works with no CDN). Falls back to the
  /// fallback language when this item's language has no bundled clips.
  String demoAssetFor(String preferredVoice) =>
      '${AppConfig.demoAudioDir}/${AppConfig.demoLanguageFor(language)}/${resolvedVoice(preferredVoice)}.mp3';

  factory CatalogItem.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return CatalogItem(
      id: j['id'] as String,
      title: j['title'] as String? ?? j['id'] as String,
      interests: (j['interests'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      language: j['language'] as String? ?? 'english',
      availableVoices:
          (j['availableVoices'] as List?)?.map((e) => e.toString()).toList() ??
              const [VoicePreset.freeDefaultId],
      defaultVoice: j['defaultVoice'] as String? ?? VoicePreset.freeDefaultId,
      durationSec: (j['durationSec'] as num?)?.toInt() ?? 0,
      sizeKb: (j['sizeKb'] as num?)?.toInt() ?? 0,
      attribution: j['attribution'] as String? ?? '',
      popularity: (j['popularity'] as num?)?.toInt() ?? 50,
      type: j['type'] as String? ?? 'library',
      date: parseDate(j['date']),
      sign: j['sign'] as String?,
      publishedDate: parseDate(j['publishedDate']) ?? parseDate(j['date']),
      reachable: j['reachable'] as bool? ?? true,
      text: j['text'] as String? ?? '',
      imageUrl: j['imageUrl'] as String?,
      imagePanelCount: (j['imagePanelCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'interests': interests,
        'language': language,
        'availableVoices': availableVoices,
        'defaultVoice': defaultVoice,
        'durationSec': durationSec,
        'sizeKb': sizeKb,
        'attribution': attribution,
        'popularity': popularity,
        'type': type,
        if (date != null) 'date': date!.toIso8601String().substring(0, 10),
        if (sign != null) 'sign': sign,
        if (publishedDate != null)
          'publishedDate': publishedDate!.toIso8601String().substring(0, 10),
        'reachable': reachable,
        if (text.isNotEmpty) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (imagePanelCount > 0) 'imagePanelCount': imagePanelCount,
      };
}

/// The full catalog (versioned for delta-update detection).
class Catalog {
  final String version;
  final List<CatalogItem> items;
  const Catalog({required this.version, required this.items});

  factory Catalog.fromJson(Map<String, dynamic> j) => Catalog(
        version: j['version'] as String? ?? 'unknown',
        items: (j['items'] as List? ?? const [])
            .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'items': items.map((e) => e.toJson()).toList(),
      };

  static const empty = Catalog(version: 'empty', items: []);
}
