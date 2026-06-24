/// Force update checker for enforcing minimum app version.
///
/// Compares the current app version against the minimum required version
/// from remote config and shows a blocking update dialog if needed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'remote_config_service.dart';

/// Version comparison result.
enum VersionCompareResult {
  equal,
  newer,
  older,
}

/// Force update checker.
class ForceUpdateChecker {
  final RemoteConfigService remoteConfig;

  ForceUpdateChecker(this.remoteConfig);

  /// Check if an update is required.
  Future<bool> isUpdateRequired() async {
    if (!remoteConfig.config.forceUpdateEnabled) {
      return false;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final minVersion = remoteConfig.config.minAppVersion;

    return compareVersions(currentVersion, minVersion) == VersionCompareResult.older;
  }

  /// Compare two version strings (e.g., "1.2.3" vs "1.2.4").
  static VersionCompareResult compareVersions(String current, String required) {
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final requiredParts = required.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad to same length
    while (currentParts.length < 3) currentParts.add(0);
    while (requiredParts.length < 3) requiredParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (currentParts[i] < requiredParts[i]) {
        return VersionCompareResult.older;
      } else if (currentParts[i] > requiredParts[i]) {
        return VersionCompareResult.newer;
      }
    }

    return VersionCompareResult.equal;
  }

  /// Get the current app version.
  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }
}

/// Force update dialog that blocks app usage.
class ForceUpdateDialog extends StatelessWidget {
  final VoidCallback onUpdate;

  const ForceUpdateDialog({
    super.key,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from dismissing
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.orange),
            SizedBox(width: 12),
            Text('Update Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of Global Radio is available.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Please update to continue using the app.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: onUpdate,
            icon: const Icon(Icons.download),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Show the force update dialog.
  static Future<void> show(BuildContext context, {required VoidCallback onUpdate}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ForceUpdateDialog(onUpdate: onUpdate),
    );
  }
}

/// Maintenance mode dialog.
class MaintenanceDialog extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const MaintenanceDialog({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.build, color: Colors.orange),
          SizedBox(width: 12),
          Text('Maintenance'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  /// Show the maintenance dialog.
  static Future<void> show(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MaintenanceDialog(message: message, onRetry: onRetry),
    );
  }
}

/// Force update checker provider.
final forceUpdateCheckerProvider = Provider<ForceUpdateChecker>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return ForceUpdateChecker(remoteConfig);
});

/// Current app version provider.
final appVersionProvider = FutureProvider<String>((ref) async {
  final checker = ref.watch(forceUpdateCheckerProvider);
  return checker.getCurrentVersion();
});

/// Update required status provider.
final updateRequiredProvider = FutureProvider<bool>((ref) async {
  final checker = ref.watch(forceUpdateCheckerProvider);
  return checker.isUpdateRequired();
});
