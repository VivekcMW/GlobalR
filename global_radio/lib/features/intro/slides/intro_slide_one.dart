import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../intro_splash_screen.dart';

/// Slide 1: Welcome & App Overview
/// Shows app logo with glow and animated radio waves visualization.
class IntroSlideOne extends StatefulWidget {
  const IntroSlideOne({super.key});

  @override
  State<IntroSlideOne> createState() => _IntroSlideOneState();
}

class _IntroSlideOneState extends State<IntroSlideOne>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _waveController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    
    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Radio wave animation (continuous)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Start logo animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _logoController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // App logo with glow and radio waves
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated radio waves
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(280, 280),
                      painter: _RadioWavesPainter(
                        progress: _waveController.value,
                      ),
                    );
                  },
                ),

                // Glow effect behind logo
                AnimatedBuilder(
                  animation: _logoOpacity,
                  builder: (context, child) {
                    return Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            IntroColors.saffron.withOpacity(0.4 * _logoOpacity.value),
                            IntroColors.saffron.withOpacity(0.15 * _logoOpacity.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // App Logo placeholder
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: IntroColors.saffron,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: IntroColors.saffron.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.radio,
                              size: 56,
                              color: IntroColors.background,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Spacer(),

          // Headline
          Text(
            'Your Personal Radio,\nYour Way',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IntroColors.offWhite,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Subtext - content categories
          Text(
            'News • Stories • Music • Devotion • Kids',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IntroColors.saffron,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ad-free audio curated just for you',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IntroColors.mutedGrey,
              fontSize: 15,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Custom painter for animated radio waves emanating from center.
class _RadioWavesPainter extends CustomPainter {
  final double progress;
  
  _RadioWavesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw multiple expanding circles
    for (var i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final radius = 60 + waveProgress * 80;
      final opacity = (1.0 - waveProgress) * 0.6;
      
      final paint = Paint()
        ..color = IntroColors.saffron.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(center, radius, paint);
    }
    
    // Draw static outer ring
    final outerPaint = Paint()
      ..color = IntroColors.dotInactive
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 130, outerPaint);
    
    // Draw sound wave arcs on sides
    _drawSoundArc(canvas, center, -1, progress);
    _drawSoundArc(canvas, center, 1, progress);
  }
  
  void _drawSoundArc(Canvas canvas, Offset center, int direction, double progress) {
    for (var i = 0; i < 3; i++) {
      final arcProgress = (progress + i * 0.25) % 1.0;
      final opacity = (1.0 - arcProgress) * 0.4;
      final radius = 70 + i * 20;
      
      final paint = Paint()
        ..color = IntroColors.saffron.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      
      final rect = Rect.fromCircle(center: center, radius: radius.toDouble());
      final startAngle = direction == 1 ? -math.pi / 4 : math.pi - math.pi / 4;
      canvas.drawArc(rect, startAngle, math.pi / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadioWavesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
