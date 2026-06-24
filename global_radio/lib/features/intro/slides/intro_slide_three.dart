import 'package:flutter/material.dart';

import '../intro_splash_screen.dart';

/// Slide 3: Languages CTA
/// Shows staggered script samples in multiple languages with fade-in animation.
class IntroSlideThree extends StatefulWidget {
  const IntroSlideThree({super.key});

  @override
  State<IntroSlideThree> createState() => _IntroSlideThreeState();
}

class _IntroSlideThreeState extends State<IntroSlideThree>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnimations;

  // Language samples with script name and sample text
  static const _languages = [
    ('हिंदी', 'नमस्ते'),
    ('తెలుగు', 'నమస్కారం'),
    ('தமிழ்', 'வணக்கம்'),
    ('ਪੰਜਾਬੀ', 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ'),
    ('বাংলা', 'নমস্কার'),
    ('ગુજરાતી', 'નમસ્તે'),
    ('ಕನ್ನಡ', 'ನಮಸ್ಕಾರ'),
    ('मराठी', 'नमस्कार'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Create staggered fade animations for each language
    _fadeAnimations = List.generate(_languages.length, (i) {
      final start = i * 0.1;
      final end = start + 0.3;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start.clamp(0.0, 0.7), end.clamp(0.0, 1.0),
              curve: Curves.easeOut),
        ),
      );
    });

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
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

          // Language grid with staggered animations
          SizedBox(
            height: 300,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final (script, greeting) = _languages[index];
                return FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_fadeAnimations[index]),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: IntroColors.dotInactive,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: IntroColors.saffron.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              color: IntroColors.saffron,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            script,
                            style: TextStyle(
                              color: IntroColors.mutedGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Spacer(),

          // Language globe icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IntroColors.saffron.withOpacity(0.1),
              border: Border.all(
                color: IntroColors.saffron.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.language,
              size: 32,
              color: IntroColors.saffron,
            ),
          ),

          const SizedBox(height: 24),

          // Headline
          Text(
            '10+ Indian languages\nYour voice, your script',
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
            'Listen in Hindi, Telugu, Tamil, Kannada,\nBengali, Gujarati, Marathi & more.',
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
