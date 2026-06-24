import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:global_radio/core/constants.dart';
import 'package:global_radio/features/onboarding/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    late GoRouter testRouter;

    setUp(() {
      testRouter = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
    });

    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
    }

    testWidgets('displays Global Radio title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Global Radio'), findsOneWidget);
    });

    testWidgets('shows language selection on first step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Choose your language'), findsOneWidget);
    });

    testWidgets('has continue button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Look for continue/next button
      final continueButton = find.byWidgetPredicate(
        (widget) => widget is FilledButton || widget is ElevatedButton,
      );
      expect(continueButton, findsAtLeast(1));
    });

    testWidgets('displays Hindi as default selected language', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Hindi should be pre-selected (check for Hindi native name)
      expect(find.textContaining('हिन्दी'), findsWidgets);
    });
  });

  group('OnboardingScreen Steps', () {
    testWidgets('has multiple onboarding steps', (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );
      await tester.pumpAndSettle();

      // Verify first step
      expect(find.text('Choose your language'), findsOneWidget);

      // PageView should exist for step navigation
      expect(find.byType(PageView), findsOneWidget);
    });
  });

  group('Language selection', () {
    test('AppLanguage has all expected tiers', () {
      expect(AppLanguage.tier1.length, 13);
      expect(AppLanguage.tier2.length, 9);
      expect(AppLanguage.tier3.length, 8);
    });

    test('AppLanguage.all contains 30 languages', () {
      expect(AppLanguage.all.length, 30);
    });

    test('Hindi is in tier 1', () {
      expect(AppLanguage.tier1.any((l) => l.code == 'hindi'), isTrue);
    });

    test('English is in tier 1', () {
      expect(AppLanguage.tier1.any((l) => l.code == 'english'), isTrue);
    });
  });

  group('Interest selection', () {
    test('Interest has expected categories', () {
      expect(Interest.all.isNotEmpty, isTrue);
    });

    test('Kids interest exists', () {
      expect(Interest.byId('kids'), isNotNull);
    });

    test('Moral interest exists', () {
      expect(Interest.byId('moral'), isNotNull);
    });

    test('Devotion interest exists', () {
      expect(Interest.byId('devotion'), isNotNull);
    });
  });

  group('Voice selection', () {
    test('VoicePreset has default free voice', () {
      expect(VoicePreset.freeDefaultId, isNotEmpty);
    });

    test('VoicePreset.all has voices', () {
      expect(VoicePreset.all.isNotEmpty, isTrue);
    });

    test('All voice presets have required fields', () {
      for (final voice in VoicePreset.all) {
        expect(voice.id, isNotEmpty);
        expect(voice.label, isNotEmpty);
      }
    });
  });
}
