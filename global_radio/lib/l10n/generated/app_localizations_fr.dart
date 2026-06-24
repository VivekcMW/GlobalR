// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Global Radio';

  @override
  String get onboardingWelcome => 'Bienvenue sur Global Radio';

  @override
  String get onboardingSubtitle =>
      'Audio personnalisé selon vos centres d\'intérêt';

  @override
  String get onboardingSelectLanguages => 'Choisissez vos langues';

  @override
  String get onboardingSelectInterests => 'Choisissez vos centres d\'intérêt';

  @override
  String get onboardingSetupComplete => 'Vous êtes prêt !';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingSkip => 'Passer';

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
  String get interestsTitle => 'Modifier les centres d\'intérêt';

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
  String get homeTitle => 'Accueil';

  @override
  String get homeGreetingMorning => 'Bonjour';

  @override
  String get homeGreetingAfternoon => 'Bon après-midi';

  @override
  String get homeGreetingEvening => 'Bonsoir';

  @override
  String get homeListenNow => 'Écouter maintenant';

  @override
  String get homeRecommendedForYou => 'Recommandé pour vous';

  @override
  String get homeTrendingNow => 'Tendances actuelles';

  @override
  String get homeRecentlyPlayed => 'Écouté récemment';

  @override
  String get homeQuickPicks => 'Sélection rapide';

  @override
  String get libraryTitle => 'Bibliothèque';

  @override
  String get libraryFavorites => 'Favoris';

  @override
  String get libraryDownloads => 'Téléchargements';

  @override
  String get libraryHistory => 'Historique';

  @override
  String get libraryNoFavorites => 'Pas encore de favoris';

  @override
  String get libraryNoDownloads => 'Pas encore de téléchargements';

  @override
  String get libraryNoHistory => 'Pas encore d\'historique';

  @override
  String get libraryAddFavorites =>
      'Appuyez sur l\'icône cœur pour ajouter aux favoris';

  @override
  String get libraryDownloadContent =>
      'Téléchargez du contenu pour écouter hors ligne';

  @override
  String get libraryStartListening =>
      'Commencez à écouter pour voir votre historique';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsSignIn => 'Se connecter';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsLanguages => 'Langues';

  @override
  String get settingsInterests => 'Centres d\'intérêt';

  @override
  String get settingsVoice => 'Préférences vocales';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDownloads => 'Téléchargements';

  @override
  String get settingsDownloadsWifiOnly => 'Télécharger uniquement en Wi-Fi';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String get settingsClearCache => 'Vider le cache';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsTermsOfService => 'Conditions d\'utilisation';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsFeedback => 'Envoyer un commentaire';

  @override
  String get settingsRateApp => 'Noter l\'application';

  @override
  String get settingsShareApp => 'Partager avec des amis';

  @override
  String get playerNowPlaying => 'En cours de lecture';

  @override
  String get playerUpNext => 'Suivant';

  @override
  String get playerPlaybackSpeed => 'Vitesse de lecture';

  @override
  String get playerSleepTimer => 'Minuterie de sommeil';

  @override
  String get playerSleepTimerOff => 'Désactivé';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get playerAddToFavorites => 'Ajouter aux favoris';

  @override
  String get playerRemoveFromFavorites => 'Retirer des favoris';

  @override
  String get playerDownload => 'Télécharger';

  @override
  String get playerShare => 'Partager';

  @override
  String get interestsSubtitle =>
      'Choisissez les sujets que vous souhaitez écouter';

  @override
  String interestsSelected(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get interestsSave => 'Enregistrer';

  @override
  String get languagesTitle => 'Langues';

  @override
  String get languagesSubtitle => 'Choisissez vos langues préférées';

  @override
  String get languagesSave => 'Enregistrer';

  @override
  String get searchTitle => 'Rechercher';

  @override
  String get searchHint => 'Rechercher du contenu...';

  @override
  String get searchVoiceHint => 'Appuyez pour rechercher par la voix';

  @override
  String get searchNoResults => 'Aucun résultat trouvé';

  @override
  String get searchTryDifferent => 'Essayez d\'autres mots-clés';

  @override
  String get authSignInTitle => 'Se connecter';

  @override
  String get authSignInSubtitle =>
      'Connectez-vous pour synchroniser vos préférences';

  @override
  String get authContinueWithGoogle => 'Continuer avec Google';

  @override
  String get authContinueWithApple => 'Continuer avec Apple';

  @override
  String get authContinueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get authSignOutConfirm =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get premiumTitle => 'Passer à Premium';

  @override
  String get premiumSubtitle => 'Débloquez toutes les fonctionnalités';

  @override
  String get premiumFeature1 => 'Écoute sans publicité';

  @override
  String get premiumFeature2 => 'Téléchargements illimités';

  @override
  String get premiumFeature3 => 'Voix premium';

  @override
  String premiumSubscribe(String price) {
    return 'S\'abonner pour $price';
  }

  @override
  String get premiumRestore => 'Restaurer les achats';

  @override
  String get errorGeneric => 'Une erreur s\'est produite';

  @override
  String get errorNetwork => 'Pas de connexion Internet';

  @override
  String get errorRetry => 'Réessayer';

  @override
  String get errorLoadingContent => 'Échec du chargement du contenu';

  @override
  String get errorPlayback => 'Erreur de lecture';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonLoading => 'Chargement...';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get notificationDailyTitle => 'Votre audio quotidien';

  @override
  String get notificationDailyBody => 'Votre contenu personnalisé est prêt';

  @override
  String adSkipIn(int seconds) {
    return 'Passer dans $seconds secondes';
  }

  @override
  String get adSkip => 'Passer la publicité';

  @override
  String get adLabel => 'Publicité';

  @override
  String get offlineTitle => 'Mode hors ligne';

  @override
  String get offlineMessage =>
      'Vous êtes hors ligne. Seul le contenu téléchargé est disponible.';

  @override
  String get offlineDownloadAvailable => 'Téléchargez pour écouter hors ligne';

  @override
  String get feedbackTitle => 'Envoyer un commentaire';

  @override
  String get feedbackHint => 'Dites-nous ce que vous en pensez...';

  @override
  String get feedbackSubmit => 'Soumettre';

  @override
  String get feedbackThankYou => 'Merci pour votre commentaire !';

  @override
  String get updateRequired => 'Mise à jour requise';

  @override
  String get updateMessage =>
      'Une nouvelle version est disponible. Veuillez mettre à jour pour continuer.';

  @override
  String get updateButton => 'Mettre à jour maintenant';
}
