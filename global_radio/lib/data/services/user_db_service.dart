import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../models/user_profile.dart';

abstract class UserDbService {
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> fetchProfile(String userId);

  /// Server-verified premium status. Only the `verifyPurchase` Cloud Function
  /// (via the Admin SDK) ever writes this field — Firestore rules reject
  /// client writes to it — so this stream is the single source of truth for
  /// entitlement, independent of whatever the client last set locally.
  Stream<bool> watchPremiumStatus(String userId);
}

class FirestoreUserDbService implements UserDbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (profile.userId == null) return;

    // Entitlement fields are server-owned; never send them from the client
    // (Firestore rules reject the write, but drop them here too so a save
    // never silently fails just because it also touched an unrelated field).
    final data = profile.toJson()
      ..remove('isPremium')
      ..remove('premiumProductId')
      ..remove('premiumPlatform')
      ..remove('premiumExpiresAt');

    try {
      await _firestore
          .collection('users')
          .doc(profile.userId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('[UserDbService] Error saving profile to Firestore: $e');
    }
  }

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
    } catch (e) {
      print('[UserDbService] Error fetching profile from Firestore: $e');
    }
    return null;
  }

  @override
  Stream<bool> watchPremiumStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isPremium'] as bool? ?? false)
        .handleError((_) {/* keep last known value on transient errors */});
  }
}

