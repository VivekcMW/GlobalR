import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../data/services/legal_service.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/voice_preview_button.dart';
import '../auth/profile_setup_sheet.dart';

/// Settings: "You" tab with profile header and organized settings sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final p = ref.read(profileProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible profile header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.15),
                      scheme.tertiary.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                    child: _ProfileHeader(
                      name: profile.name,
                      avatar: profile.avatar,
                      isSignedIn: profile.isSignedIn,
                      isPremium: profile.isPremium,
                      signInProvider: profile.signInProvider,
                      onEdit: () => showProfileSetupSheet(context, ref),
                    ),
                  ),
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Quick Actions Row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.workspace_premium,
                        label: profile.isPremium ? 'Premium' : 'Go Premium',
                        color: profile.isPremium ? Colors.amber : scheme.primary,
                        onTap: profile.isPremium ? null : () => _showUpsell(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: profile.isSignedIn ? Icons.sync : Icons.cloud_upload,
                        label: profile.isSignedIn ? 'Synced' : 'Sign in',
                        color: profile.isSignedIn ? Colors.green : scheme.secondary,
                        onTap: profile.isSignedIn ? null : () => context.push('/signin'),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              _section(context, 'Content'),
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('Languages'),
                subtitle: Text(profile.languages
                    .map(AppLanguage.nativeNameFor)
                    .join(', ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editLanguages(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.interests),
                title: const Text('Interests'),
                subtitle: Text(profile.interests.map(Interest.labelFor).join(', ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/interests'),
              ),

              // Playback Section
              _section(context, 'Playback'),
              ListTile(
                leading: const Icon(Icons.record_voice_over),
                title: const Text('Voice'),
                subtitle: Text(VoicePreset.byId(profile.preferredVoice)?.label ??
                    profile.preferredVoice),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editVoice(context, ref),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.data_saver_on),
                title: const Text('Low-data mode'),
                subtitle: const Text('48 kbps audio, prefetch next item only'),
                value: profile.lowDataMode,
                onChanged: p.setLowDataMode,
              ),

              // App Section
              _section(context, 'App'),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('App Language'),
                subtitle: Text(profile.appLocale != null
                    ? AppLanguage.nativeNameFor(profile.appLocale!)
                    : 'English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editAppLanguage(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                subtitle: const Text('Daily astrology, festivals'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/notifications'),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share Global Radio'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Share.share(
                    'Check out Global Radio - personalized audio content for your interests! '
                    'Download now: ${AppConfig.appStoreUrl}',
                    subject: 'Global Radio App',
                  );
                },
              ),

              // Account Section
              _section(context, 'Account'),
              if (profile.isSignedIn) ...[
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () => ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                subtitle: const Text('We store profile + preferences + favorites only'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => ref.read(legalServiceProvider).openPrivacyPolicy(),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of service'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => ref.read(legalServiceProvider).openTermsOfService(),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text('Delete account & data',
                    style: TextStyle(color: scheme.error)),
                onTap: () => _confirmDelete(context, ref),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'v${AppConfig.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary)),
      );

  void _editLanguages(BuildContext context, WidgetRef ref) {
    final selected = ref.read(profileProvider).languages.toSet();
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Languages', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...AppLanguage.all.map((l) => CheckboxListTile(
                  title: Text('${l.nativeName} · ${l.englishName}'),
                  value: selected.contains(l.code),
                  onChanged: (on) {
                    setState(() => on == true
                        ? selected.add(l.code)
                        : selected.remove(l.code));
                  },
                )),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (selected.isNotEmpty) {
                  ref.read(profileProvider.notifier).setLanguages(selected.toList());
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editVoice(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileProvider);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => RadioGroup<String>(
        groupValue: profile.preferredVoice,
        onChanged: (val) {
          if (val == null) return;
          ref.read(profileProvider.notifier).setVoice(val);
          Navigator.pop(sheetContext);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Voice', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Tap ▶ to preview a voice before choosing.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ...VoicePreset.all.map((v) {
              final locked = v.premium && !profile.isPremium;
              return RadioListTile<String>(
                value: v.id,
                enabled: !locked,
                secondary: VoicePreviewButton(voiceId: v.id),
                title: Text(locked ? '${v.label} (Premium)' : v.label),
                subtitle: Text(v.description),
              );
            }),
          ],
        ),
      ),
    ).whenComplete(() => ref.read(voicePreviewPlayerProvider).stop());
  }

  void _editAppLanguage(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileProvider);
    final selected = profile.appLocale ?? 'english';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => RadioGroup<String>(
          groupValue: selected,
          onChanged: (val) {
            if (val == null) return;
            ref.read(profileProvider.notifier).setAppLocale(val);
            Navigator.pop(ctx);
          },
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text('App Language', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('The app interface will display in this language.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              ...AppLanguage.all.map((l) => RadioListTile<String>(
                    value: l.code,
                    title: Text('${l.nativeName} · ${l.englishName}'),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account & data?'),
        content: const Text(
            'This permanently removes your profile, preferences, and favorites '
            'from this device. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              // Data is wiped (onboarding reset) — start fresh.
              if (context.mounted) context.go('/onboarding');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUpsell(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Go Premium', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${AppConfig.premiumYearlyPrice}\n\nAll voices · No ads · Offline favorites · Family'),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.shop),
              onPressed: () async {
                final ok = await ref.read(paymentServiceProvider).purchaseInApp();
                if (ok) {
                  await ref.read(profileProvider.notifier).setPremium(true);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              label: const Text('Buy in-app (Apple / Google)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                ref.read(paymentServiceProvider).openWebCheckout();
                Navigator.pop(ctx);
              },
              label: const Text('Pay on web (UPI — best price)'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile header with avatar, name, and sign-in status.
class _ProfileHeader extends StatelessWidget {
  final String? name;
  final String? avatar;
  final bool isSignedIn;
  final bool isPremium;
  final String? signInProvider;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.avatar,
    required this.isSignedIn,
    required this.isPremium,
    required this.signInProvider,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        GestureDetector(
          onTap: onEdit,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
              border: isPremium
                  ? Border.all(color: Colors.amber, width: 3)
                  : null,
            ),
            child: Center(
              child: Text(
                avatar ?? '🎧',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name?.isNotEmpty == true ? name! : 'Listener',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                isSignedIn
                    ? 'Signed in with ${_providerLabel(signInProvider)}'
                    : 'Tap to set name & avatar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              if (isPremium) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✨ Premium',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ],
    );
  }

  static String _providerLabel(String? provider) => switch (provider) {
        'google' => 'Google',
        'apple' => 'Apple',
        'phone' => 'phone',
        _ => 'this device',
      };
}

/// Quick action card for premium/sign-in.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = onTap == null;
    return Card(
      color: isActive ? color.withValues(alpha: 0.15) : scheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.check_circle : icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (!isActive)
                Icon(Icons.chevron_right, color: scheme.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
