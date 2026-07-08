import 'dart:math' as math;

import 'package:flutter/material.dart';

/// "Diya Disc" — the app's signature player artwork.
///
/// A slowly rotating procedural rangoli ring (pattern seeded by the content
/// interest) around a diya flame that breathes on a calm 4-second cycle.
/// Zero image assets; scales to any size; honours reduced-motion settings.
class DiyaDisc extends StatefulWidget {
  final Color ringHue;
  final bool isPlaying;
  final double size;

  /// Seeds the rangoli motif so each category gets its own pattern.
  final String motifSeed;

  const DiyaDisc({
    super.key,
    required this.ringHue,
    required this.isPlaying,
    required this.motifSeed,
    this.size = 240,
  });

  @override
  State<DiyaDisc> createState() => _DiyaDiscState();
}

class _DiyaDiscState extends State<DiyaDisc> with TickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  );
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant DiyaDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _syncAnimations();
  }

  void _syncAnimations() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.isPlaying && !reduceMotion) {
      _rotation.repeat();
      _breath.repeat(reverse: true);
    } else {
      _rotation.stop();
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: widget.isPlaying ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotation, _breath]),
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: _DiyaDiscPainter(
              ringHue: widget.ringHue,
              accent: scheme.primary,
              background: scheme.surface,
              rotationT: _rotation.value,
              breathT: Curves.easeInOut.transform(_breath.value),
              seed: widget.motifSeed.hashCode,
              glowing: widget.isPlaying,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiyaDiscPainter extends CustomPainter {
  final Color ringHue;
  final Color accent;
  final Color background;
  final double rotationT; // 0..1 full turn
  final double breathT; // 0..1 breathing cycle
  final int seed;
  final bool glowing;

  _DiyaDiscPainter({
    required this.ringHue,
    required this.accent,
    required this.background,
    required this.rotationT,
    required this.breathT,
    required this.seed,
    required this.glowing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final angle = rotationT * 2 * math.pi;

    // Soft outer glow while playing.
    if (glowing) {
      canvas.drawCircle(
        center,
        radius * (0.88 + 0.04 * breathT),
        Paint()
          ..color = accent.withValues(alpha: 0.18 + 0.12 * breathT)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
      );
    }

    // Disc base.
    canvas.drawCircle(
      center,
      radius * 0.86,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ringHue.withValues(alpha: 0.22),
            background.withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.86)),
    );

    // --- Rangoli rings (rotate together) --------------------------------
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final petals = 8 + seed.abs() % 5; // 8..12, per-category motif
    final petalPaint = Paint()
      ..color = ringHue.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.02
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = ringHue.withValues(alpha: 0.7);

    // Outer petal arcs.
    for (var i = 0; i < petals; i++) {
      final a = i * 2 * math.pi / petals;
      final petalCenter =
          Offset(math.cos(a), math.sin(a)) * (radius * 0.74);
      final petalRect =
          Rect.fromCircle(center: petalCenter, radius: radius * 0.12);
      canvas.drawArc(petalRect, a + math.pi * 0.15, math.pi * 1.7, false,
          petalPaint);
    }

    // Dot ring between petals.
    for (var i = 0; i < petals; i++) {
      final a = (i + 0.5) * 2 * math.pi / petals;
      canvas.drawCircle(
        Offset(math.cos(a), math.sin(a)) * (radius * 0.58),
        radius * 0.022,
        dotPaint,
      );
    }

    // Inner kolam diamond ring, counter-phase.
    final innerPaint = Paint()
      ..color = ringHue.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.014;
    final innerCount = petals * 2;
    final innerPath = Path();
    for (var i = 0; i <= innerCount; i++) {
      final a = i * 2 * math.pi / innerCount;
      final r = radius * (i.isEven ? 0.44 : 0.36);
      final p = Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? innerPath.moveTo(p.dx, p.dy) : innerPath.lineTo(p.dx, p.dy);
    }
    innerPath.close();
    canvas.drawPath(innerPath, innerPaint);

    canvas.restore();

    // --- Diya flame (breathes, does not rotate) --------------------------
    final flameHeight = radius * (0.30 + 0.05 * breathT);
    final flameWidth = flameHeight * 0.62;
    final flameBase = center + Offset(0, flameHeight * 0.55);

    Path flame(double scale) {
      final h = flameHeight * scale;
      final w = flameWidth * scale;
      return Path()
        ..moveTo(flameBase.dx, flameBase.dy - h) // tip
        ..cubicTo(
          flameBase.dx + w * 0.9, flameBase.dy - h * 0.45,
          flameBase.dx + w * 0.7, flameBase.dy - h * 0.05,
          flameBase.dx, flameBase.dy,
        )
        ..cubicTo(
          flameBase.dx - w * 0.7, flameBase.dy - h * 0.05,
          flameBase.dx - w * 0.9, flameBase.dy - h * 0.45,
          flameBase.dx, flameBase.dy - h,
        )
        ..close();
    }

    // Flame glow halo.
    canvas.drawCircle(
      center,
      radius * (0.20 + 0.04 * breathT),
      Paint()
        ..color = accent.withValues(alpha: 0.30 + 0.20 * breathT)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Outer flame in accent, inner flame warm-white.
    canvas.drawPath(flame(1.0), Paint()..color = accent);
    canvas.drawPath(
      flame(0.55),
      Paint()..color = const Color(0xFFFFF3D6).withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(_DiyaDiscPainter old) =>
      old.rotationT != rotationT ||
      old.breathT != breathT ||
      old.ringHue != ringHue ||
      old.accent != accent ||
      old.glowing != glowing ||
      old.seed != seed;
}
