/// Referral system for sharing and earning rewards.
///
/// Features:
/// - Generate unique referral codes
/// - Track referral redemptions
/// - Award premium days for successful referrals
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/deep_linking/deep_link_service.dart';
import '../../data/local/local_store.dart';
import '../../shared/providers/providers.dart';

/// Referral reward configuration.
class ReferralConfig {
  static const int daysPerReferral = 7;
  static const int maxReferrals = 10;
  static const String codePrefix = 'GR';
}

/// Referral data model.
class ReferralData {
  final String code;
  final int referralCount;
  final int daysEarned;
  final DateTime? lastReferralDate;
  final List<String> redeemedCodes;

  const ReferralData({
    required this.code,
    this.referralCount = 0,
    this.daysEarned = 0,
    this.lastReferralDate,
    this.redeemedCodes = const [],
  });

  ReferralData copyWith({
    String? code,
    int? referralCount,
    int? daysEarned,
    DateTime? lastReferralDate,
    List<String>? redeemedCodes,
  }) {
    return ReferralData(
      code: code ?? this.code,
      referralCount: referralCount ?? this.referralCount,
      daysEarned: daysEarned ?? this.daysEarned,
      lastReferralDate: lastReferralDate ?? this.lastReferralDate,
      redeemedCodes: redeemedCodes ?? this.redeemedCodes,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'referralCount': referralCount,
        'daysEarned': daysEarned,
        'lastReferralDate': lastReferralDate?.toIso8601String(),
        'redeemedCodes': redeemedCodes,
      };

  factory ReferralData.fromJson(Map<String, dynamic> json) => ReferralData(
        code: json['code'] as String,
        referralCount: json['referralCount'] as int? ?? 0,
        daysEarned: json['daysEarned'] as int? ?? 0,
        lastReferralDate: json['lastReferralDate'] != null
            ? DateTime.parse(json['lastReferralDate'] as String)
            : null,
        redeemedCodes: (json['redeemedCodes'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

/// Referral service.
class ReferralService {
  final LocalStore _storage;
  final DeepLinkService _deepLinkService;

  ReferralService(this._storage, this._deepLinkService);

  static const _storageKey = 'referral_data';

  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Deterministic checksum character over a code payload, so codes are
  /// self-verifying client-side without a backend round-trip.
  static String _checksumChar(String payload) {
    var sum = 0;
    for (final unit in payload.codeUnits) {
      sum = (sum + unit) % _codeChars.length;
    }
    return _codeChars[sum];
  }

  /// Generate a unique referral code: prefix + 5 random chars + checksum.
  String _generateCode() {
    final random = Random();
    final payload = StringBuffer();
    for (var i = 0; i < 5; i++) {
      payload.write(_codeChars[random.nextInt(_codeChars.length)]);
    }
    return '${ReferralConfig.codePrefix}$payload${_checksumChar(payload.toString())}';
  }

  /// Prefix for premium gift codes (e.g. "gift a month to your parents").
  static const giftPrefix = 'GP';

  /// Generate a self-verifying premium gift code.
  /// TODO(backend): record issued gift codes server-side and charge the
  /// gifter via IAP; client-side codes are for the pilot only.
  String generateGiftCode() {
    final random = Random();
    final payload = StringBuffer();
    for (var i = 0; i < 5; i++) {
      payload.write(_codeChars[random.nextInt(_codeChars.length)]);
    }
    return '$giftPrefix$payload${_checksumChar(payload.toString())}';
  }

  /// Validate a premium gift code's structure and checksum.
  static bool isValidGiftCode(String rawCode) {
    final code = rawCode.toUpperCase();
    if (!code.startsWith(giftPrefix) || code.length != 8) return false;
    final body = code.substring(giftPrefix.length);
    if (!body.split('').every(_codeChars.contains)) return false;
    final payload = body.substring(0, body.length - 1);
    return _checksumChar(payload) == body[body.length - 1];
  }

  /// Validate a referral code's structure and checksum.
  static bool isValidCode(String rawCode) {
    final code = rawCode.toUpperCase();
    if (!code.startsWith(ReferralConfig.codePrefix) || code.length != 8) {
      return false;
    }
    final body = code.substring(ReferralConfig.codePrefix.length);
    if (!body.split('').every(_codeChars.contains)) return false;
    final payload = body.substring(0, body.length - 1);
    return _checksumChar(payload) == body[body.length - 1];
  }

  /// Get or create referral data.
  Future<ReferralData> getReferralData() async {
    final json = _storage.getSetting<Map<String, dynamic>>(_storageKey);
    if (json != null) {
      return ReferralData.fromJson(Map<String, dynamic>.from(json));
    }
    // Generate new referral code for new users
    final newData = ReferralData(code: _generateCode());
    await _saveReferralData(newData);
    return newData;
  }

  Future<void> _saveReferralData(ReferralData data) async {
    await _storage.putSetting(_storageKey, data.toJson());
  }

  /// Get the referral share link.
  Future<String> getReferralLink() async {
    final data = await getReferralData();
    return _deepLinkService.generateReferralLink(data.code);
  }

  /// Redeem a referral code (for the user who received the invite).
  Future<ReferralRedeemResult> redeemCode(String code) async {
    final data = await getReferralData();

    // Premium gift codes are checked first — they can be redeemed even by
    // users who already used a referral code.
    if (isValidGiftCode(code)) {
      return ReferralRedeemResult.giftPremium;
    }

    // Can't use own code
    if (code.toUpperCase() == data.code) {
      return ReferralRedeemResult.ownCode;
    }

    // Already redeemed a code
    if (data.redeemedCodes.isNotEmpty) {
      return ReferralRedeemResult.alreadyRedeemed;
    }

    // Validate code structure + checksum (codes are self-verifying).
    if (!isValidCode(code)) {
      return ReferralRedeemResult.invalidCode;
    }

    // Note: crediting the *inviter* happens when they receive the deep link
    // callback (creditReferralBonus); no backend round-trip is required for
    // the local redemption record.
    final updatedData = data.copyWith(
      redeemedCodes: [...data.redeemedCodes, code.toUpperCase()],
    );
    await _saveReferralData(updatedData);

    return ReferralRedeemResult.success;
  }

  /// Credit referral bonus (called when someone uses your code).
  Future<void> creditReferralBonus() async {
    final data = await getReferralData();
    if (data.referralCount >= ReferralConfig.maxReferrals) {
      return; // Max referrals reached
    }

    final updatedData = data.copyWith(
      referralCount: data.referralCount + 1,
      daysEarned: data.daysEarned + ReferralConfig.daysPerReferral,
      lastReferralDate: DateTime.now(),
    );
    await _saveReferralData(updatedData);
  }
}

/// Referral redeem result.
enum ReferralRedeemResult {
  success,
  giftPremium,
  invalidCode,
  ownCode,
  alreadyRedeemed,
  error,
}

/// Referral service provider.
final referralServiceProvider = Provider<ReferralService>((ref) {
  final storage = ref.watch(localStoreProvider);
  final deepLink = ref.watch(deepLinkServiceProvider);
  return ReferralService(storage, deepLink);
});

/// Referral data provider.
final referralDataProvider = FutureProvider<ReferralData>((ref) async {
  final service = ref.watch(referralServiceProvider);
  return service.getReferralData();
});

/// Referral screen.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _shareReferral() async {
    final service = ref.read(referralServiceProvider);
    final link = await service.getReferralLink();
    await SharePlus.instance.share(ShareParams(
      text:
          'Listen to Global Radio with me! Download the app and use my referral link to get free premium: $link',
      subject: 'Try Global Radio',
    ));
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final service = ref.read(referralServiceProvider);
    final result = await service.redeemCode(code);

    if (!mounted) return;

    if (result == ReferralRedeemResult.giftPremium) {
      // Local-only unlock: isPremium in Firestore is server-verified-purchase
      // only (see verifyPurchase), so a referral gift can't write it there.
      ref.read(profileProvider.notifier).applyRemoteEntitlement(true);
    }

    final message = switch (result) {
      ReferralRedeemResult.success => 'Referral code redeemed! Enjoy your free premium days.',
      ReferralRedeemResult.giftPremium => 'Gift redeemed — Premium unlocked! 🎁',
      ReferralRedeemResult.invalidCode => 'Invalid referral code. Please check and try again.',
      ReferralRedeemResult.ownCode => 'You cannot use your own referral code.',
      ReferralRedeemResult.alreadyRedeemed => 'You have already redeemed a referral code.',
      ReferralRedeemResult.error => 'An error occurred. Please try again.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result == ReferralRedeemResult.success ||
                result == ReferralRedeemResult.giftPremium
            ? Colors.green
            : null,
      ),
    );

    if (result == ReferralRedeemResult.success ||
        result == ReferralRedeemResult.giftPremium) {
      _codeController.clear();
      ref.invalidate(referralDataProvider);
    }
  }

  Future<void> _shareGiftCode() async {
    final service = ref.read(referralServiceProvider);
    final code = service.generateGiftCode();
    await SharePlus.instance.share(ShareParams(
      text: '🎁 I’m gifting you Global Radio Premium!\n\n'
          'Download the app and redeem this code on the Invite Friends '
          'screen: $code',
      subject: 'A Global Radio Premium gift for you',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final referralData = ref.watch(referralDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Friends'),
      ),
      body: referralData.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header illustration
              Icon(
                Icons.card_giftcard,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Share & Earn',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get ${ReferralConfig.daysPerReferral} days of premium for each friend who joins!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // Your referral code card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Your referral code'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data.code,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            onPressed: () => _copyCode(data.code),
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Share button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _shareReferral,
                  icon: const Icon(Icons.share),
                  label: const Text('Share with Friends'),
                ),
              ),
              const SizedBox(height: 12),

              // Gift premium — perfect for gifting to parents/family.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _shareGiftCode,
                  icon: const Icon(Icons.redeem),
                  label: const Text('Gift Premium to someone'),
                ),
              ),
              const SizedBox(height: 32),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Friends Invited',
                      value: '${data.referralCount}',
                      icon: Icons.people,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Days Earned',
                      value: '${data.daysEarned}',
                      icon: Icons.stars,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Redeem code section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Have a referral code?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _redeemCode,
                    child: const Text('Redeem'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // How it works
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'How it works',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              _HowItWorksStep(
                number: 1,
                title: 'Share your code',
                description: 'Send your referral link to friends',
              ),
              _HowItWorksStep(
                number: 2,
                title: 'Friend joins',
                description: 'They download the app and sign up',
              ),
              _HowItWorksStep(
                number: 3,
                title: 'You both earn',
                description: 'Get ${ReferralConfig.daysPerReferral} free premium days each!',
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              '$number',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
