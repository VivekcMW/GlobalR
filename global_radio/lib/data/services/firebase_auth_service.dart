import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_service.dart';

/// Real backend for [AuthService] using Firebase Auth (Phone OTP + Google +
/// Apple). Selected by the provider only when `AppConfig.useFirebaseAuth` is
/// true and `flutterfire configure` has been run. The rest of the app is
/// unchanged — it talks to the [AuthService] interface.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  String? get userId => _auth.currentUser?.uid;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  // ---- Phone OTP ------------------------------------------------------------

  @override
  Future<String> sendOtp(String phone) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {
        // Android instant/auto-retrieval — we still wait for manual entry to
        // keep one code path across platforms.
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(AuthException(e.message ?? 'Verification failed'));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  @override
  Future<AuthUser> verifyOtp(String verificationId, String code,
      {String? phone}) async {
    final cred = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: code);
    final result = await _auth.signInWithCredential(cred);
    return _toAuthUser(result.user!, 'phone');
  }

  // ---- Google ---------------------------------------------------------------

  @override
  Future<AuthUser> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    await google.initialize();
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google sign-in returned no ID token');
    }
    final cred = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(cred);
    return _toAuthUser(result.user!, 'google');
  }

  // ---- Apple ----------------------------------------------------------------

  @override
  Future<AuthUser> signInWithApple() async {
    final apple = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ]);
    final oauth = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      accessToken: apple.authorizationCode,
    );
    final result = await _auth.signInWithCredential(oauth);
    // Apple only returns the name on the first sign-in; capture it if present.
    final displayName = [apple.givenName, apple.familyName]
        .whereType<String>()
        .join(' ')
        .trim();
    final user = _toAuthUser(result.user!, 'apple');
    return displayName.isEmpty
        ? user
        : AuthUser(
            uid: user.uid,
            provider: user.provider,
            phone: user.phone,
            email: user.email ?? apple.email,
            displayName: user.displayName ?? displayName,
            photoUrl: user.photoUrl,
          );
  }

  // ---- Session --------------------------------------------------------------

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  AuthUser _toAuthUser(User u, String provider) => AuthUser(
        uid: u.uid,
        provider: provider,
        phone: u.phoneNumber,
        email: u.email,
        displayName: u.displayName,
        photoUrl: u.photoURL,
      );
}
