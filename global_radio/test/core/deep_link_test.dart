import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/core/deep_linking/deep_link_service.dart';

void main() {
  late DeepLinkService service;

  setUp(() {
    service = DeepLinkService();
  });

  group('DeepLinkService', () {
    group('parseUri', () {
      test('parses content links', () {
        final uri = Uri.parse('https://globalradio.app/content/item123');
        final data = service.parseUri(uri);

        expect(data.type, equals(DeepLinkType.content));
        expect(data.id, equals('item123'));
      });

      test('parses play links as content', () {
        final uri = Uri.parse('https://globalradio.app/play/item456');
        final data = service.parseUri(uri);

        expect(data.type, equals(DeepLinkType.content));
        expect(data.id, equals('item456'));
      });

      test('parses category links', () {
        final uri = Uri.parse('https://globalradio.app/category/astrology');
        final data = service.parseUri(uri);

        expect(data.type, equals(DeepLinkType.category));
        expect(data.id, equals('astrology'));
      });

      test('parses referral links', () {
        final uri = Uri.parse('https://globalradio.app/invite/GRABC123');
        final data = service.parseUri(uri);

        expect(data.type, equals(DeepLinkType.referral));
        expect(data.id, equals('GRABC123'));
      });

      test('parses premium links', () {
        final uri = Uri.parse('https://globalradio.app/premium');
        final data = service.parseUri(uri);

        expect(data.type, equals(DeepLinkType.premium));
      });

      test('parses settings links', () {
        final uri = Uri.parse('https://globalradio.app/settings');
        final data = service.parseUri(uri);

        expect(data.type, equals(DeepLinkType.settings));
      });

      test('returns unknown for unrecognized paths', () {
        final uri = Uri.parse('https://globalradio.app/unknown/path');
        final data = service.parseUri(uri);

        expect(data.type, equals(DeepLinkType.unknown));
      });

      test('preserves query parameters', () {
        final uri = Uri.parse('https://globalradio.app/content/item?source=push');
        final data = service.parseUri(uri);

        expect(data.params['source'], equals('push'));
      });
    });

    group('getRouteForDeepLink', () {
      test('returns player route for content', () {
        final data = DeepLinkData(
          type: DeepLinkType.content,
          id: 'item123',
          originalUri: Uri.parse('https://globalradio.app/content/item123'),
        );

        expect(service.getRouteForDeepLink(data), equals('/player?item=item123'));
      });

      test('returns home route for content without id', () {
        final data = DeepLinkData(
          type: DeepLinkType.content,
          originalUri: Uri.parse('https://globalradio.app/content'),
        );

        expect(service.getRouteForDeepLink(data), equals('/home'));
      });

      test('returns home route with category for category links', () {
        final data = DeepLinkData(
          type: DeepLinkType.category,
          id: 'news',
          originalUri: Uri.parse('https://globalradio.app/category/news'),
        );

        expect(service.getRouteForDeepLink(data), equals('/home?category=news'));
      });

      test('returns settings for premium links', () {
        final data = DeepLinkData(
          type: DeepLinkType.premium,
          originalUri: Uri.parse('https://globalradio.app/premium'),
        );

        expect(service.getRouteForDeepLink(data), equals('/settings'));
      });

      test('returns null for unknown links', () {
        final data = DeepLinkData(
          type: DeepLinkType.unknown,
          originalUri: Uri.parse('https://globalradio.app/unknown'),
        );

        expect(service.getRouteForDeepLink(data), isNull);
      });
    });

    group('link generation', () {
      test('generates content links', () {
        final link = service.generateContentLink('item123');
        expect(link, equals('https://globalradio.app/content/item123'));
      });

      test('generates referral links', () {
        final link = service.generateReferralLink('GRABC123');
        expect(link, equals('https://globalradio.app/invite/GRABC123'));
      });
    });
  });
}
