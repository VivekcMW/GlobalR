import '../../core/constants.dart';

/// User profile + preferences. Stored locally (Hive); synced to Firestore
/// only after the soft account prompt. No PII required to start listening.
class UserProfile {
  final String? name;
  final String? appLocale; // App UI language code (e.g., 'hindi', 'english')
  final List<String> languages; // Content languages to listen to
  final List<String> interests;
  final String preferredVoice;
  final bool lowDataMode;
  final bool isPremium;
  final bool onboardingComplete;

  // Account identity. All null/anonymous until the user signs in; sign-in is
  // optional and additive — listening never requires it.
  final String? userId;
  final String? avatar; // emoji glyph chosen at profile setup
  final String? phone;
  final String? email;
  final String? signInProvider; // 'phone' | 'google' | 'apple'

  const UserProfile({
    this.name,
    this.appLocale,
    this.languages = const [],
    this.interests = const [],
    this.preferredVoice = VoicePreset.freeDefaultId,
    this.lowDataMode = false,
    this.isPremium = false,
    this.onboardingComplete = false,
    this.userId,
    this.avatar,
    this.phone,
    this.email,
    this.signInProvider,
  });

  /// True once the user has a real account (any provider).
  bool get isSignedIn => userId != null;

  UserProfile copyWith({
    String? name,
    String? appLocale,
    List<String>? languages,
    List<String>? interests,
    String? preferredVoice,
    bool? lowDataMode,
    bool? isPremium,
    bool? onboardingComplete,
    String? userId,
    String? avatar,
    String? phone,
    String? email,
    String? signInProvider,
  }) =>
      UserProfile(
        name: name ?? this.name,
        appLocale: appLocale ?? this.appLocale,
        languages: languages ?? this.languages,
        interests: interests ?? this.interests,
        preferredVoice: preferredVoice ?? this.preferredVoice,
        lowDataMode: lowDataMode ?? this.lowDataMode,
        isPremium: isPremium ?? this.isPremium,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        userId: userId ?? this.userId,
        avatar: avatar ?? this.avatar,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        signInProvider: signInProvider ?? this.signInProvider,
      );

  /// Clears all account identity (used on sign-out), keeping preferences.
  UserProfile signedOut() => UserProfile(
        name: name,
        appLocale: appLocale,
        languages: languages,
        interests: interests,
        preferredVoice: preferredVoice,
        lowDataMode: lowDataMode,
        isPremium: isPremium,
        onboardingComplete: onboardingComplete,
      );

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] as String?,
        appLocale: j['appLocale'] as String?,
        languages:
            (j['languages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        interests:
            (j['interests'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        preferredVoice: j['preferredVoice'] as String? ?? VoicePreset.freeDefaultId,
        lowDataMode: j['lowDataMode'] as bool? ?? false,
        isPremium: j['isPremium'] as bool? ?? false,
        onboardingComplete: j['onboardingComplete'] as bool? ?? false,
        userId: j['userId'] as String?,
        avatar: j['avatar'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        signInProvider: j['signInProvider'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'appLocale': appLocale,
        'languages': languages,
        'interests': interests,
        'preferredVoice': preferredVoice,
        'lowDataMode': lowDataMode,
        'isPremium': isPremium,
        'onboardingComplete': onboardingComplete,
        'userId': userId,
        'avatar': avatar,
        'phone': phone,
        'email': email,
        'signInProvider': signInProvider,
      };
}
