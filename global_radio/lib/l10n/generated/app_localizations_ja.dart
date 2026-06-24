// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'グローバルラジオ';

  @override
  String get onboardingWelcome => 'グローバルラジオへようこそ';

  @override
  String get onboardingSubtitle => 'あなたの興味に合わせたパーソナライズオーディオ';

  @override
  String get onboardingSelectLanguages => '言語を選択してください';

  @override
  String get onboardingSelectInterests => '興味を選択してください';

  @override
  String get onboardingSetupComplete => '準備完了です！';

  @override
  String get onboardingContinue => '続ける';

  @override
  String get onboardingGetStarted => '始める';

  @override
  String get onboardingSkip => 'スキップ';

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
  String get interestsTitle => '興味を編集';

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
  String get homeTitle => 'ホーム';

  @override
  String get homeGreetingMorning => 'おはようございます';

  @override
  String get homeGreetingAfternoon => 'こんにちは';

  @override
  String get homeGreetingEvening => 'こんばんは';

  @override
  String get homeListenNow => '今すぐ聴く';

  @override
  String get homeRecommendedForYou => 'あなたへのおすすめ';

  @override
  String get homeTrendingNow => 'トレンド';

  @override
  String get homeRecentlyPlayed => '最近再生したもの';

  @override
  String get homeQuickPicks => 'クイックピック';

  @override
  String get libraryTitle => 'ライブラリ';

  @override
  String get libraryFavorites => 'お気に入り';

  @override
  String get libraryDownloads => 'ダウンロード';

  @override
  String get libraryHistory => '履歴';

  @override
  String get libraryNoFavorites => 'お気に入りはまだありません';

  @override
  String get libraryNoDownloads => 'ダウンロードはまだありません';

  @override
  String get libraryNoHistory => '履歴はまだありません';

  @override
  String get libraryAddFavorites => 'ハートアイコンをタップしてお気に入りに追加';

  @override
  String get libraryDownloadContent => 'オフラインで聴くためにコンテンツをダウンロード';

  @override
  String get libraryStartListening => '履歴を見るには聴き始めてください';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsSignIn => 'サインイン';

  @override
  String get settingsSignOut => 'サインアウト';

  @override
  String get settingsLanguages => '言語';

  @override
  String get settingsInterests => '興味';

  @override
  String get settingsVoice => '音声設定';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsDownloads => 'ダウンロード';

  @override
  String get settingsDownloadsWifiOnly => 'Wi-Fi のみでダウンロード';

  @override
  String get settingsStorage => 'ストレージ';

  @override
  String get settingsClearCache => 'キャッシュをクリア';

  @override
  String get settingsAbout => 'アプリについて';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsTermsOfService => '利用規約';

  @override
  String settingsVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get settingsFeedback => 'フィードバックを送信';

  @override
  String get settingsRateApp => 'アプリを評価';

  @override
  String get settingsShareApp => '友達と共有';

  @override
  String get playerNowPlaying => '再生中';

  @override
  String get playerUpNext => '次の曲';

  @override
  String get playerPlaybackSpeed => '再生速度';

  @override
  String get playerSleepTimer => 'スリープタイマー';

  @override
  String get playerSleepTimerOff => 'オフ';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get playerAddToFavorites => 'お気に入りに追加';

  @override
  String get playerRemoveFromFavorites => 'お気に入りから削除';

  @override
  String get playerDownload => 'ダウンロード';

  @override
  String get playerShare => '共有';

  @override
  String get interestsSubtitle => '聴きたいトピックを選択してください';

  @override
  String interestsSelected(int count) {
    return '$count件選択済み';
  }

  @override
  String get interestsSave => '保存';

  @override
  String get languagesTitle => '言語';

  @override
  String get languagesSubtitle => 'お好みの言語を選択してください';

  @override
  String get languagesSave => '保存';

  @override
  String get searchTitle => '検索';

  @override
  String get searchHint => 'コンテンツを検索...';

  @override
  String get searchVoiceHint => 'タップして音声検索';

  @override
  String get searchNoResults => '結果が見つかりませんでした';

  @override
  String get searchTryDifferent => '別のキーワードを試してください';

  @override
  String get authSignInTitle => 'サインイン';

  @override
  String get authSignInSubtitle => '設定を同期するにはサインインしてください';

  @override
  String get authContinueWithGoogle => 'Google で続行';

  @override
  String get authContinueWithApple => 'Apple で続行';

  @override
  String get authContinueAsGuest => 'ゲストとして続行';

  @override
  String get authSignOutConfirm => '本当にサインアウトしますか？';

  @override
  String get premiumTitle => 'プレミアムになる';

  @override
  String get premiumSubtitle => 'すべての機能をアンロック';

  @override
  String get premiumFeature1 => '広告なしで聴く';

  @override
  String get premiumFeature2 => '無制限ダウンロード';

  @override
  String get premiumFeature3 => 'プレミアム音声';

  @override
  String premiumSubscribe(String price) {
    return '$priceで購読';
  }

  @override
  String get premiumRestore => '購入を復元';

  @override
  String get errorGeneric => '問題が発生しました';

  @override
  String get errorNetwork => 'インターネット接続がありません';

  @override
  String get errorRetry => '再試行';

  @override
  String get errorLoadingContent => 'コンテンツの読み込みに失敗しました';

  @override
  String get errorPlayback => '再生エラー';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get commonDone => '完了';

  @override
  String get commonLoading => '読み込み中...';

  @override
  String get commonRefresh => '更新';

  @override
  String get notificationDailyTitle => '今日のオーディオ';

  @override
  String get notificationDailyBody => 'パーソナライズされたコンテンツの準備ができました';

  @override
  String adSkipIn(int seconds) {
    return '$seconds秒後にスキップ';
  }

  @override
  String get adSkip => '広告をスキップ';

  @override
  String get adLabel => '広告';

  @override
  String get offlineTitle => 'オフラインモード';

  @override
  String get offlineMessage => 'オフラインです。ダウンロードしたコンテンツのみ利用可能です。';

  @override
  String get offlineDownloadAvailable => 'オフラインで聴くためにダウンロード';

  @override
  String get feedbackTitle => 'フィードバックを送信';

  @override
  String get feedbackHint => 'ご意見をお聞かせください...';

  @override
  String get feedbackSubmit => '送信';

  @override
  String get feedbackThankYou => 'フィードバックありがとうございます！';

  @override
  String get updateRequired => 'アップデートが必要です';

  @override
  String get updateMessage => '新しいバージョンが利用可能です。続行するにはアップデートしてください。';

  @override
  String get updateButton => '今すぐアップデート';
}
