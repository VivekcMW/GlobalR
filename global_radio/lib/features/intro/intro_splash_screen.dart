import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/providers.dart';
import 'slides/intro_slide_one.dart';
import 'slides/intro_slide_two.dart';
import 'slides/intro_slide_three.dart';

/// Brand color constants for intro screens.
class IntroColors {
  static const background = Color(0xFF14110E);
  static const offWhite = Color(0xFFEDE6DA);
  static const saffron = Color(0xFFE0A93B);
  static const mutedGrey = Color(0xFFA09890);
  static const dotInactive = Color(0xFF3A3530);
}

/// First-launch intro slides screen.
/// Shows 3 slides: Pain Point → Daily Hook → Languages CTA.
class IntroSplashScreen extends ConsumerStatefulWidget {
  const IntroSplashScreen({super.key});

  @override
  ConsumerState<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends ConsumerState<IntroSplashScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _completeIntro() async {
    await ref.read(localStoreProvider).markIntroSeen();
    if (mounted) {
      context.go('/onboarding');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeIntro();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IntroColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Page content
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: const [
                IntroSlideOne(),
                IntroSlideTwo(),
                IntroSlideThree(),
              ],
            ),

            // Skip button (top-right)
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _completeIntro,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: IntroColors.mutedGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Bottom controls: dots + next button
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? IntroColors.saffron
                              : IntroColors.dotInactive,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IntroColors.saffron,
                          foregroundColor: IntroColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == 2 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
