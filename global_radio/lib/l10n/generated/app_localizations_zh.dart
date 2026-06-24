// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '全球广播';

  @override
  String get onboardingWelcome => '欢迎使用全球广播';

  @override
  String get onboardingSubtitle => '为您的兴趣量身定制的音频';

  @override
  String get onboardingSelectLanguages => '选择您的语言';

  @override
  String get onboardingSelectInterests => '选择您的兴趣';

  @override
  String get onboardingSetupComplete => '您已准备就绪！';

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingGetStarted => '开始';

  @override
  String get onboardingSkip => '跳过';

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
  String get interestsTitle => '编辑兴趣';

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
  String get homeTitle => '首页';

  @override
  String get homeGreetingMorning => '早上好';

  @override
  String get homeGreetingAfternoon => '下午好';

  @override
  String get homeGreetingEvening => '晚上好';

  @override
  String get homeListenNow => '立即收听';

  @override
  String get homeRecommendedForYou => '为您推荐';

  @override
  String get homeTrendingNow => '当前热门';

  @override
  String get homeRecentlyPlayed => '最近播放';

  @override
  String get homeQuickPicks => '快速精选';

  @override
  String get libraryTitle => '资料库';

  @override
  String get libraryFavorites => '收藏';

  @override
  String get libraryDownloads => '下载';

  @override
  String get libraryHistory => '历史记录';

  @override
  String get libraryNoFavorites => '暂无收藏';

  @override
  String get libraryNoDownloads => '暂无下载';

  @override
  String get libraryNoHistory => '暂无历史记录';

  @override
  String get libraryAddFavorites => '点击心形图标添加到收藏';

  @override
  String get libraryDownloadContent => '下载内容以便离线收听';

  @override
  String get libraryStartListening => '开始收听以查看您的历史记录';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAccount => '账户';

  @override
  String get settingsSignIn => '登录';

  @override
  String get settingsSignOut => '退出';

  @override
  String get settingsLanguages => '语言';

  @override
  String get settingsInterests => '兴趣';

  @override
  String get settingsVoice => '语音偏好';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsDownloads => '下载';

  @override
  String get settingsDownloadsWifiOnly => '仅在 Wi-Fi 下下载';

  @override
  String get settingsStorage => '存储';

  @override
  String get settingsClearCache => '清除缓存';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get settingsFeedback => '发送反馈';

  @override
  String get settingsRateApp => '评价应用';

  @override
  String get settingsShareApp => '与朋友分享';

  @override
  String get playerNowPlaying => '正在播放';

  @override
  String get playerUpNext => '接下来';

  @override
  String get playerPlaybackSpeed => '播放速度';

  @override
  String get playerSleepTimer => '睡眠定时器';

  @override
  String get playerSleepTimerOff => '关闭';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get playerAddToFavorites => '添加到收藏';

  @override
  String get playerRemoveFromFavorites => '从收藏中移除';

  @override
  String get playerDownload => '下载';

  @override
  String get playerShare => '分享';

  @override
  String get interestsSubtitle => '选择您想收听的主题';

  @override
  String interestsSelected(int count) {
    return '已选择 $count 个';
  }

  @override
  String get interestsSave => '保存';

  @override
  String get languagesTitle => '语言';

  @override
  String get languagesSubtitle => '选择您偏好的语言';

  @override
  String get languagesSave => '保存';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchHint => '搜索内容...';

  @override
  String get searchVoiceHint => '点击使用语音搜索';

  @override
  String get searchNoResults => '未找到结果';

  @override
  String get searchTryDifferent => '尝试不同的关键词';

  @override
  String get authSignInTitle => '登录';

  @override
  String get authSignInSubtitle => '登录以同步您的偏好设置';

  @override
  String get authContinueWithGoogle => '使用 Google 继续';

  @override
  String get authContinueWithApple => '使用 Apple 继续';

  @override
  String get authContinueAsGuest => '以访客身份继续';

  @override
  String get authSignOutConfirm => '您确定要退出吗？';

  @override
  String get premiumTitle => '升级高级版';

  @override
  String get premiumSubtitle => '解锁所有功能';

  @override
  String get premiumFeature1 => '无广告收听';

  @override
  String get premiumFeature2 => '无限下载';

  @override
  String get premiumFeature3 => '高级语音';

  @override
  String premiumSubscribe(String price) {
    return '以 $price 订阅';
  }

  @override
  String get premiumRestore => '恢复购买';

  @override
  String get errorGeneric => '出现错误';

  @override
  String get errorNetwork => '无网络连接';

  @override
  String get errorRetry => '重试';

  @override
  String get errorLoadingContent => '内容加载失败';

  @override
  String get errorPlayback => '播放错误';

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonDone => '完成';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonRefresh => '刷新';

  @override
  String get notificationDailyTitle => '您的每日音频';

  @override
  String get notificationDailyBody => '您的个性化内容已准备就绪';

  @override
  String adSkipIn(int seconds) {
    return '$seconds 秒后跳过';
  }

  @override
  String get adSkip => '跳过广告';

  @override
  String get adLabel => '广告';

  @override
  String get offlineTitle => '离线模式';

  @override
  String get offlineMessage => '您当前处于离线状态。仅已下载的内容可用。';

  @override
  String get offlineDownloadAvailable => '下载以便离线收听';

  @override
  String get feedbackTitle => '发送反馈';

  @override
  String get feedbackHint => '告诉我们您的想法...';

  @override
  String get feedbackSubmit => '提交';

  @override
  String get feedbackThankYou => '感谢您的反馈！';

  @override
  String get updateRequired => '需要更新';

  @override
  String get updateMessage => '新版本可用。请更新以继续使用。';

  @override
  String get updateButton => '立即更新';
}
