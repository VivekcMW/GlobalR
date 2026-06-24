// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appName => 'ग्लोबल रेडियो';

  @override
  String get onboardingWelcome => 'ग्लोबल रेडियोमा स्वागत छ';

  @override
  String get onboardingSubtitle => 'तपाईंको रुचिका लागि व्यक्तिगत अडियो';

  @override
  String get onboardingSelectLanguages => 'तपाईंका भाषाहरू छान्नुहोस्';

  @override
  String get onboardingSelectInterests => 'तपाईंका रुचिहरू छान्नुहोस्';

  @override
  String get onboardingSetupComplete => 'तपाईं तयार हुनुहुन्छ!';

  @override
  String get onboardingContinue => 'जारी राख्नुहोस्';

  @override
  String get onboardingGetStarted => 'सुरु गर्नुहोस्';

  @override
  String get onboardingSkip => 'छोड्नुहोस्';

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
  String get interestsTitle => 'रुचिहरू सम्पादन गर्नुहोस्';

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
  String get homeTitle => 'गृह';

  @override
  String get homeGreetingMorning => 'शुभ प्रभात';

  @override
  String get homeGreetingAfternoon => 'शुभ दिउँसो';

  @override
  String get homeGreetingEvening => 'शुभ साँझ';

  @override
  String get homeListenNow => 'अहिले सुन्नुहोस्';

  @override
  String get homeRecommendedForYou => 'तपाईंको लागि सिफारिस';

  @override
  String get homeTrendingNow => 'अहिले ट्रेन्डिङ';

  @override
  String get homeRecentlyPlayed => 'भर्खरै बजाइएको';

  @override
  String get homeQuickPicks => 'द्रुत छनोट';

  @override
  String get libraryTitle => 'पुस्तकालय';

  @override
  String get libraryFavorites => 'मनपर्ने';

  @override
  String get libraryDownloads => 'डाउनलोडहरू';

  @override
  String get libraryHistory => 'इतिहास';

  @override
  String get libraryNoFavorites => 'अझै कुनै मनपर्ने छैन';

  @override
  String get libraryNoDownloads => 'अझै कुनै डाउनलोड छैन';

  @override
  String get libraryNoHistory => 'अझै कुनै इतिहास छैन';

  @override
  String get libraryAddFavorites => 'मनपर्नेमा थप्न हार्ट आइकन ट्याप गर्नुहोस्';

  @override
  String get libraryDownloadContent =>
      'अफलाइनमा सुन्न सामग्री डाउनलोड गर्नुहोस्';

  @override
  String get libraryStartListening =>
      'तपाईंको इतिहास हेर्न सुन्न सुरु गर्नुहोस्';

  @override
  String get settingsTitle => 'सेटिङहरू';

  @override
  String get settingsAccount => 'खाता';

  @override
  String get settingsSignIn => 'साइन इन गर्नुहोस्';

  @override
  String get settingsSignOut => 'साइन आउट गर्नुहोस्';

  @override
  String get settingsLanguages => 'भाषाहरू';

  @override
  String get settingsInterests => 'रुचिहरू';

  @override
  String get settingsVoice => 'आवाज प्राथमिकताहरू';

  @override
  String get settingsNotifications => 'सूचनाहरू';

  @override
  String get settingsDownloads => 'डाउनलोडहरू';

  @override
  String get settingsDownloadsWifiOnly => 'Wi-Fi मा मात्र डाउनलोड गर्नुहोस्';

  @override
  String get settingsStorage => 'भण्डारण';

  @override
  String get settingsClearCache => 'क्यास खाली गर्नुहोस्';

  @override
  String get settingsAbout => 'बारेमा';

  @override
  String get settingsPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get settingsTermsOfService => 'सेवाका सर्तहरू';

  @override
  String settingsVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get settingsFeedback => 'प्रतिक्रिया पठाउनुहोस्';

  @override
  String get settingsRateApp => 'एप रेट गर्नुहोस्';

  @override
  String get settingsShareApp => 'साथीहरूसँग साझा गर्नुहोस्';

  @override
  String get playerNowPlaying => 'अहिले बज्दैछ';

  @override
  String get playerUpNext => 'अर्को';

  @override
  String get playerPlaybackSpeed => 'प्लेब्याक गति';

  @override
  String get playerSleepTimer => 'स्लिप टाइमर';

  @override
  String get playerSleepTimerOff => 'बन्द';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes मिनेट';
  }

  @override
  String get playerAddToFavorites => 'मनपर्नेमा थप्नुहोस्';

  @override
  String get playerRemoveFromFavorites => 'मनपर्नेबाट हटाउनुहोस्';

  @override
  String get playerDownload => 'डाउनलोड गर्नुहोस्';

  @override
  String get playerShare => 'साझा गर्नुहोस्';

  @override
  String get interestsSubtitle => 'तपाईं सुन्न चाहनुहुने विषयहरू छान्नुहोस्';

  @override
  String interestsSelected(int count) {
    return '$count छानिएको';
  }

  @override
  String get interestsSave => 'सुरक्षित गर्नुहोस्';

  @override
  String get languagesTitle => 'भाषाहरू';

  @override
  String get languagesSubtitle => 'तपाईंको मनपर्ने भाषाहरू छान्नुहोस्';

  @override
  String get languagesSave => 'सुरक्षित गर्नुहोस्';

  @override
  String get searchTitle => 'खोज्नुहोस्';

  @override
  String get searchHint => 'सामग्री खोज्नुहोस्...';

  @override
  String get searchVoiceHint => 'आवाजले खोज्न ट्याप गर्नुहोस्';

  @override
  String get searchNoResults => 'कुनै नतिजा फेला परेन';

  @override
  String get searchTryDifferent => 'फरक शब्दहरू प्रयास गर्नुहोस्';

  @override
  String get authSignInTitle => 'साइन इन गर्नुहोस्';

  @override
  String get authSignInSubtitle =>
      'तपाईंको प्राथमिकताहरू सिंक गर्न साइन इन गर्नुहोस्';

  @override
  String get authContinueWithGoogle => 'Google सँग जारी राख्नुहोस्';

  @override
  String get authContinueWithApple => 'Apple सँग जारी राख्नुहोस्';

  @override
  String get authContinueAsGuest => 'अतिथिको रूपमा जारी राख्नुहोस्';

  @override
  String get authSignOutConfirm => 'के तपाईं साँच्चै साइन आउट गर्न चाहनुहुन्छ?';

  @override
  String get premiumTitle => 'प्रिमियम बन्नुहोस्';

  @override
  String get premiumSubtitle => 'सबै सुविधाहरू अनलक गर्नुहोस्';

  @override
  String get premiumFeature1 => 'विज्ञापन-मुक्त सुन्ने';

  @override
  String get premiumFeature2 => 'असीमित डाउनलोडहरू';

  @override
  String get premiumFeature3 => 'प्रिमियम आवाजहरू';

  @override
  String premiumSubscribe(String price) {
    return '$price मा सदस्यता लिनुहोस्';
  }

  @override
  String get premiumRestore => 'खरिद पुनर्स्थापना गर्नुहोस्';

  @override
  String get errorGeneric => 'केहि गलत भयो';

  @override
  String get errorNetwork => 'इन्टरनेट जडान छैन';

  @override
  String get errorRetry => 'पुन: प्रयास गर्नुहोस्';

  @override
  String get errorLoadingContent => 'सामग्री लोड गर्न असफल';

  @override
  String get errorPlayback => 'प्लेब्याक त्रुटि';

  @override
  String get commonCancel => 'रद्द गर्नुहोस्';

  @override
  String get commonOk => 'ठीक छ';

  @override
  String get commonSave => 'सुरक्षित गर्नुहोस्';

  @override
  String get commonDelete => 'मेट्नुहोस्';

  @override
  String get commonEdit => 'सम्पादन गर्नुहोस्';

  @override
  String get commonDone => 'भयो';

  @override
  String get commonLoading => 'लोड हुँदैछ...';

  @override
  String get commonRefresh => 'ताजा गर्नुहोस्';

  @override
  String get notificationDailyTitle => 'तपाईंको दैनिक अडियो';

  @override
  String get notificationDailyBody => 'तपाईंको व्यक्तिगत सामग्री तयार छ';

  @override
  String adSkipIn(int seconds) {
    return '$seconds सेकेन्डमा छोड्नुहोस्';
  }

  @override
  String get adSkip => 'विज्ञापन छोड्नुहोस्';

  @override
  String get adLabel => 'विज्ञापन';

  @override
  String get offlineTitle => 'अफलाइन मोड';

  @override
  String get offlineMessage =>
      'तपाईं अफलाइन हुनुहुन्छ। डाउनलोड गरिएको सामग्री मात्र उपलब्ध छ।';

  @override
  String get offlineDownloadAvailable => 'अफलाइनमा सुन्न डाउनलोड गर्नुहोस्';

  @override
  String get feedbackTitle => 'प्रतिक्रिया पठाउनुहोस्';

  @override
  String get feedbackHint => 'तपाईं के सोच्नुहुन्छ भन्नुहोस्...';

  @override
  String get feedbackSubmit => 'पेश गर्नुहोस्';

  @override
  String get feedbackThankYou => 'तपाईंको प्रतिक्रियाको लागि धन्यवाद!';

  @override
  String get updateRequired => 'अपडेट आवश्यक छ';

  @override
  String get updateMessage =>
      'नयाँ संस्करण उपलब्ध छ। कृपया जारी राख्न अपडेट गर्नुहोस्।';

  @override
  String get updateButton => 'अहिले अपडेट गर्नुहोस्';
}
