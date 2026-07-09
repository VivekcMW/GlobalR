import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../../shared/utils/interest_icons.dart';

/// Full-screen interests editor with visual cards.
/// Allows users to select their content interests and rebuilds the radio queue.
class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  late Set<String> _selected;
  late Set<String> _customInterests; // subset of _selected not in Interest.all
  bool _hasChanges = false;
  bool _saving = false;
  final _customInterestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = ref.read(profileProvider).interests.toSet();
    final builtInIds = Interest.all.map((i) => i.id).toSet();
    _customInterests = _selected.difference(builtInIds);
  }

  @override
  void dispose() {
    _customInterestController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      _hasChanges = true;
    });
  }

  void _addCustomInterest() {
    final raw = _customInterestController.text.trim();
    if (raw.isEmpty) return;
    final id = raw.toLowerCase();
    setState(() {
      _selected.add(id);
      _customInterests.add(id);
      _hasChanges = true;
    });
    _customInterestController.clear();

    // If nothing in the catalog matches this interest yet, queue a scrape
    // request — drained by tools/process_scrape_queue.py.
    final catalog = ref.read(catalogProvider).value;
    final hasContent =
        catalog?.items.any((it) => it.interests.contains(id)) ?? true;
    if (!hasContent) {
      ref.read(scrapeQueueServiceProvider).requestScrape(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$raw" has no content yet — we\'ve queued it to be sourced.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeCustomInterest(String id) {
    setState(() {
      _selected.remove(id);
      _customInterests.remove(id);
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    setState(() => _saving = true);

    // Save interests
    await ref.read(profileProvider.notifier).setInterests(_selected.toList());

    // Rebuild radio queue with new interests
    final radioState = ref.read(radioControllerProvider);
    if (radioState.queue.isNotEmpty) {
      await ref.read(radioControllerProvider.notifier).startRadio();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Interests updated! Your radio has been refreshed.'),
        duration: Duration(seconds: 2),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Interests'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select topics you\'re interested in',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_selected.length} selected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Your radio will play content matching these interests.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customInterestController,
                    decoration: const InputDecoration(
                      hintText: 'Add your own interest (e.g. dinosaurs)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addCustomInterest(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addCustomInterest,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add interest',
                ),
              ],
            ),
          ),
          if (_customInterests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _customInterests.map((id) {
                  return Chip(
                    label: Text(id),
                    onDeleted: () => _removeCustomInterest(id),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: Interest.all.length,
              itemBuilder: (context, index) {
                final interest = Interest.all[index];
                final isSelected = _selected.contains(interest.id);
                return _InterestCard(
                  interest: interest,
                  isSelected: isSelected,
                  onTap: () => _toggle(interest.id),
                );
              },
            ),
          ),
          if (_hasChanges)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InterestCard extends StatelessWidget {
  final Interest interest;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestCard({
    required this.interest,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = interestCategoryColor(interest.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? categoryColor.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InterestIconWidget(
                      interestId: interest.id,
                      category: interest.category,
                      size: 24,
                      isSelected: isSelected,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      interest.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? categoryColor
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
