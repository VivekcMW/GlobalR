// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Global Radio';

  @override
  String get onboardingWelcome => 'Bienvenido a Global Radio';

  @override
  String get onboardingSubtitle => 'Audio personalizado para tus intereses';

  @override
  String get onboardingSelectLanguages => 'Elige tus idiomas';

  @override
  String get onboardingSelectInterests => 'Elige tus intereses';

  @override
  String get onboardingSetupComplete => '¡Estás listo!';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get onboardingSkip => 'Omitir';

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
  String get interestsTitle => 'Editar intereses';

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
  String get homeTitle => 'Inicio';

  @override
  String get homeGreetingMorning => 'Buenos días';

  @override
  String get homeGreetingAfternoon => 'Buenas tardes';

  @override
  String get homeGreetingEvening => 'Buenas noches';

  @override
  String get homeListenNow => 'Escuchar ahora';

  @override
  String get homeRecommendedForYou => 'Recomendado para ti';

  @override
  String get homeTrendingNow => 'Tendencias ahora';

  @override
  String get homeRecentlyPlayed => 'Reproducido recientemente';

  @override
  String get homeQuickPicks => 'Selección rápida';

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get libraryFavorites => 'Favoritos';

  @override
  String get libraryDownloads => 'Descargas';

  @override
  String get libraryHistory => 'Historial';

  @override
  String get libraryNoFavorites => 'Aún no hay favoritos';

  @override
  String get libraryNoDownloads => 'Aún no hay descargas';

  @override
  String get libraryNoHistory => 'Aún no hay historial';

  @override
  String get libraryAddFavorites =>
      'Toca el icono de corazón para agregar a favoritos';

  @override
  String get libraryDownloadContent =>
      'Descarga contenido para escuchar sin conexión';

  @override
  String get libraryStartListening =>
      'Comienza a escuchar para ver tu historial';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsSignIn => 'Iniciar sesión';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsLanguages => 'Idiomas';

  @override
  String get settingsInterests => 'Intereses';

  @override
  String get settingsVoice => 'Preferencias de voz';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsDownloads => 'Descargas';

  @override
  String get settingsDownloadsWifiOnly => 'Descargar solo con Wi-Fi';

  @override
  String get settingsStorage => 'Almacenamiento';

  @override
  String get settingsClearCache => 'Borrar caché';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsTermsOfService => 'Términos de servicio';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get settingsFeedback => 'Enviar comentarios';

  @override
  String get settingsRateApp => 'Calificar la app';

  @override
  String get settingsShareApp => 'Compartir con amigos';

  @override
  String get playerNowPlaying => 'Reproduciendo ahora';

  @override
  String get playerUpNext => 'A continuación';

  @override
  String get playerPlaybackSpeed => 'Velocidad de reproducción';

  @override
  String get playerSleepTimer => 'Temporizador de sueño';

  @override
  String get playerSleepTimerOff => 'Apagado';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get playerAddToFavorites => 'Agregar a favoritos';

  @override
  String get playerRemoveFromFavorites => 'Quitar de favoritos';

  @override
  String get playerDownload => 'Descargar';

  @override
  String get playerShare => 'Compartir';

  @override
  String get interestsSubtitle => 'Elige los temas que quieres escuchar';

  @override
  String interestsSelected(int count) {
    return '$count seleccionados';
  }

  @override
  String get interestsSave => 'Guardar';

  @override
  String get languagesTitle => 'Idiomas';

  @override
  String get languagesSubtitle => 'Elige tus idiomas preferidos';

  @override
  String get languagesSave => 'Guardar';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Buscar contenido...';

  @override
  String get searchVoiceHint => 'Toca para buscar por voz';

  @override
  String get searchNoResults => 'No se encontraron resultados';

  @override
  String get searchTryDifferent => 'Prueba con palabras diferentes';

  @override
  String get authSignInTitle => 'Iniciar sesión';

  @override
  String get authSignInSubtitle =>
      'Inicia sesión para sincronizar tus preferencias';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authContinueWithApple => 'Continuar con Apple';

  @override
  String get authContinueAsGuest => 'Continuar como invitado';

  @override
  String get authSignOutConfirm =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get premiumTitle => 'Hazte Premium';

  @override
  String get premiumSubtitle => 'Desbloquea todas las funciones';

  @override
  String get premiumFeature1 => 'Escucha sin anuncios';

  @override
  String get premiumFeature2 => 'Descargas ilimitadas';

  @override
  String get premiumFeature3 => 'Voces premium';

  @override
  String premiumSubscribe(String price) {
    return 'Suscribirse por $price';
  }

  @override
  String get premiumRestore => 'Restaurar compras';

  @override
  String get errorGeneric => 'Algo salió mal';

  @override
  String get errorNetwork => 'Sin conexión a internet';

  @override
  String get errorRetry => 'Reintentar';

  @override
  String get errorLoadingContent => 'Error al cargar contenido';

  @override
  String get errorPlayback => 'Error de reproducción';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get notificationDailyTitle => 'Tu audio diario';

  @override
  String get notificationDailyBody => 'Tu contenido personalizado está listo';

  @override
  String adSkipIn(int seconds) {
    return 'Omitir en $seconds segundos';
  }

  @override
  String get adSkip => 'Omitir anuncio';

  @override
  String get adLabel => 'Anuncio';

  @override
  String get offlineTitle => 'Modo sin conexión';

  @override
  String get offlineMessage =>
      'Estás sin conexión. Solo el contenido descargado está disponible.';

  @override
  String get offlineDownloadAvailable => 'Descarga para escuchar sin conexión';

  @override
  String get feedbackTitle => 'Enviar comentarios';

  @override
  String get feedbackHint => 'Cuéntanos qué piensas...';

  @override
  String get feedbackSubmit => 'Enviar';

  @override
  String get feedbackThankYou => '¡Gracias por tus comentarios!';

  @override
  String get updateRequired => 'Actualización requerida';

  @override
  String get updateMessage =>
      'Nueva versión disponible. Por favor actualiza para continuar.';

  @override
  String get updateButton => 'Actualizar ahora';
}
