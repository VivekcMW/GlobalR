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

/// No-backend default: simulates the full auth flow locally so the UI works
/// with zero setup. Replace with FirebaseAuthService for real accounts.
class DevAuthService implements AuthService {
  /// In dev, any phone "receives" this code.
  static const devCode = '123456';

  String? _userId;

  @override
  String? get userId => _userId;

  @override
  bool get isSignedIn => _userId != null;

  @override
  Future<String> sendOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'dev-verification:$phone';
  }

  @override
  Future<AuthUser> verifyOtp(String verificationId, String code,
      {String? phone}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (code.trim() != devCode) {
      throw const AuthException('Incorrect code. (Dev code is 123456)');
    }
    _userId = 'dev:${phone ?? verificationId}';
    return AuthUser(uid: _userId!, provider: 'phone', phone: phone);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _userId = 'dev:google';
    return const AuthUser(
      uid: 'dev:google',
      provider: 'google',
      email: 'dev.user@gmail.com',
      displayName: 'Dev User',
    );
  }

  @override
  Future<AuthUser> signInWithApple() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _userId = 'dev:apple';
    return const AuthUser(
      uid: 'dev:apple',
      provider: 'apple',
      email: 'dev.user@icloud.com',
      displayName: 'Dev User',
    );
  }

  @override
  Future<void> signOut() async {
    _userId = null;
  }

  @override
  Future<void> deleteAccount() async {
    _userId = null;
  }
}
