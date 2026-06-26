import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_handler.dart';
import '../../audio/voice_preview_player.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/firebase_analytics_service.dart';
import '../../core/constants.dart';
import '../../core/error_handling/crash_service.dart';
import '../../core/error_handling/firebase_crash_service.dart';
import '../../data/local/local_store.dart';
import '../../data/models/catalog_item.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/catalog_sync_service.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/push_service.dart';
import '../../radio_engine/radio_engine.dart';

/// Overridden in main() with the initialized singletons.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);
final audioHandlerProvider = Provider<GlobalRadioAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider must be overridden'),
);

/// Local dev auth by default; swap to FirebaseAuthService once configured
/// (see SETUP.md). Gated by [AppConfig.useFirebaseAuth].
final authServiceProvider = Provider<AuthService>((ref) {
  // Firebase backend only when explicitly enabled AND configured; otherwise the
  // local dev stub keeps the app fully functional with no backend.
  return AppConfig.useFirebaseAuth ? FirebaseAuthService() : DevAuthService();
});

final paymentServiceProvider =
    Provider<PaymentService>((ref) => StubPaymentService());

/// Daily-astrology push. Real FCM only when explicitly enabled AND Firebase is
/// configured; otherwise a no-op so the app runs with no backend.
final pushServiceProvider = Provider<PushService>(
  (ref) => AppConfig.usePush ? FcmPushService() : NoopPushService(),
);

/// Analytics service. Firebase Analytics when enabled, otherwise debug logging.
/// Initialize via analyticsProvider.read().initialize() in main().
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AppConfig.useAnalytics
      ? FirebaseAnalyticsService()
      : DebugAnalyticsService();
});

/// Crash reporting service. Firebase Crashlytics when enabled, otherwise debug logging.
/// Override in main() with initialized instance.
final crashServiceProvider = Provider<CrashService>(
  (ref) => AppConfig.useCrashlytics
      ? FirebaseCrashService()
      : DebugCrashService(),
);

final radioEngineProvider = Provider<RadioEngine>((ref) => RadioEngine());

/// Standalone player for voice samples in the voice picker. Disposed with the
/// screens that use it.
final voicePreviewPlayerProvider = Provider<VoicePreviewPlayer>((ref) {
  final player = VoicePreviewPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.read(localStoreProvider)),
);

/// User profile (Hive-backed). All onboarding + settings writes go here.
class ProfileController extends Notifier<UserProfile> {
  @override
  UserProfile build() => ref.read(localStoreProvider).loadProfile();

  Future<void> _save(UserProfile p) async {
    state = p;
    await ref.read(localStoreProvider).saveProfile(p);
  }

  Future<void> setLanguages(List<String> langs) async {
    await _save(state.copyWith(languages: langs));
    await _syncPush();
  }

  Future<void> setInterests(List<String> interests) async {
    await _save(state.copyWith(interests: interests));
    await _syncPush();
  }

  /// Keep FCM topic subscriptions in step with the profile (no-op unless push
  /// is enabled). Failures here must never block a profile save.
  Future<void> _syncPush() async {
    try {
      await ref.read(pushServiceProvider).syncTopics(
            languages: state.languages,
            interests: state.interests,
          );
    } catch (_) {/* push is best-effort */}
  }
  Future<void> setVoice(String voiceId) =>
      _save(state.copyWith(preferredVoice: voiceId));
  Future<void> setLowDataMode(bool v) => _save(state.copyWith(lowDataMode: v));
  Future<void> setName(String? name) => _save(state.copyWith(name: name));
  Future<void> setAvatar(String? avatar) => _save(state.copyWith(avatar: avatar));
  Future<void> setProfile({String? name, String? avatar}) =>
      _save(state.copyWith(name: name, avatar: avatar));
  Future<void> setPremium(bool v) => _save(state.copyWith(isPremium: v));
  Future<void> setAppLocale(String? localeCode) =>
      _save(state.copyWith(appLocale: localeCode));
  Future<void> completeOnboarding() =>
      _save(state.copyWith(onboardingComplete: true));

  /// Merge an authenticated identity into the profile (keeps a name/avatar the
  /// user already set, but adopts the provider's name if we have none yet).
  Future<void> applyAuth(AuthUser user) => _save(state.copyWith(
        userId: user.uid,
        phone: user.phone ?? state.phone,
        email: user.email ?? state.email,
        signInProvider: user.provider,
        name: state.name ?? user.displayName,
      ));

  /// Drop account identity, keep on-device preferences.
  Future<void> clearIdentity() => _save(state.signedOut());

  /// Wipe everything — used by "Delete account & data".
  Future<void> wipe() async {
    await ref.read(localStoreProvider).clearAll();
    state = const UserProfile();
  }
}

final profileProvider =
    NotifierProvider<ProfileController, UserProfile>(ProfileController.new);

/// Drives the sign-in UI and writes the resulting identity into the profile.
class AuthController extends Notifier<void> {
  @override
  void build() {}

  AuthService get _auth => ref.read(authServiceProvider);

  Future<String> sendOtp(String phone) => _auth.sendOtp(phone);

  Future<void> verifyOtp(String verificationId, String code,
      {String? phone}) async {
    final user = await _auth.verifyOtp(verificationId, code, phone: phone);
    await ref.read(profileProvider.notifier).applyAuth(user);
  }

  Future<void> signInWithGoogle() async {
    final user = await _auth.signInWithGoogle();
    await ref.read(profileProvider.notifier).applyAuth(user);
  }

  Future<void> signInWithApple() async {
    final user = await _auth.signInWithApple();
    await ref.read(profileProvider.notifier).applyAuth(user);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await ref.read(profileProvider.notifier).clearIdentity();
  }

  Future<void> deleteAccount() async {
    await _auth.deleteAccount();
    await ref.read(profileProvider.notifier).wipe();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, void>(AuthController.new);

/// Catalog: serve cached/bundled immediately, then refresh from CDN.
/// 
/// **Auto-sync features:**
/// - Background catalog sync every 6 hours
/// - Health checking of audio URLs (marks dead items as unreachable)
/// - Automatic failover to fallback CDNs
class CatalogController extends AsyncNotifier<Catalog> {
  CatalogSyncService? _syncService;

  @override
  Future<Catalog> build() async {
    final repo = ref.read(catalogRepositoryProvider);
    final store = ref.read(localStoreProvider);
    final initial = await repo.loadInitial();
    
    // Initialize sync service with auto-sync
    _syncService = CatalogSyncService(store);
    _syncService!.onCatalogUpdated = (catalog) {
      // Update state when new catalog arrives
      state = AsyncData(catalog);
    };
    _syncService!.onDeadUrlsFound = (deadIds) {
      // Log dead URLs for monitoring
      print('[Catalog] Dead URLs found: ${deadIds.length}');
    };
    
    // Start auto-sync in background
    _syncService!.startAutoSync();
    
    // Clean up on dispose
    ref.onDispose(() {
      _syncService?.dispose();
    });
    
    return initial;
  }

  /// Force refresh the catalog (bypass cache).
  Future<void> forceRefresh() async {
    if (_syncService != null) {
      final result = await _syncService!.forceRefresh();
      if (!result.success && result.error != null) {
        state = AsyncError(result.error!, StackTrace.current);
      }
    }
  }

  /// Run health check on catalog URLs.
  Future<void> runHealthCheck() async {
    await _syncService?.runHealthCheck();
  }

  /// Whether a sync is in progress.
  bool get isSyncing => _syncService?.isSyncing ?? false;
}

final catalogProvider =
    AsyncNotifierProvider<CatalogController, Catalog>(CatalogController.new);
