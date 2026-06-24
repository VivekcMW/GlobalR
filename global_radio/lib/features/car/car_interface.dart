/// Car interface integration for Android Auto and Apple CarPlay.
///
/// This file provides the configuration and integration helpers
/// for car dashboard playback support.
///
/// ## Setup
///
/// ### Android Auto
/// 1. Add automotive_app_desc.xml (already created)
/// 2. Add to AndroidManifest.xml:
///    ```xml
///    <meta-data
///        android:name="com.google.android.gms.car.application"
///        android:resource="@xml/automotive_app_desc"/>
///    ```
/// 3. The MediaBrowserService extension on AudioHandler provides
///    browsable content automatically.
///
/// ### Apple CarPlay
/// 1. Add CarPlay entitlement to iOS app
/// 2. Configure Info.plist with CarPlay capabilities
/// 3. The audio_service plugin handles CarPlay media session
///
/// ## Browsable Content Structure
///
/// ROOT
/// ├── Good Morning India (playable daily mix)
/// ├── Recently Played
/// │   └── [Recent items...]
/// ├── Categories
/// │   ├── Devotional
/// │   ├── Kids Stories
/// │   ├── News
/// │   └── ...
/// ├── Languages
/// │   ├── Hindi
/// │   ├── Tamil
/// │   └── ...
/// ├── Favorites
/// │   └── [Liked items...]
/// └── Downloads
///     └── [Offline items...]
///

library car_interface;

export 'media_browser_service.dart';

/// Car interface configuration.
class CarInterfaceConfig {
  /// Maximum items to show in a browsable list (car UI limitation).
  static const int maxBrowsableItems = 50;

  /// Whether to show artwork in car interface.
  static const bool showArtwork = true;

  /// Default artwork for items without images.
  static const String defaultArtworkPath = 'assets/images/default_artwork.png';

  /// Voice command prefixes for hands-free control.
  static const List<String> voiceCommandPrefixes = [
    'play',
    'pause',
    'stop',
    'next',
    'previous',
    'skip',
  ];
}

/// Media session metadata for car displays.
class CarMediaMetadata {
  final String title;
  final String? artist;
  final String? album;
  final String? artworkUrl;
  final Duration? duration;
  final Duration? position;

  const CarMediaMetadata({
    required this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    this.duration,
    this.position,
  });

  /// Create metadata for car display from current item.
  factory CarMediaMetadata.fromCurrentItem({
    required String title,
    String? category,
    String? language,
    String? artworkUrl,
    Duration? duration,
    Duration? position,
  }) {
    // Format artist line for car display
    String? artistLine;
    if (category != null && language != null) {
      artistLine = '$category · $language';
    } else if (category != null) {
      artistLine = category;
    } else if (language != null) {
      artistLine = language;
    }

    return CarMediaMetadata(
      title: title,
      artist: artistLine,
      album: 'Global Radio',
      artworkUrl: artworkUrl,
      duration: duration,
      position: position,
    );
  }
}

/// Supported playback actions for car interface.
enum CarPlaybackAction {
  play,
  pause,
  stop,
  skipNext,
  skipPrevious,
  seekForward,
  seekBackward,
  fastForward,
  rewind,
}
