import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../intro_splash_screen.dart';

/// Slide 2: Content Categories Carousel
/// Shows animated icons rotating in a circle representing different content types.
class IntroSlideTwo extends StatefulWidget {
  const IntroSlideTwo({super.key});

  @override
  State<IntroSlideTwo> createState() => _IntroSlideTwoState();
}

class _IntroSlideTwoState extends State<IntroSlideTwo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Content categories with icons and labels
  static const _categories = [
    (Icons.newspaper_rounded, 'News'),
    (Icons.music_note_rounded, 'Music'),
    (Icons.auto_stories_rounded, 'Stories'),
    (Icons.temple_hindu_rounded, 'Devotion'),
    (Icons.child_care_rounded, 'Kids'),
    (Icons.star_rounded, 'Horoscope'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
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

          // Rotating content carousel
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring (static)
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: IntroColors.dotInactive,
                      width: 1,
                    ),
                  ),
                ),

                // Inner ring (static)
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: IntroColors.dotInactive.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),

                // Center glow
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        IntroColors.saffron.withOpacity(0.3),
                        IntroColors.saffron.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Center icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: IntroColors.saffron,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: IntroColors.saffron.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 36,
                    color: IntroColors.background,
                  ),
                ),

                // Rotating category icons
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: List.generate(_categories.length, (index) {
                        final baseAngle = (index * 2 * math.pi / _categories.length);
                        final currentAngle = baseAngle + (_controller.value * 2 * math.pi);
                        final radius = 115.0;
                        
                        final x = math.cos(currentAngle - math.pi / 2) * radius;
                        final y = math.sin(currentAngle - math.pi / 2) * radius;
                        
                        // Calculate opacity based on position (brighter at top)
                        final normalizedY = (y + radius) / (2 * radius);
                        final opacity = 0.5 + (1 - normalizedY) * 0.5;
                        final scale = 0.8 + (1 - normalizedY) * 0.3;
                        
                        return Transform.translate(
                          offset: Offset(x, y),
                          child: Transform.scale(
                            scale: scale,
                            child: _CategoryIcon(
                              icon: _categories[index].$1,
                              label: _categories[index].$2,
                              opacity: opacity,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Category pills preview
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: IntroColors.dotInactive,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.$1,
                      size: 14,
                      color: IntroColors.saffron,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.$2,
                      style: TextStyle(
                        color: IntroColors.offWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const Spacer(),

          // Headline
          Text(
            'Fresh content,\nevery day',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IntroColors.offWhite,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Subtext
          Text(
            'Curated just for you —\nmorning to night',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IntroColors.mutedGrey,
              fontSize: 16,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Individual category icon with glow effect.
class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final double opacity;

  const _CategoryIcon({
    required this.icon,
    required this.label,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: IntroColors.dotInactive,
          shape: BoxShape.circle,
          border: Border.all(
            color: IntroColors.saffron.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: IntroColors.saffron.withOpacity(0.2 * opacity),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 26,
          color: IntroColors.saffron,
        ),
      ),
    );
  }
}
