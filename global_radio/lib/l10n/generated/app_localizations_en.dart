// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Global Radio';

  @override
  String get onboardingWelcome => 'Welcome to Global Radio';

  @override
  String get onboardingSubtitle => 'Personalized audio for your interests';

  @override
  String get onboardingSelectLanguages => 'Select your languages';

  @override
  String get onboardingSelectInterests => 'Choose your interests';

  @override
  String get onboardingSetupComplete => 'You\'re all set!';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get appLanguageTitle => 'Select app language';

  @override
  String get appLanguageSubtitle => 'The app will display in this language';

  @override
  String get contentLanguagesTitle => 'Choose content languages';

  @override
  String get contentLanguagesSubtitle =>
      'Select languages you want to listen to';

  @override
  String get interestsTitle => 'Edit Interests';

  @override
  String get voiceTitle => 'Pick a voice';

  @override
  String get accountTitle => 'Make it yours';

  @override
  String get continueButton => 'Continue';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get appLanguage => 'App Language';

  @override
  String get appLanguageDescription => 'Language for app interface';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeGreetingMorning => 'Good Morning';

  @override
  String get homeGreetingAfternoon => 'Good Afternoon';

  @override
  String get homeGreetingEvening => 'Good Evening';

  @override
  String get homeListenNow => 'Listen Now';

  @override
  String get homeRecommendedForYou => 'Recommended for You';

  @override
  String get homeTrendingNow => 'Trending Now';

  @override
  String get homeRecentlyPlayed => 'Recently Played';

  @override
  String get homeQuickPicks => 'Quick Picks';

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryFavorites => 'Favorites';

  @override
  String get libraryDownloads => 'Downloads';

  @override
  String get libraryHistory => 'History';

  @override
  String get libraryNoFavorites => 'No favorites yet';

  @override
  String get libraryNoDownloads => 'No downloads yet';

  @override
  String get libraryNoHistory => 'No history yet';

  @override
  String get libraryAddFavorites => 'Tap the heart icon to add favorites';

  @override
  String get libraryDownloadContent => 'Download content for offline listening';

  @override
  String get libraryStartListening => 'Start listening to see your history';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSignIn => 'Sign In';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsLanguages => 'Languages';

  @override
  String get settingsInterests => 'Interests';

  @override
  String get settingsVoice => 'Voice Preferences';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDownloads => 'Downloads';

  @override
  String get settingsDownloadsWifiOnly => 'Download on Wi-Fi only';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsClearCache => 'Clear Cache';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsFeedback => 'Send Feedback';

  @override
  String get settingsRateApp => 'Rate the App';

  @override
  String get settingsShareApp => 'Share with Friends';

  @override
  String get playerNowPlaying => 'Now Playing';

  @override
  String get playerUpNext => 'Up Next';

  @override
  String get playerPlaybackSpeed => 'Playback Speed';

  @override
  String get playerSleepTimer => 'Sleep Timer';

  @override
  String get playerSleepTimerOff => 'Off';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get playerAddToFavorites => 'Add to Favorites';

  @override
  String get playerRemoveFromFavorites => 'Remove from Favorites';

  @override
  String get playerDownload => 'Download';

  @override
  String get playerShare => 'Share';

  @override
  String get interestsSubtitle => 'Select topics you\'d like to hear about';

  @override
  String interestsSelected(int count) {
    return '$count selected';
  }

  @override
  String get interestsSave => 'Save';

  @override
  String get languagesTitle => 'Languages';

  @override
  String get languagesSubtitle => 'Select your preferred languages';

  @override
  String get languagesSave => 'Save';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search for content...';

  @override
  String get searchVoiceHint => 'Tap to search by voice';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get searchTryDifferent => 'Try different keywords';

  @override
  String get authSignInTitle => 'Sign In';

  @override
  String get authSignInSubtitle => 'Sign in to sync your preferences';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueAsGuest => 'Continue as Guest';

  @override
  String get authSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get premiumTitle => 'Go Premium';

  @override
  String get premiumSubtitle => 'Unlock all features';

  @override
  String get premiumFeature1 => 'Ad-free listening';

  @override
  String get premiumFeature2 => 'Unlimited downloads';

  @override
  String get premiumFeature3 => 'Premium voices';

  @override
  String premiumSubscribe(String price) {
    return 'Subscribe for $price';
  }

  @override
  String get premiumRestore => 'Restore Purchase';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorNetwork => 'No internet connection';

  @override
  String get errorRetry => 'Retry';

  @override
  String get errorLoadingContent => 'Failed to load content';

  @override
  String get errorPlayback => 'Playback error';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDone => 'Done';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get notificationDailyTitle => 'Your Daily Audio';

  @override
  String get notificationDailyBody => 'Your personalized content is ready';

  @override
  String adSkipIn(int seconds) {
    return 'Skip in ${seconds}s';
  }

  @override
  String get adSkip => 'Skip Ad';

  @override
  String get adLabel => 'AD';

  @override
  String get offlineTitle => 'Offline Mode';

  @override
  String get offlineMessage =>
      'You\'re offline. Only downloaded content is available.';

  @override
  String get offlineDownloadAvailable => 'Download for offline listening';

  @override
  String get feedbackTitle => 'Send Feedback';

  @override
  String get feedbackHint => 'Tell us what you think...';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackThankYou => 'Thank you for your feedback!';

  @override
  String get updateRequired => 'Update Required';

  @override
  String get updateMessage =>
      'A new version is available. Please update to continue.';

  @override
  String get updateButton => 'Update Now';
}
