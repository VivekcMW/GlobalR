/// App-wide constants: interests, languages, voice presets, CDN config.
///
/// These mirror the catalog schema and the launch matrix in /docs.
library;

import 'dart:ui' show Locale;

class AppConfig {
  AppConfig._();

  /// Base URL for the static catalog + pre-rendered MP3s (Cloudflare R2 / CDN).
  /// Audio URL convention: {cdnBase}/{lang}/{voiceId}/{itemId}.mp3
  /// Override at build time: --dart-define=CDN_BASE=https://cdn.yourdomain.com
  static const String cdnBase = String.fromEnvironment(
    'CDN_BASE',
    defaultValue: 'https://cdn.globalradio.app',
  );

  /// Remote catalog.json location (delta-updated, cached on device daily).
  static const String catalogUrl = String.fromEnvironment(
    'CATALOG_URL',
    defaultValue: '$cdnBase/catalog.json',
  );

  /// Base URL for legal documents (privacy policy, terms).
  static const String legalBaseUrl = String.fromEnvironment(
    'LEGAL_BASE_URL',
    defaultValue: 'https://globalradio.app/legal',
  );

  /// Support email address.
  static const String supportEmail = 'support@globalradio.app';

  /// Privacy email address.
  static const String privacyEmail = 'privacy@globalradio.app';

  /// App Store URL (iOS).
  static const String appStoreUrl = 'https://apps.apple.com/app/global-radio/id000000000';

  /// Play Store URL (Android).
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.globalradio.global_radio';

  /// Privacy Policy URL.
  static const String privacyPolicyUrl = '$legalBaseUrl/privacy';

  /// Terms of Service URL.
  static const String termsOfServiceUrl = '$legalBaseUrl/terms';

  /// Bundled seed catalog, used on first launch / offline before the
  /// remote catalog is fetched.
  static const String bundledCatalogAsset = 'assets/catalog/catalog.json';

  /// When true, every item plays a bundled per-voice demo clip from
  /// `assets/audio/demo/{voiceId}.mp3` instead of the (not-yet-real) CDN URL,
  /// so audio can be tested end-to-end with no backend.
  /// Disable for real playback: --dart-define=DEMO_AUDIO=false
  static const bool demoAudio = bool.fromEnvironment(
    'DEMO_AUDIO',
    defaultValue: true,
  );

  /// Folder holding the bundled demo clips, laid out as
  /// `{demoAudioDir}/{language}/{voiceId}.mp3` (mirrors the real CDN convention).
  static const String demoAudioDir = 'assets/audio/demo';

  /// Languages we ship bundled demo clips for. Items in any other language
  /// fall back to [demoFallbackLanguage] so playback never breaks.
  static const Set<String> demoLanguages = {'english', 'hindi'};
  static const String demoFallbackLanguage = 'english';

  /// The demo language actually used for [language]: itself if bundled, else
  /// the fallback.
  static String demoLanguageFor(String language) =>
      demoLanguages.contains(language) ? language : demoFallbackLanguage;

  /// Subscription price shown in the upsell sheet.
  static const String premiumYearlyPrice = '₹99 / year';

  /// When false (default) the app uses the local [DevAuthService] so the sign-in
  /// flow works with no backend. Flip on once Firebase is configured:
  /// --dart-define=USE_FIREBASE_AUTH=true
  static const bool useFirebaseAuth = bool.fromEnvironment(
    'USE_FIREBASE_AUTH',
    defaultValue: false,
  );

  /// When true, the app subscribes to FCM topics for the daily-astrology push
  /// (the server side is `tools/astrology_cron.py --notify`). Off by default so
  /// builds run with no backend; requires Firebase configured (see
  /// tools/setup_firebase.sh). --dart-define=USE_PUSH=true
  static const bool usePush = bool.fromEnvironment(
    'USE_PUSH',
    defaultValue: false,
  );

  /// When true, Firebase Analytics is used for tracking events. Off by default;
  /// enable with --dart-define=USE_ANALYTICS=true. Falls back to debug logging
  /// when disabled.
  static const bool useAnalytics = bool.fromEnvironment(
    'USE_ANALYTICS',
    defaultValue: false,
  );

  /// When true, Firebase Crashlytics is used for crash reporting. Off by default;
  /// enable with --dart-define=USE_CRASHLYTICS=true. Falls back to debug logging
  /// when disabled.
  static const bool useCrashlytics = bool.fromEnvironment(
    'USE_CRASHLYTICS',
    defaultValue: false,
  );

