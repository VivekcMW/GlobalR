import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/locale_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../../shared/widgets/interest_picker.dart';
import '../../shared/widgets/voice_preview_button.dart';
import '../auth/auth_methods.dart';
import '../auth/profile_setup_sheet.dart';

/// 5-step onboarding: app language → content languages → interests → voice → account.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _step = 0;

  // Step 0: App language (single selection for UI)
  String _appLang = AppLanguage.english.code;
  // Step 1: Content languages (multiple selection for audio)
  final Set<String> _langs = {AppLanguage.hindi.code};
  final Set<String> _interests = {Interest.kids.id, Interest.moral.id};
  String _voice = VoicePreset.freeDefaultId;

  static const _lastStep = 4; // app lang, content langs, interests, voice, account

  bool get _canContinue {
    if (_step == 0) return _appLang.isNotEmpty;
    if (_step == 1) return _langs.isNotEmpty;
    if (_step == 2) return _interests.isNotEmpty;
    return true;
  }

  Future<void> _next() async {
    // When leaving Step 0 (app language), set the locale immediately
    if (_step == 0) {
      ref.read(appLocaleNotifierProvider.notifier).setLocale(_appLang);
    }
    
    if (_step < _lastStep) {
      setState(() => _step++);
      _page.animateToPage(_step,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  /// Persist prefs, start the radio, and land on Home. Used by both "Skip for
  /// now" and a successful sign-in.
  Future<void> _finish() async {
    // Stop any voice preview before the radio takes over playback.
    await ref.read(voicePreviewPlayerProvider).stop();
    final profile = ref.read(profileProvider.notifier);
    await profile.setAppLocale(_appLang);
    await profile.setLanguages(_langs.toList());
    await profile.setInterests(_interests.toList());
    await profile.setVoice(_voice);
    await profile.completeOnboarding();
    if (!mounted) return;
    // Build the radio queue, then land on Home with the mini-player live.
    await ref.read(radioControllerProvider.notifier).startRadio();
    if (!mounted) return;
    context.go('/home');
  }

  /// After sign-in, capture name + avatar (prefilled from the provider) then
  /// finish onboarding.
  Future<void> _finishAfterSignIn() async {
    if (!mounted) return;
    await showProfileSetupSheet(context, ref);
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.appLanguageTitle,      // 'Select app language'
      l10n.contentLanguagesTitle, // 'Choose content languages'
      l10n.interestsTitle,        // 'Pick your interests'
      l10n.voiceTitle,            // 'Pick a voice'
      l10n.accountTitle,          // 'Make it yours'
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Global Radio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Text(titles[_step],
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              // Show subtitle for first two steps
              if (_step == 0)
                Text(l10n.appLanguageSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              if (_step == 1)
                Text(l10n.contentLanguagesSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _AppLanguageStep(
                      selected: _appLang,
                      onChanged: (v) => setState(() => _appLang = v),
                    ),
                    _ContentLanguageStep(selected: _langs, onChanged: () => setState(() {})),
                    InterestPicker(selected: _interests, onChanged: () => setState(() {})),
                    _VoiceStep(
                      selected: _voice,
                      onChanged: (v) => setState(() => _voice = v),
                    ),
                    _AccountStep(onSignedIn: _finishAfterSignIn),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  titles.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _step
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _step < _lastStep
                    ? FilledButton(
                        onPressed: _canContinue ? _next : null,
                        child: Text(l10n.continueButton),
                      )
                    : OutlinedButton(
                        onPressed: _finish,
                        child: Text(l10n.skipForNow),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 0: Single-select app UI language.
class _AppLanguageStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _AppLanguageStep({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AppLanguage.all.map((l) {
          final isSelected = selected == l.code;
          return ChoiceChip(
            label: Text('${l.nativeName}  ·  ${l.englishName}'),
            selected: isSelected,
            onSelected: (_) => onChanged(l.code),
          );
        }).toList(),
      ),
    );
  }
}

/// Step 1: Multi-select content languages for audio.
class _ContentLanguageStep extends StatelessWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _ContentLanguageStep({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AppLanguage.all.map((l) {
          final on = selected.contains(l.code);
          return FilterChip(
            label: Text('${l.nativeName}  ·  ${l.englishName}'),
            selected: on,
            onSelected: (_) {
              on ? selected.remove(l.code) : selected.add(l.code);
              onChanged();
            },
          );
        }).toList(),
      ),
    );
  }
}

class _VoiceStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _VoiceStep({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      child: ListView(
        children: VoicePreset.all.map((v) {
          return Card(
            child: RadioListTile<String>(
              value: v.id,
              enabled: !v.premium,
              secondary: VoicePreviewButton(voiceId: v.id),
              title: Row(
                children: [
                  Flexible(child: Text(v.label)),
                  if (v.premium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(v.description),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Optional final step: create an account (or skip). Sign-in is value-add, not
/// required — the bottom "Skip for now" button proceeds without it.
class _AccountStep extends StatelessWidget {
  final VoidCallback onSignedIn;
  const _AccountStep({required this.onSignedIn});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Save your favorites and sync across devices.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text('Optional — you can skip and do this later in Settings.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          AuthMethods(onSignedIn: onSignedIn),
        ],
      ),
    );
  }
}
