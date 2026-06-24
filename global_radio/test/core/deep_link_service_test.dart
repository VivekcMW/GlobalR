import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/core/deep_linking/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    late DeepLinkService service;

    setUp(() {
      service = DeepLinkService();
    });

    group('parseUri', () {
      test('parses content links', () {
        final uri = Uri.parse('https://globalradio.app/content/story-123');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.content);
        expect(data.id, 'story-123');
      });

      test('parses play links as content', () {
        final uri = Uri.parse('https://globalradio.app/play/item-456');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.content);
        expect(data.id, 'item-456');
      });

      test('parses referral links', () {
        final uri = Uri.parse('https://globalradio.app/invite/REF12345');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.referral);
        expect(data.id, 'REF12345');
      });

      test('parses category links', () {
        final uri = Uri.parse('https://globalradio.app/category/devotion');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.category);
        expect(data.id, 'devotion');
      });

      test('parses premium links', () {
        final uri = Uri.parse('https://globalradio.app/premium');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.premium);
      });

      test('parses settings links', () {
        final uri = Uri.parse('https://globalradio.app/settings');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.settings);
      });

      test('parses today/astrology links', () {
        final uri = Uri.parse('https://globalradio.app/today/aries');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.today);
        expect(data.id, 'aries');
      });

      test('handles unknown paths', () {
        final uri = Uri.parse('https://globalradio.app/unknown/path');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.unknown);
      });

      test('handles empty paths', () {
        final uri = Uri.parse('https://globalradio.app/');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.unknown);
      });

      test('captures query parameters', () {
        final uri = Uri.parse('https://globalradio.app/content/story-1?source=push&campaign=daily');
        final data = service.parseUri(uri);

        expect(data.type, DeepLinkType.content);
        expect(data.params['source'], 'push');
        expect(data.params['campaign'], 'daily');
      });
    });

    group('getRouteForDeepLink', () {
      test('returns player route for content links', () {
        final data = DeepLinkData(
          type: DeepLinkType.content,
          id: 'story-123',
          originalUri: Uri.parse('https://globalradio.app/content/story-123'),
        );

        final route = service.getRouteForDeepLink(data);
        expect(route, '/player?item=story-123');
      });

      test('returns home route for content links without id', () {
        final data = DeepLinkData(
          type: DeepLinkType.content,
          originalUri: Uri.parse('https://globalradio.app/content'),
        );

        final route = service.getRouteForDeepLink(data);
        expect(route, '/home');
      });

      test('returns home with category for category links', () {
        final data = DeepLinkData(
          type: DeepLinkType.category,
          id: 'devotion',
          originalUri: Uri.parse('https://globalradio.app/category/devotion'),
        );

        final route = service.getRouteForDeepLink(data);
        expect(route, '/home?category=devotion');
      });

      test('returns home and calls callback for referral links', () {
        String? capturedCode;
        final data = DeepLinkData(
          type: DeepLinkType.referral,
          id: 'REF12345',
          originalUri: Uri.parse('https://globalradio.app/invite/REF12345'),
        );

        final route = service.getRouteForDeepLink(
          data,
          onReferralCode: (code) => capturedCode = code,
        );

        expect(route, '/home');
        expect(capturedCode, 'REF12345');
      });

      test('returns settings for premium links', () {
        final data = DeepLinkData(
          type: DeepLinkType.premium,
          originalUri: Uri.parse('https://globalradio.app/premium'),
        );

        final route = service.getRouteForDeepLink(data);
        expect(route, '/settings');
      });

      test('returns today with sign for today links', () {
        final data = DeepLinkData(
          type: DeepLinkType.today,
          id: 'aries',
          originalUri: Uri.parse('https://globalradio.app/today/aries'),
        );

        final route = service.getRouteForDeepLink(data);
        expect(route, '/today?sign=aries');
      });

      test('returns null for unknown links', () {
        final data = DeepLinkData(
          type: DeepLinkType.unknown,
          originalUri: Uri.parse('https://globalradio.app/unknown'),
        );

        final route = service.getRouteForDeepLink(data);
        expect(route, isNull);
      });
    });
  });
}