  /// When true, Firebase Remote Config is used for feature flags. Off by default;
  /// enable with --dart-define=USE_REMOTE_CONFIG=true.
  static const bool useRemoteConfig = bool.fromEnvironment(
    'USE_REMOTE_CONFIG',
    defaultValue: false,
  );

  /// Minimum app version required. Used for force update check.
  /// Format: "major.minor.patch+buildNumber"
  static const String minAppVersion = String.fromEnvironment(
    'MIN_APP_VERSION',
    defaultValue: '1.0.0+1',
  );

  /// Current app version. Displayed in settings.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Firebase must be initialized for auth, push, analytics, or crashlytics.
  static const bool useFirebase = useFirebaseAuth || usePush || useAnalytics || useCrashlytics || useRemoteConfig;
}

/// Listening interests. `id` is the stable key used in the catalog + storage.
class Interest {
  final String id;
  final String label;
  final int iconCodePoint; // Material icon code point
  final String description; // short description for UI
  final String category; // category for grouping
  const Interest(this.id, this.label, this.iconCodePoint, this.description, [this.category = 'General']);

  // Stories & Kids
  static const kids = Interest('kids', 'Kids', 0xe32a, 'Stories for children', 'Stories');
  static const moral = Interest('moral', 'Moral Stories', 0xe3e1, 'Life lessons & values', 'Stories');
  static const mythology = Interest('mythology', 'Mythology', 0xe0b7, 'Ancient tales & epics', 'Stories');
  static const fairytales = Interest('fairytales', 'Fairy Tales', 0xe22a, 'Magical adventures', 'Stories');
  static const bedtime = Interest('bedtime', 'Bedtime Stories', 0xef44, 'Calm stories for sleep', 'Stories');

  // Spiritual & Wellness
  static const devotion = Interest('devotion', 'Devotion', 0xea23, 'Spiritual content', 'Spiritual');
  static const meditation = Interest('meditation', 'Meditation', 0xea1e, 'Mindfulness & calm', 'Spiritual');
  static const yoga = Interest('yoga', 'Yoga', 0xea22, 'Yoga guidance & tips', 'Spiritual');
  static const astrology = Interest('astrology', 'Astrology', 0xf06f, 'Daily horoscopes', 'Spiritual');
  static const mantras = Interest('mantras', 'Mantras & Chants', 0xe312, 'Sacred chants', 'Spiritual');

  // Knowledge & Learning
  static const education = Interest('education', 'Education', 0xe80c, 'Learn something new', 'Knowledge');
  static const history = Interest('history', 'History', 0xe889, 'Historical stories', 'Knowledge');
  static const science = Interest('science', 'Science', 0xea4b, 'Scientific wonders', 'Knowledge');
  static const technology = Interest('technology', 'Technology', 0xe30a, 'Tech news & trends', 'Knowledge');
  static const biography = Interest('biography', 'Biographies', 0xe7fd, 'Inspiring life stories', 'Knowledge');

  // Entertainment
  static const comedy = Interest('comedy', 'Comedy', 0xe5c8, 'Jokes & funny content', 'Entertainment');
  static const drama = Interest('drama', 'Drama', 0xe8d4, 'Dramatic stories', 'Entertainment');
  static const music = Interest('music', 'Music', 0xe405, 'Songs & melodies', 'Entertainment');
  static const poetry = Interest('poetry', 'Poetry', 0xe254, 'Verses & poems', 'Entertainment');
  static const fiction = Interest('fiction', 'Fiction', 0xe865, 'Imaginative stories', 'Entertainment');

  // Lifestyle
  static const health = Interest('health', 'Health', 0xe3f3, 'Health & fitness tips', 'Lifestyle');
  static const cooking = Interest('cooking', 'Cooking', 0xe56c, 'Recipes & food tips', 'Lifestyle');
  static const travel = Interest('travel', 'Travel', 0xe539, 'Travel stories & tips', 'Lifestyle');
  static const motivation = Interest('motivation', 'Motivation', 0xe68b, 'Inspiring talks', 'Lifestyle');
  static const relationships = Interest('relationships', 'Relationships', 0xe87d, 'Love & family', 'Lifestyle');

  // News & Current Affairs
  static const news = Interest('news', 'News', 0xef42, 'Daily news updates', 'News');
  static const business = Interest('business', 'Business', 0xe0af, 'Business & finance', 'News');
  static const sports = Interest('sports', 'Sports', 0xeb45, 'Sports updates', 'News');
  static const politics = Interest('politics', 'Politics', 0xe0b7, 'Political news', 'News');

