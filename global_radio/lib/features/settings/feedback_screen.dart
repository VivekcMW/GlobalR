/// User feedback and support screen.
///
/// Allows users to:
/// - Submit bug reports with optional screenshots
/// - Request features
/// - Contact support via email
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants.dart';
import '../../data/services/feedback_service.dart';

/// Feedback type.
enum FeedbackType {
  bug('Bug Report', Icons.bug_report),
  feature('Feature Request', Icons.lightbulb_outline),
  question('Question', Icons.help_outline),
  other('Other', Icons.chat_bubble_outline);

  final String label;
  final IconData icon;
  const FeedbackType(this.label, this.icon);
}

/// Feedback form state.
class FeedbackFormState {
  final FeedbackType type;
  final String message;
  final int? rating;
  final bool includeDeviceInfo;
  final bool isSubmitting;
  final String? error;

  const FeedbackFormState({
    this.type = FeedbackType.bug,
    this.message = '',
    this.rating,
    this.includeDeviceInfo = true,
    this.isSubmitting = false,
    this.error,
  });

  FeedbackFormState copyWith({
    FeedbackType? type,
    String? message,
    int? rating,
    bool? includeDeviceInfo,
    bool? isSubmitting,
    String? error,
  }) {
    return FeedbackFormState(
      type: type ?? this.type,
      message: message ?? this.message,
      rating: rating ?? this.rating,
      includeDeviceInfo: includeDeviceInfo ?? this.includeDeviceInfo,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

/// Feedback form provider.
final feedbackFormProvider = StateNotifierProvider.autoDispose<FeedbackFormNotifier, FeedbackFormState>((ref) {
  return FeedbackFormNotifier();
});

/// Feedback form notifier.
class FeedbackFormNotifier extends StateNotifier<FeedbackFormState> {
  FeedbackFormNotifier() : super(const FeedbackFormState());

  void setType(FeedbackType type) {
    state = state.copyWith(type: type);
  }

  void setMessage(String message) {
    state = state.copyWith(message: message);
  }

  void setRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void setIncludeDeviceInfo(bool include) {
    state = state.copyWith(includeDeviceInfo: include);
  }

  Future<bool> submit(FeedbackService feedbackService) async {
    if (state.message.trim().isEmpty) {
      state = state.copyWith(error: 'Please enter your feedback');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      // Collect device info if enabled
      Map<String, dynamic>? deviceInfo;
      if (state.includeDeviceInfo) {
        final packageInfo = await PackageInfo.fromPlatform();
        deviceInfo = {
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'osVersion': kIsWeb ? 'web' : Platform.operatingSystemVersion,
          'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
        };
      }

      final success = await feedbackService.submitFeedback(
        message: state.message,
        rating: state.rating ?? 3,
        category: state.type.label,
        includeDeviceInfo: state.includeDeviceInfo,
        deviceInfo: deviceInfo,
      );

      state = state.copyWith(isSubmitting: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to submit feedback. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const FeedbackFormState();
  }
}

/// Feedback screen.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(feedbackFormProvider);
    final formNotifier = ref.read(feedbackFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Support email card
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email Support'),
                subtitle: Text(AppConfig.supportEmail),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ref.read(feedbackServiceProvider).openEmailClient(
                    subject: 'Global Radio Support Request',
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Feedback type selection
            Text(
              'What type of feedback?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FeedbackType.values.map((type) {
                final isSelected = formState.type == type;
                return ChoiceChip(
                  avatar: Icon(
                    type.icon,
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (_) => formNotifier.setType(type),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Rating (optional)
            Text(
              'How would you rate your experience?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = formState.rating != null && formState.rating! >= rating;
                return IconButton(
                  icon: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: isSelected ? Colors.amber : Colors.grey,
                    size: 36,
                  ),
                  onPressed: () => formNotifier.setRating(rating),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Message input
            Text(
              'Your feedback',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Please describe your issue or suggestion...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: formNotifier.setMessage,
            ),
            const SizedBox(height: 16),

            // Include device info option
            CheckboxListTile(
              value: formState.includeDeviceInfo,
              onChanged: (value) => formNotifier.setIncludeDeviceInfo(value ?? true),
              title: const Text('Include device information'),
              subtitle: const Text('Helps us debug issues faster'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Error message
            if (formState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  formState.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: formState.isSubmitting
                    ? null
                    : () async {
                        final feedbackService = ref.read(feedbackServiceProvider);
                        final success = await formNotifier.submit(feedbackService);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you for your feedback!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                icon: formState.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(formState.isSubmitting ? 'Submitting...' : 'Submit Feedback'),
              ),
            ),
            const SizedBox(height: 24),

            // FAQ section
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              context,
              'How do I go premium?',
              'Go to Settings > Premium to subscribe and remove ads.',
            ),
            _buildFAQItem(
              context,
              'How do I download for offline?',
              'Premium users can download content by tapping the download icon on any item.',
            ),
            _buildFAQItem(
              context,
              'Why is playback stopping?',
              'Check your internet connection and battery optimization settings.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
