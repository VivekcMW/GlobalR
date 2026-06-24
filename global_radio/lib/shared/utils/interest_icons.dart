/// Shared utility for interest icons and colors.
///
/// Use this across all screens that display interest-related UI
/// for consistent styling and iconography.
library;

import 'package:flutter/material.dart';

/// Get color for interest category.
Color interestCategoryColor(String category) {
  return switch (category) {
    'Stories' => const Color(0xFF6366F1),      // Indigo
    'Spiritual' => const Color(0xFF8B5CF6),    // Purple
    'Knowledge' => const Color(0xFF0EA5E9),    // Sky Blue
    'Entertainment' => const Color(0xFFF59E0B), // Amber
    'Lifestyle' => const Color(0xFFEC4899),    // Pink
    'News' => const Color(0xFF10B981),         // Emerald
    'Culture' => const Color(0xFFEF4444),      // Red
    _ => const Color(0xFF6B7280),              // Gray
  };
}

/// Get icon for interest category.
IconData interestCategoryIcon(String category) {
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

/// Get icon for a specific interest by ID.
IconData interestIcon(String interestId) {
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

/// A beautifully styled interest icon widget.
class InterestIconWidget extends StatelessWidget {
  final String interestId;
  final String category;
  final double size;
  final bool isSelected;
  final bool showBackground;

  const InterestIconWidget({
    super.key,
    required this.interestId,
    required this.category,
    this.size = 28,
    this.isSelected = false,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = interestCategoryColor(category);
    final icon = interestIcon(interestId);

    if (!showBackground) {
      return Icon(
        icon,
        size: size,
        color: isSelected ? color : color.withValues(alpha: 0.7),
      );
    }

    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [color, color.withValues(alpha: 0.8)]
              : [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.4),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: size,
        color: isSelected ? Colors.white : color,
      ),
    );
  }
}
