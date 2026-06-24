import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../providers/providers.dart';

/// Play/stop button that auditions a voice sample before selection.
///
/// Shows a stop icon while *this* voice is the one previewing, so only one row
/// is ever active. Previews are allowed for premium-locked voices too (lets
/// users hear what they'd unlock).
class VoicePreviewButton extends ConsumerWidget {
  final String voiceId;
  const VoicePreviewButton({super.key, required this.voiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(voicePreviewPlayerProvider);
    // Preview in the user's primary language so they hear the voice as they'll
    // actually receive it (falls back to the default demo language).
    final language = ref.watch(profileProvider.select((p) =>
        p.languages.isNotEmpty
            ? p.languages.first
            : AppConfig.demoFallbackLanguage));
    return StreamBuilder<String?>(
      stream: preview.nowPlayingStream,
      builder: (context, snap) {
        final playing = snap.data == voiceId;
        return IconButton(
          tooltip: playing ? 'Stop preview' : 'Preview voice',
          color: Theme.of(context).colorScheme.primary,
          icon: Icon(playing
              ? Icons.stop_circle_outlined
              : Icons.play_circle_outline),
          onPressed: () => playing
              ? preview.stop()
              : preview.preview(voiceId, language: language),
        );
      },
    );
  }
}