  // Regional & Culture
  static const folklore = Interest('folklore', 'Folklore', 0xe8da, 'Regional folk tales', 'Culture');
  static const culture = Interest('culture', 'Culture', 0xe40a, 'Arts & traditions', 'Culture');
  static const festivals = Interest('festivals', 'Festivals', 0xe7e9, 'Festival stories', 'Culture');

  /// All categories in display order.
  static const categories = ['Stories', 'Spiritual', 'Knowledge', 'Entertainment', 'Lifestyle', 'News', 'Culture'];

  static const all = <Interest>[
    // Most popular first
    kids, moral, devotion, astrology,
    mythology, meditation, motivation, health,
    bedtime, fairytales, mantras, yoga,
    comedy, music, poetry, drama,
    education, history, science, biography,
    news, business, sports, technology,
    cooking, travel, relationships, fiction,
    folklore, culture, festivals, politics,
  ];

  /// Get interests by category.
  static List<Interest> byCategory(String category) =>
      all.where((i) => i.category == category).toList();

  static Interest? byId(String id) {
    for (final i in all) {
      if (i.id == id) return i;
    }
    return null;
  }

  static String labelFor(String id) => byId(id)?.label ?? id;
  static String descriptionFor(String id) => byId(id)?.description ?? '';
}

/// Languages selectable in v1. Tier reflects TTS readiness (see docs matrix).
class AppLanguage {
  final String code; // catalog `language` value
  final String englishName;
  final String nativeName;
  final int tier; // 1 = Azure ship-ready, 2 = AI4Bharat, 3 = best-effort
  const AppLanguage(this.code, this.englishName, this.nativeName, this.tier);

  // Tier 1: Primary Indian Languages (Azure TTS ready)
  static const english = AppLanguage('english', 'English', 'English', 1);
  static const hindi = AppLanguage('hindi', 'Hindi', 'हिन्दी', 1);
  static const bengali = AppLanguage('bengali', 'Bengali', 'বাংলা', 1);
  static const marathi = AppLanguage('marathi', 'Marathi', 'मराठी', 1);
  static const telugu = AppLanguage('telugu', 'Telugu', 'తెలుగు', 1);
  static const tamil = AppLanguage('tamil', 'Tamil', 'தமிழ்', 1);
  static const gujarati = AppLanguage('gujarati', 'Gujarati', 'ગુજરાતી', 1);
  static const urdu = AppLanguage('urdu', 'Urdu', 'اردو', 1);
  static const kannada = AppLanguage('kannada', 'Kannada', 'ಕನ್ನಡ', 1);
  static const odia = AppLanguage('odia', 'Odia', 'ଓଡ଼ିଆ', 1);
  static const malayalam = AppLanguage('malayalam', 'Malayalam', 'മലയാളം', 1);
  static const punjabi = AppLanguage('punjabi', 'Punjabi', 'ਪੰਜਾਬੀ', 1);
  static const assamese = AppLanguage('assamese', 'Assamese', 'অসমীয়া', 1);

  // Tier 2: Additional Indian Languages (Scheduled/Regional)
  static const kashmiri = AppLanguage('kashmiri', 'Kashmiri', 'कॉशुर', 2);
  static const sindhi = AppLanguage('sindhi', 'Sindhi', 'سنڌي', 2);
  static const nepali = AppLanguage('nepali', 'Nepali', 'नेपाली', 2);
  static const dogri = AppLanguage('dogri', 'Dogri', 'डोगरी', 2);
  static const konkani = AppLanguage('konkani', 'Konkani', 'कोंकणी', 2);
  static const maithili = AppLanguage('maithili', 'Maithili', 'मैथिली', 2);
  static const santali = AppLanguage('santali', 'Santali', 'ᱥᱟᱱᱛᱟᱲᱤ', 2);
  static const manipuri = AppLanguage('manipuri', 'Manipuri', 'মৈতৈলোন্', 2);
  static const bodo = AppLanguage('bodo', 'Bodo', 'बड़ो', 2);

  // Tier 3: International Languages
  static const arabic = AppLanguage('arabic', 'Arabic', 'العربية', 3);
  static const french = AppLanguage('french', 'French', 'Français', 3);
  static const portuguese = AppLanguage('portuguese', 'Portuguese', 'Português', 3);
  static const chinese = AppLanguage('chinese', 'Chinese', '中文', 3);
  static const spanish = AppLanguage('spanish', 'Spanish', 'Español', 3);
  static const german = AppLanguage('german', 'German', 'Deutsch', 3);
  static const japanese = AppLanguage('japanese', 'Japanese', '日本語', 3);
  static const korean = AppLanguage('korean', 'Korean', '한국어', 3);

