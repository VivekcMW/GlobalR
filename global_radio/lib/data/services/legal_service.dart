import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';

/// Service for handling legal document links (Privacy Policy, Terms of Service).
class LegalService {
  /// Open the privacy policy in browser.
  Future<bool> openPrivacyPolicy() async {
    return _openUrl(AppConfig.privacyPolicyUrl);
  }

  /// Open the terms of service in browser.
  Future<bool> openTermsOfService() async {
    return _openUrl(AppConfig.termsOfServiceUrl);
  }

  /// Open the privacy email for data requests.
  Future<bool> openPrivacyEmail({String? subject}) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: AppConfig.privacyEmail,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );

    if (await canLaunchUrl(emailUri)) {
      return await launchUrl(emailUri);
    }
    return false;
  }

  /// Open support email.
  Future<bool> openSupportEmail({String? subject}) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );

    if (await canLaunchUrl(emailUri)) {
      return await launchUrl(emailUri);
    }
    return false;
  }

  /// Open the app store page (Play Store on Android, App Store on iOS).
  Future<bool> openAppStore() async {
    // Try Play Store on Android, App Store on iOS
    final urls = [
      AppConfig.playStoreUrl,
      AppConfig.appStoreUrl,
    ];

    for (final url in urls) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return false;
  }

  /// Generic URL opener.
  Future<bool> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      debugPrint('LegalService: Cannot launch URL: $url');
      return false;
    } catch (e) {
      debugPrint('LegalService: Error opening URL: $e');
      return false;
    }
  }
}

/// Legal service provider.
final legalServiceProvider = Provider<LegalService>((ref) {
  return LegalService();
});
