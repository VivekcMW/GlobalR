import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../shared/providers/providers.dart';

/// Progress of an offline pack download.
class OfflinePackState {
  final bool downloading;
  final int done;
  final int failed;
  final int total;

  const OfflinePackState({
    this.downloading = false,
    this.done = 0,
    this.failed = 0,
    this.total = 0,
  });

  double get progress => total == 0 ? 0 : (done + failed) / total;
}

/// Downloads the next N items of the user's station into the same cache
/// the player reads from ([DefaultCacheManager]), so cached items play
/// instantly and fully offline.
class OfflinePackController extends Notifier<OfflinePackState> {
  static const packSize = 10;

  @override
  OfflinePackState build() => const OfflinePackState();

  Future<void> downloadMyStation() async {
    if (state.downloading) return;
    final catalog = ref.read(catalogProvider).value;
    if (catalog == null) return;
    final profile = ref.read(profileProvider);
    final engine = ref.read(radioEngineProvider);
    final signals = ref.read(localStoreProvider).loadAllSignals();

    final items = engine
        .buildRadio(profile, catalog, signals, now: DateTime.now())
        .take(packSize)
        .toList();
    if (items.isEmpty) return;

    state = OfflinePackState(downloading: true, total: items.length);
    final cache = DefaultCacheManager();
    for (final item in items) {
      final url = item.audioUrlFor(profile.preferredVoice);
      try {
        await cache.downloadFile(url, force: false);
        state = OfflinePackState(
            downloading: true,
            done: state.done + 1,
            failed: state.failed,
            total: state.total);
      } catch (_) {
        state = OfflinePackState(
            downloading: true,
            done: state.done,
            failed: state.failed + 1,
            total: state.total);
      }
    }
    state = OfflinePackState(
        downloading: false,
        done: state.done,
        failed: state.failed,
        total: state.total);
  }
}

final offlinePackProvider =
    NotifierProvider<OfflinePackController, OfflinePackState>(
        OfflinePackController.new);

/// Library card: download the station for offline listening (Premium).
class OfflinePackCard extends ConsumerWidget {
  const OfflinePackCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pack = ref.watch(offlinePackProvider);
    final isPremium = ref.watch(profileProvider).isPremium;
    final scheme = Theme.of(context).colorScheme;

    final String subtitle;
    if (AppConfig.demoAudio) {
      subtitle = 'Demo content is already bundled offline';
    } else if (pack.downloading) {
      subtitle =
          'Downloading ${pack.done + pack.failed + 1} of ${pack.total}…';
    } else if (pack.total > 0) {
      subtitle = pack.failed == 0
          ? '${pack.done} items ready for offline listening'
          : '${pack.done} downloaded, ${pack.failed} failed';
    } else {
      subtitle = isPremium
          ? 'Save the next ${OfflinePackController.packSize} items of your station'
          : 'Premium: listen anywhere, no data needed';
    }

    return Card(
      child: ListTile(
        leading: pack.downloading
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    value: pack.progress, strokeWidth: 3),
              )
            : Icon(
                isPremium
                    ? Icons.download_for_offline_outlined
                    : Icons.workspace_premium_outlined,
                color: scheme.primary,
                size: 28,
              ),
        title: const Text('Offline pack'),
        subtitle: Text(subtitle),
        trailing: AppConfig.demoAudio || pack.downloading
            ? null
            : const Icon(Icons.chevron_right),
        onTap: AppConfig.demoAudio || pack.downloading
            ? null
            : () {
                if (!isPremium) {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Premium feature'),
                      content: const Text(
                          'Offline packs let you download your station and '
                          'listen without any internet. Upgrade to Premium '
                          'in Settings to unlock.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Not now'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                ref.read(offlinePackProvider.notifier).downloadMyStation();
              },
      ),
    );
  }
}
