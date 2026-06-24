import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/providers.dart';
import 'auth_methods.dart';
import 'profile_setup_sheet.dart';

/// Full-screen sign-in (route `/signin`). After auth, prompts for name + avatar
/// if not already set, then returns to wherever the user came from.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> finish() async {
      final p = ref.read(profileProvider);
      if (p.name == null || p.name!.isEmpty) {
        await showProfileSetupSheet(context, ref);
      }
      if (context.mounted) {
        context.canPop() ? context.pop() : context.go('/home');
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create account or sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Save your favorites & sync across devices',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Quick and secure — choose any one.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),
              AuthMethods(onSignedIn: finish),
            ],
          ),
        ),
      ),
    );
  }
}
