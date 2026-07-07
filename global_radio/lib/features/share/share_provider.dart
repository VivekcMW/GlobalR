import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';
import 'share_service.dart';

/// Provider for the share service.
final shareServiceProvider = Provider<ShareService>((ref) => ShareService());

/// Provider for the referral service.
final referralServiceProvider = Provider<ReferralService>((ref) => ReferralService());

/// Provider for the user's referral code.
final referralCodeProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(referralServiceProvider);
  final profile = ref.watch(profileProvider);
  
  if (profile.userId != null) {
    return await service.getOrCreateCode(profile.userId!);
  }
  
  // Return a temporary code if not logged in
  return 'GUEST1';
});

/// Provider for referral statistics.
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

final referralStatsProvider = FutureProvider<ReferralStats>((ref) async {
  final profile = ref.watch(profileProvider);
  
  if (profile.userId == null) {
    return const ReferralStats();
  }
  
  final docSnap = await FirebaseFirestore.instance.collection('users').doc(profile.userId).get();
  if (!docSnap.exists) {
    return const ReferralStats();
  }
  
  final data = docSnap.data() as Map<String, dynamic>?;
  if (data == null) return const ReferralStats();
  
  return ReferralStats(
    totalReferrals: data['totalReferrals'] ?? 0,
    successfulReferrals: data['successfulReferrals'] ?? 0,
    pendingRewards: data['pendingRewards'] ?? 0,
  );
});
