import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_brx.dart';
import 'app_localizations_de.dart';
import 'app_localizations_doi.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_kok.dart';
import 'app_localizations_ks.dart';
import 'app_localizations_mai.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_sd.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('as'),
    Locale('bn'),
    Locale('brx'),
    Locale('de'),
    Locale('doi'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('gu'),
    Locale('hi'),
    Locale('ja'),
    Locale('kn'),
    Locale('ko'),
    Locale('kok'),
    Locale('ks'),
    Locale('mai'),
    Locale('ml'),
    Locale('mni'),
    Locale('mr'),
    Locale('ne'),
    Locale('or'),
    Locale('pa'),
    Locale('pt'),
    Locale('sat'),
    Locale('sd'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
    Locale('zh'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Global Radio'**
  String get appName;

  /// Welcome message on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Global Radio'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalized audio for your interests'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingSelectLanguages.
  ///
  /// In en, this message translates to:
  /// **'Select your languages'**
  String get onboardingSelectLanguages;

  /// No description provided for @onboardingSelectInterests.
  ///
  /// In en, this message translates to:
  /// **'Choose your interests'**
  String get onboardingSelectInterests;

  /// No description provided for @onboardingSetupComplete.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardingSetupComplete;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Title for app language selection step
  ///
  /// In en, this message translates to:
  /// **'Select app language'**
  String get appLanguageTitle;

  /// Subtitle for app language selection
  ///
  /// In en, this message translates to:
  /// **'The app will display in this language'**
  String get appLanguageSubtitle;

  /// Title for content languages selection step
  ///
  /// In en, this message translates to:
  /// **'Choose content languages'**
  String get contentLanguagesTitle;

  /// Subtitle for content languages selection
  ///
  /// In en, this message translates to:
  /// **'Select languages you want to listen to'**
  String get contentLanguagesSubtitle;

  /// Title for interests selection step in onboarding
  ///
  /// In en, this message translates to:
  /// **'Edit Interests'**
  String get interestsTitle;

  /// Title for voice selection step
  ///
  /// In en, this message translates to:
  /// **'Pick a voice'**
  String get voiceTitle;

  /// Title for account setup step
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get accountTitle;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Skip for now button text
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// App language setting label
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// Description for app language setting
  ///
  /// In en, this message translates to:
  /// **'Language for app interface'**
  String get appLanguageDescription;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeListenNow.
  ///
  /// In en, this message translates to:
  /// **'Listen Now'**
  String get homeListenNow;

  /// No description provided for @homeRecommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get homeRecommendedForYou;

  /// No description provided for @homeTrendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get homeTrendingNow;

  /// No description provided for @homeRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get homeRecentlyPlayed;

  /// No description provided for @homeQuickPicks.
  ///
  /// In en, this message translates to:
  /// **'Quick Picks'**
  String get homeQuickPicks;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @libraryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFavorites;

  /// No description provided for @libraryDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get libraryDownloads;

  /// No description provided for @libraryHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get libraryHistory;

  /// No description provided for @libraryNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get libraryNoFavorites;

  /// No description provided for @libraryNoDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get libraryNoDownloads;

  /// No description provided for @libraryNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get libraryNoHistory;

  /// No description provided for @libraryAddFavorites.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon to add favorites'**
  String get libraryAddFavorites;

  /// No description provided for @libraryDownloadContent.
  ///
  /// In en, this message translates to:
  /// **'Download content for offline listening'**
  String get libraryDownloadContent;

  /// No description provided for @libraryStartListening.
  ///
  /// In en, this message translates to:
  /// **'Start listening to see your history'**
  String get libraryStartListening;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get settingsSignIn;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get settingsLanguages;

  /// No description provided for @settingsInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get settingsInterests;

  /// No description provided for @settingsVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice Preferences'**
  String get settingsVoice;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsDownloads;

  /// No description provided for @settingsDownloadsWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Download on Wi-Fi only'**
  String get settingsDownloadsWifiOnly;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsClearCache;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get settingsRateApp;

  /// No description provided for @settingsShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share with Friends'**
  String get settingsShareApp;

  /// No description provided for @playerNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get playerNowPlaying;

  /// No description provided for @playerUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get playerUpNext;

  /// No description provided for @playerPlaybackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playerPlaybackSpeed;

  /// No description provided for @playerSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get playerSleepTimer;

  /// No description provided for @playerSleepTimerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get playerSleepTimerOff;

  /// No description provided for @playerSleepTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String playerSleepTimerMinutes(int minutes);

  /// No description provided for @playerAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get playerAddToFavorites;

  /// No description provided for @playerRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get playerRemoveFromFavorites;

  /// No description provided for @playerDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get playerDownload;

  /// No description provided for @playerShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get playerShare;

  /// No description provided for @interestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select topics you\'d like to hear about'**
  String get interestsSubtitle;

  /// No description provided for @interestsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String interestsSelected(int count);

  /// No description provided for @interestsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get interestsSave;

  /// No description provided for @languagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesTitle;

  /// No description provided for @languagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred languages'**
  String get languagesSubtitle;

  /// No description provided for @languagesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get languagesSave;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for content...'**
  String get searchHint;

  /// No description provided for @searchVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to search by voice'**
  String get searchVoiceHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @searchTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get searchTryDifferent;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your preferences'**
  String get authSignInSubtitle;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authContinueAsGuest;

  /// No description provided for @authSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get authSignOutConfirm;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get premiumTitle;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features'**
  String get premiumSubtitle;

  /// No description provided for @premiumFeature1.
  ///
  /// In en, this message translates to:
  /// **'Ad-free listening'**
  String get premiumFeature1;

  /// No description provided for @premiumFeature2.
  ///
  /// In en, this message translates to:
  /// **'Unlimited downloads'**
  String get premiumFeature2;

  /// No description provided for @premiumFeature3.
  ///
  /// In en, this message translates to:
  /// **'Premium voices'**
  String get premiumFeature3;

  /// No description provided for @premiumSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe for {price}'**
  String premiumSubscribe(String price);

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get premiumRestore;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorNetwork;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetry;

  /// No description provided for @errorLoadingContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content'**
  String get errorLoadingContent;

  /// No description provided for @errorPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get errorPlayback;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @notificationDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Daily Audio'**
  String get notificationDailyTitle;

  /// No description provided for @notificationDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Your personalized content is ready'**
  String get notificationDailyBody;

  /// No description provided for @adSkipIn.
  ///
  /// In en, this message translates to:
  /// **'Skip in {seconds}s'**
  String adSkipIn(int seconds);

  /// No description provided for @adSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip Ad'**
  String get adSkip;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'AD'**
  String get adLabel;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineTitle;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Only downloaded content is available.'**
  String get offlineMessage;

  /// No description provided for @offlineDownloadAvailable.
  ///
  /// In en, this message translates to:
  /// **'Download for offline listening'**
  String get offlineDownloadAvailable;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you think...'**
  String get feedbackHint;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmit;

  /// No description provided for @feedbackThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackThankYou;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequired;

  /// No description provided for @updateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version is available. Please update to continue.'**
  String get updateMessage;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'as',
    'bn',
    'brx',
    'de',
    'doi',
    'en',
    'es',
    'fr',
    'gu',
    'hi',
    'ja',
    'kn',
    'ko',
    'kok',
    'ks',
    'mai',
    'ml',
    'mni',
    'mr',
    'ne',
    'or',
    'pa',
    'pt',
    'sat',
    'sd',
    'ta',
    'te',
    'ur',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'brx':
      return AppLocalizationsBrx();
    case 'de':
      return AppLocalizationsDe();
    case 'doi':
      return AppLocalizationsDoi();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'kn':
      return AppLocalizationsKn();
    case 'ko':
      return AppLocalizationsKo();
    case 'kok':
      return AppLocalizationsKok();
    case 'ks':
      return AppLocalizationsKs();
    case 'mai':
      return AppLocalizationsMai();
    case 'ml':
      return AppLocalizationsMl();
    case 'mni':
      return AppLocalizationsMni();
    case 'mr':
      return AppLocalizationsMr();
    case 'ne':
      return AppLocalizationsNe();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'pt':
      return AppLocalizationsPt();
    case 'sat':
      return AppLocalizationsSat();
    case 'sd':
      return AppLocalizationsSd();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
