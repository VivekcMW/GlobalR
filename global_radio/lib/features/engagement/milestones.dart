/// Streak milestones: confetti celebration + share card at 3/7/30/100/365
/// days. Crossing detection is pure and unit-tested; the celebration sheet is
/// triggered via [pendingMilestoneProvider] from wherever playback completes.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics/analytics_events.dart';
import '../../shared/providers/providers.dart';

class Milestones {
  static const thresholds = [3, 7, 30, 100, 365];
  static const storeKey = 'milestone_last_celebrated';

  /// The highest threshold newly crossed when the streak moved from a state
  /// where [lastCelebrated] was the last celebrated milestone to
  /// [currentStreak] days. Returns null when there is nothing new to
  /// celebrate.
  static int? newlyCrossed(int lastCelebrated, int currentStreak) {
    int? crossed;
    for (final t in thresholds) {
      if (currentStreak >= t && t > lastCelebrated) crossed = t;
    }
    return crossed;
  }

  static String messageFor(int days) => switch (days) {
        3 => 'Three days in a row — a habit is forming!',
        7 => 'A full week of listening. Shandaar!',
        30 => 'One month straight. You are unstoppable!',
        100 => '100 days! You are in the top 1% of listeners.',
        _ => 'A whole year of daily listening. Legendary!',
      };
}

/// A milestone (in days) waiting to be celebrated, or null.
final pendingMilestoneProvider = StateProvider<int?>((ref) => null);

/// Shows the celebration sheet and marks the milestone as celebrated.
Future<void> showMilestoneCelebration(
    BuildContext context, WidgetRef ref, int days) async {
  final store = ref.read(localStoreProvider);
  await store.putSetting(Milestones.storeKey, days);
  unawaitedLog(ref, MilestoneReachedEvent(days: days));
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MilestoneSheet(days: days),
  );
}

void unawaitedLog(WidgetRef ref, AnalyticsEvent event) {
  // Analytics must never block or crash the celebration.
  // ignore: discarded_futures
  ref.read(analyticsServiceProvider).logEvent(event).catchError((_) {});
}

class _MilestoneSheet extends ConsumerWidget {
  const _MilestoneSheet({required this.days});
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: ConfettiBurst()),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('🏆', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                '$days-day streak!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Milestones.messageFor(days),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Keep listening'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        unawaitedLog(ref,
                            MilestoneReachedEvent(days: days, shared: true));
                        SharePlus.instance.share(ShareParams(
                          text:
                              '🔥 $days-day listening streak on Global Radio! '
                              'Stories, news and bhajans in my language — '
                              'https://globalradio.app',
                        ));
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lightweight confetti animation — no external package needed.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _ConfettiPainter(_controller.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  static final _rng = math.Random(42);
  static final _pieces = List.generate(40, (i) {
    return (
      x: _rng.nextDouble(),
      speed: 0.5 + _rng.nextDouble(),
      size: 4.0 + _rng.nextDouble() * 5,
      color: [
        Colors.orange,
        Colors.pink,
        Colors.teal,
        Colors.amber,
        Colors.indigo,
      ][i % 5],
      spin: _rng.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final paint = Paint();
    for (final p in _pieces) {
      final y = size.height * (t * p.speed * 1.4 - 0.2);
      if (y < 0 || y > size.height) continue;
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.x * size.width, y);
      canvas.rotate(p.spin + t * math.pi * 4);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
