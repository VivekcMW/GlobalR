// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Global Radio';

  @override
  String get onboardingWelcome => 'Willkommen bei Global Radio';

  @override
  String get onboardingSubtitle => 'Personalisiertes Audio für Ihre Interessen';

  @override
  String get onboardingSelectLanguages => 'Wählen Sie Ihre Sprachen';

  @override
  String get onboardingSelectInterests => 'Wählen Sie Ihre Interessen';

  @override
  String get onboardingSetupComplete => 'Sie sind bereit!';

  @override
  String get onboardingContinue => 'Weiter';

  @override
  String get onboardingGetStarted => 'Los geht\'s';

  @override
  String get onboardingSkip => 'Überspringen';

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
  String get interestsTitle => 'Interessen bearbeiten';

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
  String get homeTitle => 'Startseite';

  @override
  String get homeGreetingMorning => 'Guten Morgen';

  @override
  String get homeGreetingAfternoon => 'Guten Tag';

  @override
  String get homeGreetingEvening => 'Guten Abend';

  @override
  String get homeListenNow => 'Jetzt anhören';

  @override
  String get homeRecommendedForYou => 'Empfohlen für Sie';

  @override
  String get homeTrendingNow => 'Jetzt im Trend';

  @override
  String get homeRecentlyPlayed => 'Kürzlich gespielt';

  @override
  String get homeQuickPicks => 'Schnelle Auswahl';

  @override
  String get libraryTitle => 'Bibliothek';

  @override
  String get libraryFavorites => 'Favoriten';

  @override
  String get libraryDownloads => 'Downloads';

  @override
  String get libraryHistory => 'Verlauf';

  @override
  String get libraryNoFavorites => 'Noch keine Favoriten';

  @override
  String get libraryNoDownloads => 'Noch keine Downloads';

  @override
  String get libraryNoHistory => 'Noch kein Verlauf';

  @override
  String get libraryAddFavorites =>
      'Tippen Sie auf das Herz-Symbol, um zu Favoriten hinzuzufügen';

  @override
  String get libraryDownloadContent =>
      'Laden Sie Inhalte herunter, um offline zu hören';

  @override
  String get libraryStartListening =>
      'Beginnen Sie zu hören, um Ihren Verlauf zu sehen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsSignIn => 'Anmelden';

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsLanguages => 'Sprachen';

  @override
  String get settingsInterests => 'Interessen';

  @override
  String get settingsVoice => 'Spracheinstellungen';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsDownloads => 'Downloads';

  @override
  String get settingsDownloadsWifiOnly => 'Nur über WLAN herunterladen';

  @override
  String get settingsStorage => 'Speicher';

  @override
  String get settingsClearCache => 'Cache leeren';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get settingsTermsOfService => 'Nutzungsbedingungen';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsFeedback => 'Feedback senden';

  @override
  String get settingsRateApp => 'App bewerten';

  @override
  String get settingsShareApp => 'Mit Freunden teilen';

  @override
  String get playerNowPlaying => 'Wird jetzt gespielt';

  @override
  String get playerUpNext => 'Als Nächstes';

  @override
  String get playerPlaybackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String get playerSleepTimer => 'Schlaf-Timer';

  @override
  String get playerSleepTimerOff => 'Aus';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes Minuten';
  }

  @override
  String get playerAddToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get playerRemoveFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get playerDownload => 'Herunterladen';

  @override
  String get playerShare => 'Teilen';

  @override
  String get interestsSubtitle =>
      'Wählen Sie die Themen, die Sie hören möchten';

  @override
  String interestsSelected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get interestsSave => 'Speichern';

  @override
  String get languagesTitle => 'Sprachen';

  @override
  String get languagesSubtitle => 'Wählen Sie Ihre bevorzugten Sprachen';

  @override
  String get languagesSave => 'Speichern';

  @override
  String get searchTitle => 'Suchen';

  @override
  String get searchHint => 'Inhalte suchen...';

  @override
  String get searchVoiceHint => 'Tippen Sie für Sprachsuche';

  @override
  String get searchNoResults => 'Keine Ergebnisse gefunden';

  @override
  String get searchTryDifferent => 'Versuchen Sie andere Stichwörter';

  @override
  String get authSignInTitle => 'Anmelden';

  @override
  String get authSignInSubtitle =>
      'Melden Sie sich an, um Ihre Einstellungen zu synchronisieren';

  @override
  String get authContinueWithGoogle => 'Mit Google fortfahren';

  @override
  String get authContinueWithApple => 'Mit Apple fortfahren';

  @override
  String get authContinueAsGuest => 'Als Gast fortfahren';

  @override
  String get authSignOutConfirm =>
      'Sind Sie sicher, dass Sie sich abmelden möchten?';

  @override
  String get premiumTitle => 'Premium werden';

  @override
  String get premiumSubtitle => 'Alle Funktionen freischalten';

  @override
  String get premiumFeature1 => 'Werbefreies Hören';

  @override
  String get premiumFeature2 => 'Unbegrenzte Downloads';

  @override
  String get premiumFeature3 => 'Premium-Stimmen';

  @override
  String premiumSubscribe(String price) {
    return 'Für $price abonnieren';
  }

  @override
  String get premiumRestore => 'Käufe wiederherstellen';

  @override
  String get errorGeneric => 'Etwas ist schief gelaufen';

  @override
  String get errorNetwork => 'Keine Internetverbindung';

  @override
  String get errorRetry => 'Erneut versuchen';

  @override
  String get errorLoadingContent => 'Laden des Inhalts fehlgeschlagen';

  @override
  String get errorPlayback => 'Wiedergabefehler';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonLoading => 'Wird geladen...';

  @override
  String get commonRefresh => 'Aktualisieren';

  @override
  String get notificationDailyTitle => 'Ihr tägliches Audio';

  @override
  String get notificationDailyBody => 'Ihr personalisierter Inhalt ist bereit';

  @override
  String adSkipIn(int seconds) {
    return 'In $seconds Sekunden überspringen';
  }

  @override
  String get adSkip => 'Werbung überspringen';

  @override
  String get adLabel => 'Werbung';

  @override
  String get offlineTitle => 'Offline-Modus';

  @override
  String get offlineMessage =>
      'Sie sind offline. Nur heruntergeladene Inhalte sind verfügbar.';

  @override
  String get offlineDownloadAvailable => 'Herunterladen für Offline-Hören';

  @override
  String get feedbackTitle => 'Feedback senden';

  @override
  String get feedbackHint => 'Teilen Sie uns Ihre Meinung mit...';

  @override
  String get feedbackSubmit => 'Absenden';

  @override
  String get feedbackThankYou => 'Danke für Ihr Feedback!';

  @override
  String get updateRequired => 'Update erforderlich';

  @override
  String get updateMessage =>
      'Neue Version verfügbar. Bitte aktualisieren Sie, um fortzufahren.';

  @override
  String get updateButton => 'Jetzt aktualisieren';
}
