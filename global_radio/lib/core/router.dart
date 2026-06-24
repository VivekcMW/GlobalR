import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';
import '../features/intro/intro_splash_screen.dart';
import '../features/library/library_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/parental/parental_controls_screen.dart';
import '../features/player/player_screen.dart';
import '../features/referral/referral_screen.dart';
import '../features/settings/feedback_screen.dart';
import '../features/settings/interests_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/today_screen.dart';
import '../shared/providers/providers.dart';
import '../shared/widgets/scaffold_with_nav.dart';

/// GoRouter with a persistent bottom-nav shell + a full-screen player route.
GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final introSeen = ref.read(localStoreProvider).introSeen;
      final onboarded = ref.read(profileProvider).onboardingComplete;
      final path = state.matchedLocation;

      // First-time users: show intro slides before anything else
      if (!introSeen && path != '/splash') return '/splash';

      // After intro: onboarding flow
      if (introSeen && !onboarded && path != '/onboarding') return '/onboarding';

      // Completed users shouldn't land on intro/onboarding
      if (introSeen && onboarded && (path == '/splash' || path == '/onboarding')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const IntroSplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/player',
        builder: (_, _) => const PlayerScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: '/interests',
        builder: (_, _) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, _) => const LegalScreen(docType: LegalDocType.privacy),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, _) => const LegalScreen(docType: LegalDocType.terms),
      ),
      GoRoute(
        path: '/feedback',
        builder: (_, _) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (_, _) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/parental',
        builder: (_, _) => const ParentalControlsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));
