import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/core/constants.dart';

void main() {
  group('AppConfig', () {
    test('cdnBase has default value', () {
      expect(AppConfig.cdnBase, isNotEmpty);
      expect(AppConfig.cdnBase, startsWith('https://'));
    });

    test('catalogUrl is based on cdnBase', () {
      expect(AppConfig.catalogUrl, contains('catalog.json'));
    });

    test('supportEmail is valid email format', () {
      expect(AppConfig.supportEmail, contains('@'));
      expect(AppConfig.supportEmail, endsWith('.app'));
    });

    test('privacyEmail is valid email format', () {
      expect(AppConfig.privacyEmail, contains('@'));
      expect(AppConfig.privacyEmail, endsWith('.app'));
    });

    test('appStoreUrl is valid App Store URL', () {
      expect(AppConfig.appStoreUrl, contains('apps.apple.com'));
    });

    test('playStoreUrl is valid Play Store URL', () {
      expect(AppConfig.playStoreUrl, contains('play.google.com'));
    });

    test('privacyPolicyUrl is based on legalBaseUrl', () {
      expect(AppConfig.privacyPolicyUrl, contains('privacy'));
    });

    test('termsOfServiceUrl is based on legalBaseUrl', () {
      expect(AppConfig.termsOfServiceUrl, contains('terms'));
    });

    test('demoLanguageFor returns language if supported', () {
      expect(AppConfig.demoLanguageFor('english'), 'english');
      expect(AppConfig.demoLanguageFor('hindi'), 'hindi');
    });

    test('demoLanguageFor falls back for unsupported languages', () {
      expect(AppConfig.demoLanguageFor('marathi'), AppConfig.demoFallbackLanguage);
      expect(AppConfig.demoLanguageFor('unknown'), AppConfig.demoFallbackLanguage);
    });
  });

  group('AppLanguage', () {
    test('has correct number of languages', () {
      expect(AppLanguage.all.length, 30);
    });

    test('tier 1 languages are correct', () {
      final tier1 = AppLanguage.byTier(1);
      expect(tier1.length, 13);
      expect(tier1.any((l) => l.code == 'english'), isTrue);
      expect(tier1.any((l) => l.code == 'hindi'), isTrue);
      expect(tier1.any((l) => l.code == 'bengali'), isTrue);
    });

    test('tier 2 languages are correct', () {
      final tier2 = AppLanguage.byTier(2);
      expect(tier2.length, 9);
      expect(tier2.any((l) => l.code == 'kashmiri'), isTrue);
      expect(tier2.any((l) => l.code == 'sindhi'), isTrue);
    });

    test('tier 3 languages are correct', () {
      final tier3 = AppLanguage.byTier(3);
      expect(tier3.length, 8);
      expect(tier3.any((l) => l.code == 'arabic'), isTrue);
      expect(tier3.any((l) => l.code == 'japanese'), isTrue);
    });

    test('RTL languages are marked correctly', () {
      expect(AppLanguage.isRtl('urdu'), isTrue);
      expect(AppLanguage.isRtl('arabic'), isTrue);
      expect(AppLanguage.isRtl('sindhi'), isTrue);
      expect(AppLanguage.isRtl('kashmiri'), isTrue);
      expect(AppLanguage.isRtl('english'), isFalse);
      expect(AppLanguage.isRtl('hindi'), isFalse);
    });

    test('all languages have required fields', () {
      for (final lang in AppLanguage.all) {
        expect(lang.code, isNotEmpty);
        expect(lang.englishName, isNotEmpty);
        expect(lang.nativeName, isNotEmpty);
        expect(lang.tier, greaterThan(0));
        expect(lang.tier, lessThanOrEqualTo(3));
      }
    });

    test('language codes are unique', () {
      final codes = AppLanguage.all.map((l) => l.code).toSet();
      expect(codes.length, AppLanguage.all.length);
    });

    test('byCode returns correct language', () {
      final hindi = AppLanguage.byCode('hindi');
      expect(hindi, isNotNull);
      expect(hindi!.code, 'hindi');
      expect(hindi.englishName, 'Hindi');
    });

    test('byCode returns null for unknown code', () {
      expect(AppLanguage.byCode('unknown'), isNull);
    });

    test('nativeNameFor returns native name', () {
      expect(AppLanguage.nativeNameFor('hindi'), 'हिन्दी');
      expect(AppLanguage.nativeNameFor('english'), 'English');
    });

    test('nativeNameFor returns code for unknown language', () {
      expect(AppLanguage.nativeNameFor('unknown'), 'unknown');
    });
  });

  group('VoicePreset', () {
    test('has all expected presets', () {
      expect(VoicePreset.all.length, greaterThan(0));
    });

    test('all presets have required fields', () {
      for (final preset in VoicePreset.all) {
        expect(preset.id, isNotEmpty);
        expect(preset.label, isNotEmpty);
        expect(preset.description, isNotEmpty);
      }
    });

    test('preset IDs are unique', () {
      final ids = VoicePreset.all.map((p) => p.id).toSet();
      expect(ids.length, VoicePreset.all.length);
    });
  });
}
