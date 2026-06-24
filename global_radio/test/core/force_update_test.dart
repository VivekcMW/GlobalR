import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/core/config/force_update_checker.dart';

void main() {
  group('ForceUpdateChecker', () {
    group('compareVersions', () {
      test('returns equal for same versions', () {
        expect(
          ForceUpdateChecker.compareVersions('1.0.0', '1.0.0'),
          equals(VersionCompareResult.equal),
        );
        expect(
          ForceUpdateChecker.compareVersions('2.5.3', '2.5.3'),
          equals(VersionCompareResult.equal),
        );
      });

      test('returns older when current is lower', () {
        expect(
          ForceUpdateChecker.compareVersions('1.0.0', '1.0.1'),
          equals(VersionCompareResult.older),
        );
        expect(
          ForceUpdateChecker.compareVersions('1.0.0', '2.0.0'),
          equals(VersionCompareResult.older),
        );
        expect(
          ForceUpdateChecker.compareVersions('1.5.0', '1.6.0'),
          equals(VersionCompareResult.older),
        );
      });

      test('returns newer when current is higher', () {
        expect(
          ForceUpdateChecker.compareVersions('2.0.0', '1.0.0'),
          equals(VersionCompareResult.newer),
        );
        expect(
          ForceUpdateChecker.compareVersions('1.1.0', '1.0.0'),
          equals(VersionCompareResult.newer),
        );
        expect(
          ForceUpdateChecker.compareVersions('1.0.1', '1.0.0'),
          equals(VersionCompareResult.newer),
        );
      });

      test('handles versions with different segment counts', () {
        expect(
          ForceUpdateChecker.compareVersions('1.0', '1.0.0'),
          equals(VersionCompareResult.equal),
        );
        expect(
          ForceUpdateChecker.compareVersions('2', '1.9.9'),
          equals(VersionCompareResult.newer),
        );
      });
    });
  });
}
