import 'package:just_audio/just_audio.dart';

import '../core/constants.dart';

/// Plays a short bundled sample of a voice so users can hear it before
/// selecting it (onboarding step 3 + Settings → Voice).
///
/// Uses its own [AudioPlayer] — independent of the radio handler — so previews
/// never disturb (or get disturbed by) the main playback queue.
class VoicePreviewPlayer {
  final _player = AudioPlayer();

  /// The voice id currently being previewed, or null when idle/stopped.
  String? get nowPlaying =>
      _player.playing ? _currentVoiceId : null;
  String? _currentVoiceId;

  /// Emits the playing voice id (or null) so the UI can show which row is live.
  Stream<String?> get nowPlayingStream =>
      _player.playerStateStream.map((s) =>
          s.playing && s.processingState != ProcessingState.completed
              ? _currentVoiceId
              : null);

  /// Play the bundled sample for [voiceId] in [language] (falling back to the
  /// default demo language) from the start. Replaces any preview playing.
  Future<void> preview(
    String voiceId, {
    String language = AppConfig.demoFallbackLanguage,
  }) async {
    _currentVoiceId = voiceId;
    final lang = AppConfig.demoLanguageFor(language);
    await _player.setAsset('${AppConfig.demoAudioDir}/$lang/$voiceId.mp3');
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> stop() async {
    _currentVoiceId = null;
    await _player.stop();
  }

  Future<void> dispose() => _player.dispose();
}