  /// Tier-1 languages are live with full Azure quality (see docs).
  static const tier1 = <AppLanguage>[
    hindi, english, bengali, marathi, telugu, tamil, gujarati,
    urdu, kannada, odia, malayalam, punjabi, assamese,
  ];

  /// Tier-2 languages: Additional Indian scheduled/regional languages.
  static const tier2 = <AppLanguage>[
    kashmiri, sindhi, nepali, dogri, konkani, maithili, santali, manipuri, bodo,
  ];

  /// Tier-3 languages: International languages for global reach.
  static const tier3 = <AppLanguage>[
    arabic, french, portuguese, chinese, spanish, german, japanese, korean,
  ];

  /// All supported languages across all tiers.
  static const all = <AppLanguage>[
    // Tier 1 - Primary Indian
    hindi, english, bengali, marathi, telugu, tamil, gujarati,
    urdu, kannada, odia, malayalam, punjabi, assamese,
    // Tier 2 - Additional Indian
    kashmiri, sindhi, nepali, dogri, konkani, maithili, santali, manipuri, bodo,
    // Tier 3 - International
    arabic, french, portuguese, chinese, spanish, german, japanese, korean,
  ];

  /// Languages requiring RTL (right-to-left) layout.
  static const rtlLanguages = {'urdu', 'arabic', 'sindhi', 'kashmiri'};

  /// Check if a language code requires RTL layout.
  static bool isRtl(String code) => rtlLanguages.contains(code);

  static AppLanguage? byCode(String code) {
    for (final l in all) {
      if (l.code == code) return l;
    }
    return null;
  }

  static String nativeNameFor(String code) => byCode(code)?.nativeName ?? code;
  
  /// Get languages by tier.
  static List<AppLanguage> byTier(int tier) => all.where((l) => l.tier == tier).toList();

  /// Map language code (e.g., 'hindi') to Flutter Locale (e.g., Locale('hi')).
  Locale toLocale() => Locale(_languageCodeMap[code] ?? 'en');

  /// Static version for use with language code string.
  static Locale localeFor(String code) {
    final lang = byCode(code);
    return lang?.toLocale() ?? const Locale('en');
  }

  /// ISO 639-1 code mapping from app language codes.
  static const _languageCodeMap = <String, String>{
    // Tier 1 - Primary Indian
    'english': 'en',
    'hindi': 'hi',
    'bengali': 'bn',
    'marathi': 'mr',
    'telugu': 'te',
    'tamil': 'ta',
    'gujarati': 'gu',
    'urdu': 'ur',
    'kannada': 'kn',
    'odia': 'or',
    'malayalam': 'ml',
    'punjabi': 'pa',
    'assamese': 'as',
    // Tier 2 - Additional Indian
    'kashmiri': 'ks',
    'sindhi': 'sd',
    'nepali': 'ne',
    'dogri': 'doi',
    'konkani': 'kok',
    'maithili': 'mai',
    'santali': 'sat',
    'manipuri': 'mni',
    'bodo': 'brx',
    // Tier 3 - International
    'arabic': 'ar',
    'french': 'fr',
    'portuguese': 'pt',
    'chinese': 'zh',
    'spanish': 'es',
    'german': 'de',
    'japanese': 'ja',
    'korean': 'ko',
  };
}

/// Curated narration voice presets (pre-rendered once, reused for all users).
class VoicePreset {
  final String id;
  final String label;
  final String shortLabel; // 3-4 char label for mini-player badge
  final String icon;
  final String description;
  final bool premium; // true = unlocked only for premium users
  const VoicePreset(this.id, this.label, this.shortLabel, this.icon, this.description, {this.premium = false});

  static const maleStory =
      VoicePreset('male_story', 'Storyteller (Male)', 'Tale', '📖', 'Warm male narrator — moral stories');
  static const kidsStory =
      VoicePreset('kids_story', 'Kids Storyteller', 'Kids', '🧒', 'Bright, energetic — children\'s stories');
  static const femaleWarm =
      VoicePreset('female_warm', 'Warm (Female)', 'Calm', '🌸', 'Gentle female voice — daily & astrology');
  static const devotional =
      VoicePreset('devotional', 'Devotional', 'Dev', '🪔', 'Calm, reverent — bhajans & slokas', premium: true);

  /// The single free-tier default voice every language ships with.
  static const String freeDefaultId = 'male_story';

  static const all = <VoicePreset>[maleStory, kidsStory, femaleWarm, devotional];

  static VoicePreset? byId(String id) {
    for (final v in all) {
      if (v.id == id) return v;
    }
    return null;
  }
}
