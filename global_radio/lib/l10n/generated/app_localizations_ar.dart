// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'راديو جلوبال';

  @override
  String get onboardingWelcome => 'مرحباً بكم في راديو جلوبال';

  @override
  String get onboardingSubtitle => 'صوتيات مخصصة لاهتماماتك';

  @override
  String get onboardingSelectLanguages => 'اختر لغاتك';

  @override
  String get onboardingSelectInterests => 'اختر اهتماماتك';

  @override
  String get onboardingSetupComplete => 'أنت جاهز!';

  @override
  String get onboardingContinue => 'متابعة';

  @override
  String get onboardingGetStarted => 'ابدأ';

  @override
  String get onboardingSkip => 'تخطي';

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
  String get interestsTitle => 'تعديل الاهتمامات';

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
  String get homeTitle => 'الرئيسية';

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingAfternoon => 'مساء الخير';

  @override
  String get homeGreetingEvening => 'مساء الخير';

  @override
  String get homeListenNow => 'استمع الآن';

  @override
  String get homeRecommendedForYou => 'موصى به لك';

  @override
  String get homeTrendingNow => 'الرائج الآن';

  @override
  String get homeRecentlyPlayed => 'تم تشغيله مؤخراً';

  @override
  String get homeQuickPicks => 'اختيارات سريعة';

  @override
  String get libraryTitle => 'المكتبة';

  @override
  String get libraryFavorites => 'المفضلة';

  @override
  String get libraryDownloads => 'التنزيلات';

  @override
  String get libraryHistory => 'السجل';

  @override
  String get libraryNoFavorites => 'لا توجد مفضلات بعد';

  @override
  String get libraryNoDownloads => 'لا توجد تنزيلات بعد';

  @override
  String get libraryNoHistory => 'لا يوجد سجل بعد';

  @override
  String get libraryAddFavorites => 'انقر على أيقونة القلب للإضافة إلى المفضلة';

  @override
  String get libraryDownloadContent => 'قم بتنزيل المحتوى للاستماع بدون إنترنت';

  @override
  String get libraryStartListening => 'ابدأ الاستماع لرؤية سجلك';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsSignIn => 'تسجيل الدخول';

  @override
  String get settingsSignOut => 'تسجيل الخروج';

  @override
  String get settingsLanguages => 'اللغات';

  @override
  String get settingsInterests => 'الاهتمامات';

  @override
  String get settingsVoice => 'تفضيلات الصوت';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsDownloads => 'التنزيلات';

  @override
  String get settingsDownloadsWifiOnly => 'التنزيل عبر Wi-Fi فقط';

  @override
  String get settingsStorage => 'التخزين';

  @override
  String get settingsClearCache => 'مسح ذاكرة التخزين المؤقت';

  @override
  String get settingsAbout => 'حول';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsTermsOfService => 'شروط الخدمة';

  @override
  String settingsVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get settingsFeedback => 'إرسال ملاحظات';

  @override
  String get settingsRateApp => 'قيّم التطبيق';

  @override
  String get settingsShareApp => 'شارك مع الأصدقاء';

  @override
  String get playerNowPlaying => 'يتم التشغيل الآن';

  @override
  String get playerUpNext => 'التالي';

  @override
  String get playerPlaybackSpeed => 'سرعة التشغيل';

  @override
  String get playerSleepTimer => 'مؤقت النوم';

  @override
  String get playerSleepTimerOff => 'إيقاف';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes دقائق';
  }

  @override
  String get playerAddToFavorites => 'أضف إلى المفضلة';

  @override
  String get playerRemoveFromFavorites => 'إزالة من المفضلة';

  @override
  String get playerDownload => 'تنزيل';

  @override
  String get playerShare => 'مشاركة';

  @override
  String get interestsSubtitle => 'اختر المواضيع التي تريد الاستماع إليها';

  @override
  String interestsSelected(int count) {
    return '$count محدد';
  }

  @override
  String get interestsSave => 'حفظ';

  @override
  String get languagesTitle => 'اللغات';

  @override
  String get languagesSubtitle => 'اختر لغاتك المفضلة';

  @override
  String get languagesSave => 'حفظ';

  @override
  String get searchTitle => 'بحث';

  @override
  String get searchHint => 'ابحث عن محتوى...';

  @override
  String get searchVoiceHint => 'انقر للبحث بالصوت';

  @override
  String get searchNoResults => 'لم يتم العثور على نتائج';

  @override
  String get searchTryDifferent => 'جرب كلمات مختلفة';

  @override
  String get authSignInTitle => 'تسجيل الدخول';

  @override
  String get authSignInSubtitle => 'سجل دخولك لمزامنة تفضيلاتك';

  @override
  String get authContinueWithGoogle => 'المتابعة مع Google';

  @override
  String get authContinueWithApple => 'المتابعة مع Apple';

  @override
  String get authContinueAsGuest => 'المتابعة كضيف';

  @override
  String get authSignOutConfirm => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get premiumTitle => 'احصل على بريميوم';

  @override
  String get premiumSubtitle => 'افتح جميع المميزات';

  @override
  String get premiumFeature1 => 'استماع بدون إعلانات';

  @override
  String get premiumFeature2 => 'تنزيلات غير محدودة';

  @override
  String get premiumFeature3 => 'أصوات بريميوم';

  @override
  String premiumSubscribe(String price) {
    return 'اشترك بـ $price';
  }

  @override
  String get premiumRestore => 'استعادة المشتريات';

  @override
  String get errorGeneric => 'حدث خطأ ما';

  @override
  String get errorNetwork => 'لا يوجد اتصال بالإنترنت';

  @override
  String get errorRetry => 'إعادة المحاولة';

  @override
  String get errorLoadingContent => 'فشل تحميل المحتوى';

  @override
  String get errorPlayback => 'خطأ في التشغيل';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonOk => 'موافق';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonDone => 'تم';

  @override
  String get commonLoading => 'جارٍ التحميل...';

  @override
  String get commonRefresh => 'تحديث';

  @override
  String get notificationDailyTitle => 'صوتياتك اليومية';

  @override
  String get notificationDailyBody => 'محتواك المخصص جاهز';

  @override
  String adSkipIn(int seconds) {
    return 'تخطي في $seconds ثوانٍ';
  }

  @override
  String get adSkip => 'تخطي الإعلان';

  @override
  String get adLabel => 'إعلان';

  @override
  String get offlineTitle => 'وضع عدم الاتصال';

  @override
  String get offlineMessage => 'أنت غير متصل. المحتوى المُنزّل فقط متاح.';

  @override
  String get offlineDownloadAvailable => 'قم بالتنزيل للاستماع بدون إنترنت';

  @override
  String get feedbackTitle => 'إرسال ملاحظات';

  @override
  String get feedbackHint => 'أخبرنا برأيك...';

  @override
  String get feedbackSubmit => 'إرسال';

  @override
  String get feedbackThankYou => 'شكراً على ملاحظاتك!';

  @override
  String get updateRequired => 'التحديث مطلوب';

  @override
  String get updateMessage => 'يتوفر إصدار جديد. يرجى التحديث للمتابعة.';

  @override
  String get updateButton => 'تحديث الآن';
}
