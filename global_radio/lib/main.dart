import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/generated/app_localizations.dart';

import 'audio/audio_handler.dart';
import 'core/constants.dart';
import 'core/error_handling/app_error_handler.dart';
import 'core/error_handling/crash_service.dart';
import 'core/error_handling/firebase_crash_service.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/local/local_store.dart';
import 'data/services/push_service.dart';
import 'firebase_options.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/providers.dart';

/// Background/terminated FCM handler — must be a top-level function. The OS
/// already renders the tray notification; this is a hook for any data work.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: the daily-astrology push is a display nudge; tapping it opens the
  // app, which refreshes the catalog and surfaces today's reading.
}

/// Global crash service instance for error reporting.
late final CrashService crashService;

Future<void> main() async {
  // Set up custom error widget (replaces red error screen in release).
  setupErrorWidget();

  // Run in a zone that catches all uncaught errors.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Firebase backs auth (Phase B), push, analytics, and crashlytics.
      // Opt-in and only after `flutterfire configure`; default builds skip it.
      if (AppConfig.useFirebase) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Set up Crashlytics error handling.
        if (AppConfig.useCrashlytics) {
          FlutterError.onError = (errorDetails) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
          };
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };
        }

        if (AppConfig.usePush) {
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        }
      }

      // Initialize crash service (Firebase or debug).
      crashService = AppConfig.useCrashlytics
          ? FirebaseCrashService()
          : DebugCrashService();
      await crashService.init();

      // Set up Flutter framework error handling (non-crashlytics fallback).
      if (!AppConfig.useCrashlytics) {
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          crashService.recordError(
            details.exception,
            details.stack,
            reason: details.context?.toDescription(),
            fatal: true,
          );
        };
      }

      // Local DB (profile, signals, catalog cache).
      final store = LocalStore();
      await store.init();

      // Background audio handler (lock-screen controls, gapless queue).
      final audioHandler = await AudioService.init(
        builder: GlobalRadioAudioHandler.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.globalradio.audio',
          androidNotificationChannelName: 'Global Radio',
          androidNotificationOngoing: true,
        ),
      );

      // Daily-astrology push (no-op unless USE_PUSH). Subscribe to the topics that
      // match the saved profile so a returning user is already enrolled at launch.
      final pushService = AppConfig.usePush ? FcmPushService() : NoopPushService();
      await pushService.init();
      final profile = store.loadProfile();
      await pushService.syncTopics(
        languages: profile.languages,
        interests: profile.interests,
      );

      runApp(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(store),
            audioHandlerProvider.overrideWithValue(audioHandler),
            pushServiceProvider.overrideWithValue(pushService),
            crashServiceProvider.overrideWithValue(crashService),
          ],
          child: const GlobalRadioApp(),
        ),
      );
    },
    (error, stack) {
      // Catch any uncaught async errors.
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
      if (AppConfig.useCrashlytics) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      }
    },
  );
}

class GlobalRadioApp extends ConsumerWidget {
  const GlobalRadioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      title: 'Global Radio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark, // dark-first
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
