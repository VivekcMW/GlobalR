import 'dart:math';

import 'package:share_plus/share_plus.dart';

import '../../data/models/catalog_item.dart';

/// Service for sharing content and generating referral links.
class ShareService {
  static const _appName = 'Global Radio';
  static const _baseUrl = 'https://globalradio.app';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=app.globalradio';
  static const _appStoreUrl =
      'https://apps.apple.com/app/global-radio/id000000000';

  /// Share a catalog item with a deep link.
  Future<void> shareItem(CatalogItem item, {String? referralCode}) async {
    final link = generateItemLink(item.id, referralCode: referralCode);
    final text = _buildShareText(item, link);

    await Share.share(
      text,
      subject: 'Listen to "${item.title}" on $_appName',
    );
  }

  /// Share the app with a referral code.
  Future<void> shareApp({String? referralCode}) async {
    final link = referralCode != null
        ? '$_baseUrl/invite?ref=$referralCode'
        : _baseUrl;

    final text = '''
🎧 Discover Global Radio - India's personalized audio app!

Listen to astrology, devotion, moral stories & more in your language.

Download now: $link

Or search "Global Radio" on your app store.
''';

    await Share.share(
      text,
      subject: 'Join me on $_appName!',
    );
  }

  /// Generate a deep link for a specific item.
  String generateItemLink(String itemId, {String? referralCode}) {
    var link = '$_baseUrl/item/$itemId';
    if (referralCode != null) {
      link += '?ref=$referralCode';
    }
    return link;
  }

  /// Generate a referral link.
  String generateReferralLink(String referralCode) {
    return '$_baseUrl/invite?ref=$referralCode';
  }

  String _buildShareText(CatalogItem item, String link) {
    final interest = item.primaryInterest;
    final emoji = _interestEmoji(interest);

    return '''
$emoji Listen to "${item.title}" on $_appName!

$link

Download the app to explore more personalized audio content in your language.
''';
  }

  String _interestEmoji(String interest) {
    switch (interest) {
      case 'kids':
        return '🧒';
      case 'moral':
        return '📖';
      case 'devotion':
        return '🪔';
      case 'astrology':
        return '✨';
      default:
        return '🎧';
    }
  }
}

/// Manages referral codes and tracking.
class ReferralService {
  final String Function() _generateCode;
  
  ReferralService({String Function()? generateCode})
      : _generateCode = generateCode ?? _defaultGenerateCode;

  /// Generate a unique referral code for the user.
  static String _defaultGenerateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Get or create the user's referral code.
  /// In a real implementation, this would be stored in Hive/Firebase.
  String getOrCreateCode(String? existingCode) {
    if (existingCode != null && existingCode.isNotEmpty) {
      return existingCode;
    }
    return _generateCode();
  }

  /// Validate a referral code format.
  bool isValidCode(String code) {
    if (code.length != 6) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(code);
  }

  /// Track a referral (would call backend in real implementation).
  Future<void> trackReferral(String referralCode, String newUserId) async {
    // In a real implementation, this would:
    // 1. Validate the referral code
    // 2. Credit the referrer
    // 3. Give bonus to new user
    // For now, this is a stub.
  }
}
