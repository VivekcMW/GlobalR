/// Deep linking service for handling app links and universal links.
///
/// Supports:
/// - Content sharing links (globalradio.app/content/{id})
/// - Referral links (globalradio.app/invite/{code})
/// - Category links (globalradio.app/category/{name})
library;

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/providers.dart';

/// Deep link types.
enum DeepLinkType {
  content,
  category,
  referral,
  premium,
  settings,
  today,
  unknown,
}

/// Parsed deep link data.
class DeepLinkData {
  final DeepLinkType type;
  final String? id;
  final Map<String, String> params;
  final Uri originalUri;

  const DeepLinkData({
    required this.type,
    this.id,
    this.params = const {},
    required this.originalUri,
  });

  @override
  String toString() => 'DeepLinkData($type, id: $id, params: $params)';
}

/// Deep linking service.
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  
  /// Parse a URI into a DeepLinkData.
  DeepLinkData parseUri(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.isEmpty) {
      return DeepLinkData(
        type: DeepLinkType.unknown,
        originalUri: uri,
      );
    }

    final firstSegment = pathSegments[0];
    final id = pathSegments.length > 1 ? pathSegments[1] : null;

    switch (firstSegment) {
      case 'content':
      case 'item':
      case 'play':
        return DeepLinkData(
          type: DeepLinkType.content,
          id: id,
          params: uri.queryParameters,
          originalUri: uri,
        );
      case 'category':
      case 'interest':
        return DeepLinkData(
          type: DeepLinkType.category,
          id: id,
          params: uri.queryParameters,
          originalUri: uri,
        );
      case 'invite':
      case 'referral':
      case 'ref':
        return DeepLinkData(
          type: DeepLinkType.referral,
          id: id,
          params: uri.queryParameters,
          originalUri: uri,
        );
      case 'premium':
      case 'subscribe':
        return DeepLinkData(
          type: DeepLinkType.premium,
          params: uri.queryParameters,
          originalUri: uri,
        );
      case 'settings':
        return DeepLinkData(
          type: DeepLinkType.settings,
          id: id,
          params: uri.queryParameters,
          originalUri: uri,
        );
      case 'today':
      case 'daily':
      case 'astrology':
        return DeepLinkData(
          type: DeepLinkType.today,
          id: id, // Optional zodiac sign
          params: uri.queryParameters,
          originalUri: uri,
        );
      default:
        return DeepLinkData(
          type: DeepLinkType.unknown,
          originalUri: uri,
        );
    }
  }

  /// Handle a deep link by navigating to the appropriate route.
  /// 
  /// [onReferralCode] is called when a referral code is found, allowing
  /// the caller to store it appropriately.
  String? getRouteForDeepLink(
    DeepLinkData data, {
    void Function(String code)? onReferralCode,
  }) {
    switch (data.type) {
      case DeepLinkType.content:
        if (data.id != null) {
          return '/player?item=${data.id}';
        }
        return '/home';
      case DeepLinkType.category:
        if (data.id != null) {
          return '/home?category=${data.id}';
        }
        return '/home';
      case DeepLinkType.referral:
        // Store referral code and navigate to home
        if (data.id != null) {
          debugPrint('DeepLinkService: Referral code received: ${data.id}');
          onReferralCode?.call(data.id!);
        }
        return '/home';
      case DeepLinkType.premium:
        return '/settings'; // Navigate to settings where premium is
      case DeepLinkType.settings:
        return '/settings';
      case DeepLinkType.today:
        // Navigate to Today tab, optionally with zodiac sign
        if (data.id != null) {
          return '/today?sign=${data.id}';
        }
        return '/today';
      case DeepLinkType.unknown:
        return null;
    }
  }

  /// Get the initial deep link (app launched from link).
  Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      debugPrint('Error getting initial link: $e');
      return null;
    }
  }

  /// Stream of incoming deep links.
  Stream<Uri> get onLinkReceived => _appLinks.uriLinkStream;

  /// Generate a share link for content.
  String generateContentLink(String contentId) {
    return 'https://globalradio.app/content/$contentId';
  }

  /// Generate a referral link.
  String generateReferralLink(String referralCode) {
    return 'https://globalradio.app/invite/$referralCode';
  }
}

/// Deep link service provider.
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

/// Initial deep link provider.
final initialDeepLinkProvider = FutureProvider<DeepLinkData?>((ref) async {
  final service = ref.watch(deepLinkServiceProvider);
  final uri = await service.getInitialLink();
  if (uri != null) {
    return service.parseUri(uri);
  }
  return null;
});

/// Deep link stream provider.
final deepLinkStreamProvider = StreamProvider<DeepLinkData>((ref) {
  final service = ref.watch(deepLinkServiceProvider);
  return service.onLinkReceived.map((uri) => service.parseUri(uri));
});
