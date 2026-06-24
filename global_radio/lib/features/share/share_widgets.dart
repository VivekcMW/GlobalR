import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/catalog_item.dart';
import 'share_provider.dart';
import 'share_service.dart';

/// Share button for the player screen.
class ShareButton extends ConsumerWidget {
  final CatalogItem? item;

  const ShareButton({super.key, this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareService = ref.read(shareServiceProvider);
    final referralCode = ref.watch(referralCodeProvider);

    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share',
      onPressed: item == null
          ? null
          : () => shareService.shareItem(item!, referralCode: referralCode),
    );
  }
}

/// Bottom sheet for sharing options.
class ShareSheet extends ConsumerWidget {
  final CatalogItem item;

  const ShareSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareService = ref.read(shareServiceProvider);
    final referralCode = ref.watch(referralCodeProvider);
    final link = shareService.generateItemLink(item.id, referralCode: referralCode);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share "${item.title}"',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Link preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share button
            FilledButton.icon(
              onPressed: () {
                shareService.shareItem(item, referralCode: referralCode);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, CatalogItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ShareSheet(item: item),
    );
  }
}

/// Referral screen showing user's code and stats.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareService = ref.read(shareServiceProvider);
    final referralCode = ref.watch(referralCodeProvider);
    final stats = ref.watch(referralStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Friends'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Hero section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.2),
                  scheme.tertiary.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Share the joy of listening!',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite friends and both of you get a free week of Premium!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Referral code
          Text(
            'Your referral code',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  referralCode,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Share buttons
          FilledButton.icon(
            onPressed: () => shareService.shareApp(referralCode: referralCode),
            icon: const Icon(Icons.share),
            label: const Text('Share with friends'),
          ),
          const SizedBox(height: 32),

          // Stats
          Text(
            'Your referrals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  label: 'Invited',
                  value: stats.totalReferrals.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle,
                  label: 'Joined',
                  value: stats.successfulReferrals.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.star,
                  label: 'Rewards',
                  value: stats.pendingRewards.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // How it works
          Text(
            'How it works',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _HowItWorksStep(
            step: '1',
            title: 'Share your code',
            description: 'Send your unique code to friends',
          ),
          _HowItWorksStep(
            step: '2',
            title: 'Friend joins',
            description: 'They download the app and enter your code',
          ),
          _HowItWorksStep(
            step: '3',
            title: 'Both get rewarded',
            description: 'You both receive a free week of Premium!',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _HowItWorksStep({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
