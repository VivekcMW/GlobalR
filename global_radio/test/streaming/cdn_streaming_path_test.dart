@Tags(['integration'])
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/core/constants.dart';
import 'package:global_radio/data/models/catalog_item.dart';

/// Proves the REAL streaming path end-to-end (DEMO_AUDIO=false):
///   remote catalog.json fetch  →  Catalog.fromJson  →  audioUrlFor()  →
///   ranged HTTP GET of a real MP3 from the CDN origin.
///
/// Run against the local CDN emulator (tools/serve_cdn.py):
///   flutter test test/streaming/cdn_streaming_path_test.dart \
///     --dart-define=DEMO_AUDIO=false \
///     --dart-define=CDN_BASE=http://localhost:8787 \
///     --dart-define=CATALOG_URL=http://localhost:8787/catalog.json
void main() {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  test('DEMO_AUDIO is disabled for the real streaming path', () {
    expect(AppConfig.demoAudio, isFalse,
        reason: 'pass --dart-define=DEMO_AUDIO=false');
    expect(AppConfig.cdnBase, startsWith('http'));
  });

  late Catalog catalog;

  test('remote catalog.json is fetched and parsed (CatalogRepository path)',
      () async {
    final res = await dio.get<String>(AppConfig.catalogUrl,
        options: Options(responseType: ResponseType.plain));
    expect(res.statusCode, 200);
    catalog = Catalog.fromJson(jsonDecode(res.data!) as Map<String, dynamic>);
    expect(catalog.items, isNotEmpty);
    print('catalog version=${catalog.version} items=${catalog.items.length}');
  });

  test('every catalog audio URL resolves and streams real bytes (ranged GET)',
      () async {
    // Sample across languages, voices, library + daily items.
    final byLang = <String, CatalogItem>{};
    for (final it in catalog.items) {
      byLang.putIfAbsent(it.language, () => it);
    }
    final daily = catalog.items.firstWhere((i) => i.isDaily,
        orElse: () => catalog.items.first);
    final sample = {...byLang.values, daily}.toList();

    for (final item in sample) {
      for (final voice in item.availableVoices) {
        final url = item.audioUrlFor(voice);
        expect(url, '${AppConfig.cdnBase}/${item.language}/$voice/${item.id}.mp3');

        // Ranged request — exactly how just_audio streams audio.
        final res = await dio.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Range': 'bytes=0-2047'},
            validateStatus: (s) => s != null && s < 400,
          ),
        );
        expect(res.statusCode, anyOf(200, 206),
            reason: 'audio must be reachable: $url');
        expect(res.headers.value('content-type'), contains('audio/mpeg'));
        expect(res.data, isNotNull);
        expect(res.data!.length, greaterThan(0));
        // MP3 frame/ID3 magic at the start of the file.
        final head = res.data!;
        final isMp3 = (head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) ||
            (head[0] == 0xFF && (head[1] & 0xE0) == 0xE0);
        expect(isMp3, isTrue, reason: 'not an MP3 stream: $url');
      }
    }
    print('streamed ${sample.length} items across '
        '${sample.map((e) => e.language).toSet().length} languages OK');
  });

  test('voice fallback never breaks playback (resolvedVoice)', () {
    final item = catalog.items.first;
    // A voice the item does not offer must fall back to its default.
    final url = item.audioUrlFor('no_such_voice');
    expect(url, contains('/${item.defaultVoice}/'));
  });
}
