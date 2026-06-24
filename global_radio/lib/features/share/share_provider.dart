import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';
import 'share_service.dart';

/// Provider for the share service.
final shareServiceProvider = Provider<ShareService>((ref) => ShareService());

/// Provider for the referral service.
final referralServiceProvider = Provider<ReferralService>((ref) => ReferralService());

/// Provider for the user's referral code.
final referralCodeProvider = Provider<String>((ref) {
  // Referral codes are generated from user ID in a real implementation.
  // For now, generate a temporary code.
  final service = ref.read(referralServiceProvider);
  return service.getOrCreateCode(null);
});

/// Provider for referral statistics (would come from backend).
class ReferralStats {
  final int totalReferrals;
  final int successfulReferrals;
  final int pendingRewards;

  const ReferralStats({
    this.totalReferrals = 0,
    this.successfulReferrals = 0,
    this.pendingRewards = 0,
  });
}

final referralStatsProvider = Provider<ReferralStats>((ref) {
  // In a real implementation, this would fetch from the backend.
  return const ReferralStats();
});
