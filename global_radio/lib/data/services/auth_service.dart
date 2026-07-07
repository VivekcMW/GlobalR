/// Account abstraction. Sign-in is optional ("save your favorites / sync") and
/// sits behind this interface so the app runs with zero login during onboarding.
///
/// [DevAuthService] is the default and needs no credentials — it lets the whole
/// sign-in UI be exercised on-device. Swap in `FirebaseAuthService` once
/// `flutterfire configure` has been run (see SETUP.md "Cloud wiring"). Nothing
/// in the UI changes — the provider just returns the other implementation.
library;

/// The signed-in user returned by every sign-in method.
class AuthUser {
  final String uid;
  final String? phone;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String provider; // 'phone' | 'google' | 'apple'

  const AuthUser({
    required this.uid,
    required this.provider,
    this.phone,
    this.email,
    this.displayName,
    this.photoUrl,
  });
}

abstract class AuthService {
  /// Null until the user signs in.
  String? get userId;
  bool get isSignedIn;

  /// Phone OTP is two-step: request a code, then verify it.
  /// [sendOtp] returns a verification id to pass back into [verifyOtp].
  Future<String> sendOtp(String phone);
  Future<AuthUser> verifyOtp(String verificationId, String code, {String? phone});

  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();

  Future<void> signOut();
  Future<void> deleteAccount();
}

/// Thrown for expected, user-facing auth failures (e.g. wrong OTP).
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}


