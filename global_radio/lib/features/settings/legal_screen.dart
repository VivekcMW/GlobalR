/// Legal documents screen (Privacy Policy, Terms of Service).
///
/// Displays legal documents either from bundled assets or opens web URLs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';

/// Legal document type.
enum LegalDocType {
  privacy('Privacy Policy', 'privacy'),
  terms('Terms of Service', 'terms');

  const LegalDocType(this.title, this.slug);
  final String title;
  final String slug;

  String get webUrl => '${AppConfig.legalBaseUrl}/$slug';
}

/// Legal documents screen that displays privacy policy or terms.
class LegalScreen extends ConsumerWidget {
  final LegalDocType docType;

  const LegalScreen({super.key, required this.docType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(docType.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (docType) {
      case LegalDocType.privacy:
        return const _PrivacyPolicyContent();
      case LegalDocType.terms:
        return const _TermsContent();
    }
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Privacy Policy — Global Radio'),
        const SizedBox(height: 8),
        Text(
          'Effective Date: January 1, 2025\nLast Updated: January 1, 2025',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('1. Information We Collect'),
        const SizedBox(height: 12),
        _SubsectionTitle('1.1 Information You Provide'),
        const _BulletPoint('Account Information: If you sign in with Google or Apple, we receive your display name and email address.'),
        const _BulletPoint('Language Preferences: Your selected languages for content playback.'),
        const _BulletPoint('Interest Selections: Topics you choose to follow.'),
        const SizedBox(height: 12),
        _SubsectionTitle('1.2 Automatically Collected Information'),
        const _BulletPoint('Device Information: Device model, OS version, app version.'),
        const _BulletPoint('Usage Analytics: Anonymous playback statistics.'),
        const _BulletPoint('Push Notification Tokens: If notifications are enabled.'),
        const SizedBox(height: 12),
        _SubsectionTitle('1.3 Information We Do NOT Collect'),
        const _BulletPoint('Precise location data'),
        const _BulletPoint('Contacts or call logs'),
        const _BulletPoint('Microphone or camera access (except for voice search)'),
        const SizedBox(height: 24),
        
        _SectionTitle('2. How We Use Your Information'),
        const _BulletPoint('Deliver personalized audio content'),
        const _BulletPoint('Send daily updates via push notifications'),
        const _BulletPoint('Improve content recommendations'),
        const _BulletPoint('Debug technical issues'),
        const SizedBox(height: 24),
        
        _SectionTitle('3. Data Storage & Security'),
        const _BulletPoint('Preferences stored locally on your device using encrypted storage'),
        const _BulletPoint('Cloud data stored securely in Firebase (Google Cloud)'),
        const _BulletPoint('We do not sell or share your data with third parties'),
        const SizedBox(height: 24),
        
        _SectionTitle('4. Push Notifications'),
        const _BulletPoint('Push notifications are opt-in'),
        const _BulletPoint('Disable anytime in app settings'),
        const _BulletPoint('We use Firebase Cloud Messaging'),
        const SizedBox(height: 24),
        
        _SectionTitle('5. Children\'s Privacy'),
        const Text(
          'Global Radio includes content suitable for children. We do not knowingly collect personal information from children under 13.',
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('6. Your Rights'),
        const _BulletPoint('Access your personal data'),
        const _BulletPoint('Request correction of inaccurate data'),
        const _BulletPoint('Request deletion of your data'),
        const _BulletPoint('Opt out of push notifications'),
        const SizedBox(height: 16),
        Text(
          'Contact: privacy@globalradio.app',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('7. Changes to This Policy'),
        const Text(
          'We may update this Privacy Policy periodically. We will notify you of significant changes through the App.',
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Terms of Service — Global Radio'),
        const SizedBox(height: 8),
        Text(
          'Effective Date: January 1, 2025\nLast Updated: January 1, 2025',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('1. Acceptance of Terms'),
        const Text(
          'By downloading, installing, or using Global Radio, you agree to be bound by these Terms of Service. If you do not agree, do not use the App.',
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('2. Description of Service'),
        const Text(
          'Global Radio is a personalized audio content streaming application that provides stories, devotional content, astrology readings, and other audio content in multiple Indian languages.',
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('3. User Accounts'),
        const _BulletPoint('You may use the app without an account'),
        const _BulletPoint('Account sign-in enables sync across devices'),
        const _BulletPoint('You are responsible for maintaining account security'),
        const _BulletPoint('We reserve the right to suspend accounts that violate these terms'),
        const SizedBox(height: 24),
        
        _SectionTitle('4. Content'),
        const _BulletPoint('All content is legally sourced (public domain, CC BY, or licensed)'),
        const _BulletPoint('Content is for personal, non-commercial use only'),
        const _BulletPoint('Do not redistribute, copy, or modify our content'),
        const SizedBox(height: 24),
        
        _SectionTitle('5. Premium Features'),
        const _BulletPoint('Premium subscription removes ads and unlocks additional features'),
        const _BulletPoint('Subscriptions auto-renew unless cancelled'),
        const _BulletPoint('Cancellation takes effect at end of billing period'),
        const _BulletPoint('Refunds handled by Apple App Store / Google Play Store'),
        const SizedBox(height: 24),
        
        _SectionTitle('6. Prohibited Conduct'),
        const _BulletPoint('Reverse engineering or decompiling the app'),
        const _BulletPoint('Circumventing premium feature restrictions'),
        const _BulletPoint('Using the app for illegal purposes'),
        const _BulletPoint('Interfering with app operation or servers'),
        const SizedBox(height: 24),
        
        _SectionTitle('7. Intellectual Property'),
        const Text(
          'The App, including its design, logo, and features, is owned by Global Radio. Content is used under appropriate licenses or is in the public domain.',
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('8. Disclaimers'),
        const _BulletPoint('App provided "as is" without warranties'),
        const _BulletPoint('We do not guarantee uninterrupted service'),
        const _BulletPoint('Astrology content is for entertainment purposes'),
        const SizedBox(height: 24),
        
        _SectionTitle('9. Limitation of Liability'),
        const Text(
          'To the maximum extent permitted by law, Global Radio shall not be liable for any indirect, incidental, or consequential damages.',
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('10. Governing Law'),
        const Text(
          'These Terms are governed by the laws of India. Any disputes shall be resolved in the courts of Bangalore, Karnataka.',
        ),
        const SizedBox(height: 24),
        
        _SectionTitle('11. Contact Us'),
        Text(
          'For questions about these Terms, contact: legal@globalradio.app',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SubsectionTitle extends StatelessWidget {
  final String text;
  const _SubsectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
