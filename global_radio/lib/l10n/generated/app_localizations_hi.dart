// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'ग्लोबल रेडियो';

  @override
  String get onboardingWelcome => 'ग्लोबल रेडियो में आपका स्वागत है';

  @override
  String get onboardingSubtitle => 'आपकी रुचियों के लिए व्यक्तिगत ऑडियो';

  @override
  String get onboardingSelectLanguages => 'अपनी भाषाएं चुनें';

  @override
  String get onboardingSelectInterests => 'अपनी रुचियां चुनें';

  @override
  String get onboardingSetupComplete => 'आप तैयार हैं!';

  @override
  String get onboardingContinue => 'आगे बढ़ें';

  @override
  String get onboardingGetStarted => 'शुरू करें';

  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get appLanguageTitle => 'ऐप की भाषा चुनें';

  @override
  String get appLanguageSubtitle => 'ऐप इस भाषा में दिखाई देगा';

  @override
  String get contentLanguagesTitle => 'सुनने की भाषाएं चुनें';

  @override
  String get contentLanguagesSubtitle => 'आप किन भाषाओं में सुनना चाहते हैं';

  @override
  String get interestsTitle => 'रुचियां संपादित करें';

  @override
  String get voiceTitle => 'आवाज़ चुनें';

  @override
  String get accountTitle => 'अपना बनाएं';

  @override
  String get continueButton => 'आगे बढ़ें';

  @override
  String get skipForNow => 'अभी के लिए छोड़ें';

  @override
  String get appLanguage => 'ऐप की भाषा';

  @override
  String get appLanguageDescription => 'ऐप इंटरफ़ेस की भाषा';

  @override
  String get homeTitle => 'होम';

  @override
  String get homeGreetingMorning => 'सुप्रभात';

  @override
  String get homeGreetingAfternoon => 'नमस्कार';

  @override
  String get homeGreetingEvening => 'शुभ संध्या';

  @override
  String get homeListenNow => 'अभी सुनें';

  @override
  String get homeRecommendedForYou => 'आपके लिए अनुशंसित';

  @override
  String get homeTrendingNow => 'अभी ट्रेंडिंग';

  @override
  String get homeRecentlyPlayed => 'हाल ही में सुना';

  @override
  String get homeQuickPicks => 'त्वरित चयन';

  @override
  String get libraryTitle => 'लाइब्रेरी';

  @override
  String get libraryFavorites => 'पसंदीदा';

  @override
  String get libraryDownloads => 'डाउनलोड';

  @override
  String get libraryHistory => 'इतिहास';

  @override
  String get libraryNoFavorites => 'अभी तक कोई पसंदीदा नहीं';

  @override
  String get libraryNoDownloads => 'अभी तक कोई डाउनलोड नहीं';

  @override
  String get libraryNoHistory => 'अभी तक कोई इतिहास नहीं';

  @override
  String get libraryAddFavorites =>
      'पसंदीदा जोड़ने के लिए हार्ट आइकन पर टैप करें';

  @override
  String get libraryDownloadContent =>
      'ऑफलाइन सुनने के लिए कंटेंट डाउनलोड करें';

  @override
  String get libraryStartListening =>
      'अपना इतिहास देखने के लिए सुनना शुरू करें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsAccount => 'अकाउंट';

  @override
  String get settingsSignIn => 'साइन इन करें';

  @override
  String get settingsSignOut => 'साइन आउट करें';

  @override
  String get settingsLanguages => 'भाषाएं';

  @override
  String get settingsInterests => 'रुचियां';

  @override
  String get settingsVoice => 'आवाज़ प्राथमिकताएं';

  @override
  String get settingsNotifications => 'सूचनाएं';

  @override
  String get settingsDownloads => 'डाउनलोड';

  @override
  String get settingsDownloadsWifiOnly => 'केवल वाई-फाई पर डाउनलोड करें';

  @override
  String get settingsStorage => 'स्टोरेज';

  @override
  String get settingsClearCache => 'कैश साफ़ करें';

  @override
  String get settingsAbout => 'के बारे में';

  @override
  String get settingsPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get settingsTermsOfService => 'सेवा की शर्तें';

  @override
  String settingsVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get settingsFeedback => 'फ़ीडबैक भेजें';

  @override
  String get settingsRateApp => 'ऐप रेट करें';

  @override
  String get settingsShareApp => 'दोस्तों के साथ शेयर करें';

  @override
  String get playerNowPlaying => 'अभी चल रहा है';

  @override
  String get playerUpNext => 'आगे';

  @override
  String get playerPlaybackSpeed => 'प्लेबैक गति';

  @override
  String get playerSleepTimer => 'स्लीप टाइमर';

  @override
  String get playerSleepTimerOff => 'बंद';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes मिनट';
  }

  @override
  String get playerAddToFavorites => 'पसंदीदा में जोड़ें';

  @override
  String get playerRemoveFromFavorites => 'पसंदीदा से हटाएं';

  @override
  String get playerDownload => 'डाउनलोड करें';

  @override
  String get playerShare => 'शेयर करें';

  @override
  String get interestsSubtitle =>
      'वे विषय चुनें जिनके बारे में आप सुनना चाहते हैं';

  @override
  String interestsSelected(int count) {
    return '$count चयनित';
  }

  @override
  String get interestsSave => 'सहेजें';

  @override
  String get languagesTitle => 'भाषाएं';

  @override
  String get languagesSubtitle => 'अपनी पसंदीदा भाषाएं चुनें';

  @override
  String get languagesSave => 'सहेजें';

  @override
  String get searchTitle => 'खोजें';

  @override
  String get searchHint => 'कंटेंट खोजें...';

  @override
  String get searchVoiceHint => 'आवाज़ से खोजने के लिए टैप करें';

  @override
  String get searchNoResults => 'कोई परिणाम नहीं मिला';

  @override
  String get searchTryDifferent => 'अलग कीवर्ड आज़माएं';

  @override
  String get authSignInTitle => 'साइन इन करें';

  @override
  String get authSignInSubtitle =>
      'अपनी प्राथमिकताएं सिंक करने के लिए साइन इन करें';

  @override
  String get authContinueWithGoogle => 'Google से जारी रखें';

  @override
  String get authContinueWithApple => 'Apple से जारी रखें';

  @override
  String get authContinueAsGuest => 'अतिथि के रूप में जारी रखें';

  @override
  String get authSignOutConfirm => 'क्या आप वाकई साइन आउट करना चाहते हैं?';

  @override
  String get premiumTitle => 'प्रीमियम बनें';

  @override
  String get premiumSubtitle => 'सभी सुविधाएं अनलॉक करें';

  @override
  String get premiumFeature1 => 'विज्ञापन-मुक्त सुनना';

  @override
  String get premiumFeature2 => 'असीमित डाउनलोड';

  @override
  String get premiumFeature3 => 'प्रीमियम आवाज़ें';

  @override
  String premiumSubscribe(String price) {
    return '$price में सदस्यता लें';
  }

  @override
  String get premiumRestore => 'खरीदारी पुनर्स्थापित करें';

  @override
  String get errorGeneric => 'कुछ गलत हो गया';

  @override
  String get errorNetwork => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get errorRetry => 'पुनः प्रयास करें';

  @override
  String get errorLoadingContent => 'कंटेंट लोड करने में विफल';

  @override
  String get errorPlayback => 'प्लेबैक त्रुटि';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonDelete => 'हटाएं';

  @override
  String get commonEdit => 'संपादित करें';

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonLoading => 'लोड हो रहा है...';

  @override
  String get commonRefresh => 'रीफ़्रेश करें';

  @override
  String get notificationDailyTitle => 'आपका दैनिक ऑडियो';

  @override
  String get notificationDailyBody => 'आपका व्यक्तिगत कंटेंट तैयार है';

  @override
  String adSkipIn(int seconds) {
    return '${seconds}s में छोड़ें';
  }

  @override
  String get adSkip => 'विज्ञापन छोड़ें';

  @override
  String get adLabel => 'विज्ञापन';

  @override
  String get offlineTitle => 'ऑफ़लाइन मोड';

  @override
  String get offlineMessage =>
      'आप ऑफ़लाइन हैं। केवल डाउनलोड किया गया कंटेंट उपलब्ध है।';

  @override
  String get offlineDownloadAvailable => 'ऑफ़लाइन सुनने के लिए डाउनलोड करें';

  @override
  String get feedbackTitle => 'फ़ीडबैक भेजें';

  @override
  String get feedbackHint => 'हमें बताएं आप क्या सोचते हैं...';

  @override
  String get feedbackSubmit => 'सबमिट करें';

  @override
  String get feedbackThankYou => 'आपकी प्रतिक्रिया के लिए धन्यवाद!';

  @override
  String get updateRequired => 'अपडेट आवश्यक';

  @override
  String get updateMessage =>
      'एक नया संस्करण उपलब्ध है। जारी रखने के लिए कृपया अपडेट करें।';

  @override
  String get updateButton => 'अभी अपडेट करें';
}
