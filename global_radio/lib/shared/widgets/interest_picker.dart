/// Premium interest picker with beautiful design, search, and category filtering.
///
/// Features:
/// - Elegant search with glass-morphism effect
/// - Smooth category pills with gradients
/// - Beautiful card-based layout with visual feedback
/// - Thoughtfully designed icons and colors
/// - Selection badges with animations
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Category colors for visual distinction.
Color _categoryColor(String category) {
  return switch (category) {
    'Stories' => const Color(0xFF6366F1),    // Indigo
    'Spiritual' => const Color(0xFF8B5CF6),  // Purple
    'Knowledge' => const Color(0xFF0EA5E9),  // Sky Blue
    'Entertainment' => const Color(0xFFF59E0B), // Amber
    'Lifestyle' => const Color(0xFFEC4899),  // Pink
    'News' => const Color(0xFF10B981),       // Emerald
    'Culture' => const Color(0xFFEF4444),    // Red
    _ => const Color(0xFF6B7280),            // Gray
  };
}

/// Category icon mapping.
IconData _categoryIcon(String category) {
  return switch (category) {
    'Stories' => Icons.auto_stories_rounded,
    'Spiritual' => Icons.self_improvement_rounded,
    'Knowledge' => Icons.lightbulb_rounded,
    'Entertainment' => Icons.theater_comedy_rounded,
    'Lifestyle' => Icons.favorite_rounded,
    'News' => Icons.public_rounded,
    'Culture' => Icons.palette_rounded,
    _ => Icons.grid_view_rounded,
  };
}

/// Interest picker with search and category filtering.
class InterestPicker extends StatefulWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  final int minSelection;

  const InterestPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.minSelection = 1,
  });

  @override
  State<InterestPicker> createState() => _InterestPickerState();
}

class _InterestPickerState extends State<InterestPicker> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Interest> get _filteredInterests {
    var interests = Interest.all;

    if (_selectedCategory != null) {
      interests = interests.where((i) => i.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      interests = interests.where((i) {
        return i.label.toLowerCase().contains(query) ||
            i.description.toLowerCase().contains(query) ||
            i.category.toLowerCase().contains(query);
      }).toList();
    }

    return interests;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Selection badge
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.selected.isEmpty
                  ? [
                      colorScheme.surfaceContainerHighest,
                      colorScheme.surfaceContainerHighest,
                    ]
                  : [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.primary.withValues(alpha: 0.08),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected.isNotEmpty
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.selected.isNotEmpty
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: widget.selected.isNotEmpty
                      ? Text(
                          '${widget.selected.length}',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : Icon(
                          Icons.touch_app_rounded,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selected.isEmpty
                          ? 'Tap to select interests'
                          : '${widget.selected.length} interest${widget.selected.length > 1 ? 's' : ''} selected',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.selected.isNotEmpty
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (widget.selected.isEmpty)
                      Text(
                        'Choose what you love to listen',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.selected.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.selected.clear();
                      widget.onChanged();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restart_alt_rounded,
                            size: 18,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search interests...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 50),
              suffixIcon: _searchQuery.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(height: 16),

        // Category pills
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            children: [
              _CategoryPill(
                label: 'All',
                icon: Icons.grid_view_rounded,
                color: colorScheme.primary,
                isSelected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              ...Interest.categories.map((cat) => _CategoryPill(
                    label: cat,
                    icon: _categoryIcon(cat),
                    color: _categoryColor(cat),
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Interest grid
        Expanded(
          child: _filteredInterests.isEmpty
              ? _EmptyState(query: _searchQuery)
              : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _filteredInterests.length,
                  itemBuilder: (context, index) {
                    final interest = _filteredInterests[index];
                    return _InterestCard(
                      interest: interest,
                      isSelected: widget.selected.contains(interest.id),
                      onTap: () {
                        if (widget.selected.contains(interest.id)) {
                          widget.selected.remove(interest.id);
                        } else {
                          widget.selected.add(interest.id);
                        }
                        widget.onChanged();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              query.isEmpty ? Icons.category_rounded : Icons.search_off_rounded,
              size: 40,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No interests available' : 'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            query.isEmpty
                ? 'Check back later'
                : 'Try a different search term',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category filter pill with gradient.
class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? color : colorScheme.outline.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Beautiful interest card with icon and selection state.
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
    final categoryColor = _categoryColor(interest.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? categoryColor.withValues(alpha: 0.6)
                  : colorScheme.outline.withValues(alpha: 0.15),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon container
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected
                              ? [categoryColor, categoryColor.withValues(alpha: 0.8)]
                              : [
                                  categoryColor.withValues(alpha: 0.15),
                                  categoryColor.withValues(alpha: 0.08),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: categoryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _getInterestIcon(interest.id),
                        size: 28,
                        color: isSelected ? Colors.white : categoryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Label
                    Text(
                      interest.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? categoryColor
                            : colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      interest.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Selection check
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
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

/// Get proper icon for each interest.
IconData _getInterestIcon(String interestId) {
  return switch (interestId) {
    // Stories
    'kids' => Icons.child_care_rounded,
    'moral' => Icons.menu_book_rounded,
    'mythology' => Icons.castle_rounded,
    'fairytales' => Icons.auto_fix_high_rounded,
    'bedtime' => Icons.bedtime_rounded,
    // Spiritual
    'devotion' => Icons.temple_buddhist_rounded,
    'meditation' => Icons.self_improvement_rounded,
    'yoga' => Icons.accessibility_new_rounded,
    'astrology' => Icons.star_rounded,
    'mantras' => Icons.music_note_rounded,
    // Knowledge
    'education' => Icons.school_rounded,
    'history' => Icons.account_balance_rounded,
    'science' => Icons.science_rounded,
    'technology' => Icons.computer_rounded,
    'biography' => Icons.person_rounded,
    // Entertainment
    'comedy' => Icons.sentiment_very_satisfied_rounded,
    'drama' => Icons.theater_comedy_rounded,
    'music' => Icons.headphones_rounded,
    'poetry' => Icons.format_quote_rounded,
    'fiction' => Icons.book_rounded,
    // Lifestyle
    'health' => Icons.favorite_rounded,
    'cooking' => Icons.restaurant_rounded,
    'travel' => Icons.flight_rounded,
    'motivation' => Icons.rocket_launch_rounded,
    'relationships' => Icons.people_rounded,
    // News
    'news' => Icons.newspaper_rounded,
    'business' => Icons.business_center_rounded,
    'sports' => Icons.sports_soccer_rounded,
    'politics' => Icons.how_to_vote_rounded,
    // Culture
    'folklore' => Icons.diversity_3_rounded,
    'culture' => Icons.palette_rounded,
    'festivals' => Icons.celebration_rounded,
    _ => Icons.category_rounded,
  };
}
