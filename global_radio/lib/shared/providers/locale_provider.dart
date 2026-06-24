import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import 'providers.dart';

/// Provides the current app locale based on user's appLocale preference.
/// Falls back to device locale or English if not set.
final appLocaleProvider = Provider<Locale>((ref) {
  final profile = ref.watch(profileProvider);
  
  // If user has set an app locale, use it
  if (profile.appLocale != null) {
    return AppLanguage.localeFor(profile.appLocale!);
  }
  
  // Fall back to English
  return const Locale('en');
});

/// Notifier version for when you need to set the locale (used during onboarding
/// before profile is saved).
class AppLocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final profile = ref.watch(profileProvider);
    if (profile.appLocale != null) {
      return AppLanguage.localeFor(profile.appLocale!);
    }
    return null; // null means use system locale
  }

  /// Set the app locale. Called during onboarding Step 0.
  void setLocale(String languageCode) {
    state = AppLanguage.localeFor(languageCode);
  }

  /// Clear override to use system locale.
  void clearLocale() {
    state = null;
  }
}

/// Use this during onboarding to set locale immediately before saving to profile.
final appLocaleNotifierProvider =
    NotifierProvider<AppLocaleNotifier, Locale?>(AppLocaleNotifier.new);
