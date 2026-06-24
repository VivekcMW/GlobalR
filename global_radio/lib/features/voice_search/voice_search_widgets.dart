import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_search_provider.dart';

/// Floating voice search button for the home screen.
class VoiceSearchButton extends ConsumerWidget {
  const VoiceSearchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isVoiceSearchActiveProvider);

    return FloatingActionButton(
      onPressed: () => _showVoiceSearch(context),
      backgroundColor: isActive
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      child: Icon(
        Icons.mic,
        color: isActive
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showVoiceSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceSearchSheet(),
    );
  }
}

/// Full-screen voice search overlay.
class VoiceSearchSheet extends ConsumerStatefulWidget {
  const VoiceSearchSheet({super.key});

  @override
  ConsumerState<VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends ConsumerState<VoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(voiceSearchStateProvider);
    final scheme = Theme.of(context).colorScheme;

    // Auto-start listening when sheet opens
    if (!_autoStarted) {
      _autoStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(voiceSearchControllerProvider).startListening();
      });
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voice Search',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main content
            Expanded(
              child: stateAsync.when(
                data: (state) => _buildStateContent(state),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e', style: TextStyle(color: scheme.error)),
                ),
              ),
            ),

            // Language selector
            Padding(
              padding: const EdgeInsets.all(24),
              child: _LanguageSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent(VoiceSearchState state) {
    switch (state) {
      case VoiceSearchIdle():
        return _buildIdleState();
        
      case VoiceSearchListening(:final partialResult):
        return _buildListeningState(partialResult);
        
      case VoiceSearchProcessing(:final transcript):
        return _buildProcessingState(transcript);
        
      case VoiceSearchResult(:final transcript, :final intent):
        return _buildResultState(transcript, intent);
        
      case VoiceSearchError(:final message):
        return _buildErrorState(message);
    }
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMicButton(false),
          const SizedBox(height: 24),
          Text(
            'Tap to speak',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try saying "Play astrology" or "Next"',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningState(String partialResult) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMicButton(true),
          const SizedBox(height: 24),
          Text(
            'Listening...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          if (partialResult.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                partialResult,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingState(String transcript) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Processing...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '"$transcript"',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState(String transcript, VoiceIntent intent) {
    final controller = ref.read(voiceSearchControllerProvider);
    
    // Execute intent automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.executeIntent(intent);
      Navigator.pop(context);
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            _intentDescription(intent),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'Couldn\'t understand',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(voiceSearchControllerProvider).startListening();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(bool isListening) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        final controller = ref.read(voiceSearchControllerProvider);
        if (isListening) {
          controller.stopListening();
        } else {
          controller.startListening();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isListening ? 1.0 + (_pulseController.value * 0.1) : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? scheme.primary : scheme.surfaceContainerHighest,
                boxShadow: isListening
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.mic,
                size: 48,
                color: isListening ? scheme.onPrimary : scheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  String _intentDescription(VoiceIntent intent) {
    switch (intent) {
      case ControlIntent(:final action):
        return 'Command: ${action.name}';
      case InterestIntent(:final interest):
        return 'Playing: $interest';
      case PlayIntent(:final query):
        return 'Playing: $query';
      case SearchIntent(:final query):
        return 'Searching: $query';
      case TimerIntent(:final minutes):
        return 'Timer set: $minutes minutes';
      case AdjustIntent(:final type, :final increase):
        return '${increase ? "Increasing" : "Decreasing"} ${type.name}';
      case UnknownIntent():
        return 'Not understood';
    }
  }
}

class _LanguageSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(voiceLanguageProvider);
    final availableLangs = ref.watch(availableVoiceLanguagesProvider);

    return availableLangs.when(
      data: (languages) {
        return DropdownButton<VoiceLanguage>(
          value: currentLang,
          isExpanded: true,
          items: languages.map((lang) {
            return DropdownMenuItem(
              value: lang,
              child: Text(lang.displayName),
            );
          }).toList(),
          onChanged: (lang) {
            if (lang != null) {
              ref.read(voiceLanguageProvider.notifier).state = lang;
            }
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Language selection unavailable'),
    );
  }
}

/// Compact voice search button for app bars.
class VoiceSearchIconButton extends ConsumerWidget {
  const VoiceSearchIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isVoiceSearchActiveProvider);

    return IconButton(
      icon: Icon(
        Icons.mic,
        color: isActive ? Theme.of(context).colorScheme.primary : null,
      ),
      tooltip: 'Voice search',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const VoiceSearchSheet(),
        );
      },
    );
  }
}
