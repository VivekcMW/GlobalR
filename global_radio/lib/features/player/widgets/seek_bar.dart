import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../../audio/audio_handler.dart';
import '../../../shared/providers/display_settings_provider.dart';
import '../../../shared/utils/localized_digits.dart';

/// Position + buffered + duration snapshot for the seek bar.
class PositionData {
  final Duration position;
  final Duration buffered;
  final Duration duration;

  const PositionData(this.position, this.buffered, this.duration);
}

/// Draggable seek bar with buffered-progress track and time labels.
///
/// While the user drags, the thumb follows the finger (not the stream); the
/// actual seek fires once on release so scrubbing feels instant.
class SeekBar extends ConsumerStatefulWidget {
  final GlobalRadioAudioHandler audioHandler;

  const SeekBar({super.key, required this.audioHandler});

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  /// Non-null while the user is dragging the thumb.
  double? _dragValue;

  late final Stream<PositionData> _positionData;

  @override
  void initState() {
    super.initState();
    final h = widget.audioHandler;
    _positionData = Rx.combineLatest3<Duration, Duration, Duration?,
        PositionData>(
      h.positionStream,
      h.bufferedPositionStream,
      h.durationStream,
      (position, buffered, duration) =>
          PositionData(position, buffered, duration ?? Duration.zero),
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final text = '$minutes:$seconds';
    if (!ref.read(displaySettingsProvider).localizedNumerals) return text;
    return localizeDigits(text, Localizations.localeOf(context).languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<PositionData>(
      stream: _positionData,
      builder: (context, snapshot) {
        final data = snapshot.data ??
            const PositionData(Duration.zero, Duration.zero, Duration.zero);
        final totalMs = data.duration.inMilliseconds.toDouble();
        final hasDuration = totalMs > 0;
        final positionMs = _dragValue ??
            data.position.inMilliseconds.clamp(0, totalMs).toDouble();
        final bufferedMs =
            data.buffered.inMilliseconds.clamp(0, totalMs).toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: scheme.primary,
                secondaryActiveTrackColor:
                    scheme.primary.withValues(alpha: 0.25),
                inactiveTrackColor: scheme.surfaceContainerHighest,
              ),
              child: Slider(
                min: 0,
                max: hasDuration ? totalMs : 1,
                value: hasDuration ? positionMs : 0,
                secondaryTrackValue: hasDuration ? bufferedMs : 0,
                onChangeStart: hasDuration
                    ? (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _dragValue = v);
                      }
                    : null,
                onChanged: hasDuration
                    ? (v) => setState(() => _dragValue = v)
                    : null,
                onChangeEnd: hasDuration
                    ? (v) {
                        widget.audioHandler
                            .seek(Duration(milliseconds: v.round()));
                        setState(() => _dragValue = null);
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _format(Duration(milliseconds: positionMs.round())),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    hasDuration ? _format(data.duration) : '--:--',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
