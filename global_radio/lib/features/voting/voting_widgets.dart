import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voting_service.dart';

/// Trending requests card for home screen.
class TrendingRequestsCard extends ConsumerWidget {
  const TrendingRequestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingRequestsProvider);
    final scheme = Theme.of(context).colorScheme;

    if (trending.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Community Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContentRequestsScreen(),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal scroll of trending
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: trending.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _CompactRequestCard(request: trending[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactRequestCard extends ConsumerWidget {
  final ContentRequest request;

  const _CompactRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 200,
      child: Card(
        child: InkWell(
          onTap: () {
            // Toggle vote
            if (request.hasVoted) {
              ref.read(contentRequestsProvider.notifier).unvote(request.id);
            } else {
              ref.read(contentRequestsProvider.notifier).vote(request.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Expanded(
                  child: Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Vote count & button
                Row(
                  children: [
                    // Language chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        request.language.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Vote button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: request.hasVoted
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            request.hasVoted
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 14,
                            color: request.hasVoted
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${request.votes}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: request.hasVoted
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full content requests screen.
class ContentRequestsScreen extends ConsumerStatefulWidget {
  const ContentRequestsScreen({super.key});

  @override
  ConsumerState<ContentRequestsScreen> createState() =>
      _ContentRequestsScreenState();
}

class _ContentRequestsScreenState extends ConsumerState<ContentRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trending'),
            Tab(text: 'New'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestsList(
            requests: ref.watch(trendingRequestsProvider),
            emptyMessage: 'No trending requests',
          ),
          _RequestsList(
            requests: ref.watch(requestsByStatusProvider('pending')),
            emptyMessage: 'No pending requests',
          ),
          _RequestsList(
            requests: ref.watch(requestsByStatusProvider('completed')),
            emptyMessage: 'No completed requests',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Request'),
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SubmitRequestSheet(),
    );
  }
}

class _RequestsList extends StatelessWidget {
  final List<ContentRequest> requests;
  final String emptyMessage;

  const _RequestsList({
    required this.requests,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _ExpandedRequestCard(request: requests[index]);
      },
    );
  }
}

class _ExpandedRequestCard extends ConsumerWidget {
  final ContentRequest request;

  const _ExpandedRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),

            // Description
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Tags row
            Row(
              children: [
                _TagChip(label: request.language),
                const SizedBox(width: 8),
                _TagChip(label: request.category),
                const Spacer(),

                // Vote button
                _VoteButton(request: request),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;
    IconData? icon;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = 'Approved';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Live';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Declined';
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = status;
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _VoteButton extends ConsumerWidget {
  final ContentRequest request;

  const _VoteButton({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        if (request.hasVoted) {
          ref.read(contentRequestsProvider.notifier).unvote(request.id);
        } else {
          ref.read(contentRequestsProvider.notifier).vote(request.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: request.hasVoted
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: request.hasVoted
                ? scheme.primary
                : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              request.hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
              color: request.hasVoted ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '${request.votes}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: request.hasVoted ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Submit request bottom sheet.
class _SubmitRequestSheet extends ConsumerStatefulWidget {
  const _SubmitRequestSheet();

  @override
  ConsumerState<_SubmitRequestSheet> createState() => _SubmitRequestSheetState();
}

class _SubmitRequestSheetState extends ConsumerState<_SubmitRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'podcast';
  String _selectedLanguage = 'hindi';
  bool _isSubmitting = false;

  final _categories = [
    'podcast',
    'kids_stories',
    'music',
    'devotional',
    'news',
    'comedy',
    'stories',
    'lifestyle',
  ];

  final _languages = [
    'hindi',
    'english',
    'tamil',
    'telugu',
    'kannada',
    'malayalam',
    'marathi',
    'gujarati',
    'bengali',
    'punjabi',
    'urdu',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request New Content',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'What content would you like?',
                  hintText: 'e.g., Bengali Science Podcasts',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Describe what you would like',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Category & Language row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v ?? 'podcast'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(),
                      ),
                      items: _languages
                          .map((l) => DropdownMenuItem(
                                value: l,
                                child: Text(l),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedLanguage = v ?? 'hindi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(contentRequestsProvider.notifier).submitRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            language: _selectedLanguage,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted!')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
