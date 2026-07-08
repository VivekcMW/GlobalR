import 'package:flutter/material.dart';

/// "Prabhat" design system tokens — category hues, daypart palettes,
/// status colors. Extends the base "Calm Audio, Indian Warmth" theme.
class DesignTokens {
  DesignTokens._();

  // ---------------------------------------------------------------- status
  /// Pulsing dot for freshly generated daily items.
  static const Color live = Color(0xFFFF6B5E);
  static const Color success = Color(0xFF7FD18B);
  static const Color warning = Color(0xFFE8C56A);

  /// Kids Mode accent — warm pink, signals the mode switch to parents.
  static const Color kidsAccent = Color(0xFFF2A6C0);

  // --------------------------------------------------------- category hues
  /// One hue per interest — used for chips, mini-player edge, rangoli rings.
  static const Map<String, Color> _interestHues = {
    // Stories
    'kids': Color(0xFFF2A6C0),
    'moral': Color(0xFFE8C56A),
    'mythology': Color(0xFFD98B6A),
    'fairytales': Color(0xFFE89AC7),
    'bedtime': Color(0xFF9B8FC7),
    // Spiritual
    'devotion': Color(0xFFE0A93B),
    'meditation': Color(0xFFA8B8D8),
    'yoga': Color(0xFF8FC7A8),
    'astrology': Color(0xFFC9A0DC),
    'mantras': Color(0xFFE0B87A),
    // Knowledge
    'education': Color(0xFF6FC7BB),
    'history': Color(0xFFC7A96F),
    'science': Color(0xFF7FB3D5),
    'technology': Color(0xFF8FA8D8),
    'biography': Color(0xFFB8A88F),
    // Entertainment
    'comedy': Color(0xFFF0B860),
    'drama': Color(0xFFD88FA8),
    'music': Color(0xFF9FC78F),
    'poetry': Color(0xFFC78FB8),
    'fiction': Color(0xFF8FB8C7),
    // Lifestyle
    'health': Color(0xFF8FD1A8),
    'cooking': Color(0xFFE0A87A),
    'travel': Color(0xFF7AC7D8),
    'motivation': Color(0xFFE8956A),
    'relationships': Color(0xFFE8A0A0),
    // News
    'news': Color(0xFF7FB3D5),
    'business': Color(0xFFC7A96F),
    'sports': Color(0xFF8FC79F),
    'politics': Color(0xFFB0A8C7),
    // Culture
    'folklore': Color(0xFFA8C686),
    'culture': Color(0xFFD8A88F),
    'festivals': Color(0xFFE8B860),
  };

  /// Hue for an interest id; falls back to saffron.
  static Color interestHue(String interestId) =>
      _interestHues[interestId] ?? const Color(0xFFE0A93B);

  /// Cycling palette for the onboarding language grid tiles.
  static const List<Color> languageTileHues = [
    Color(0xFFE0A93B), // saffron
    Color(0xFF6FC7BB), // teal
    Color(0xFFE89AC7), // pink
    Color(0xFF7FB3D5), // sky
    Color(0xFFA8C686), // leaf
    Color(0xFF9B8FC7), // lavender
    Color(0xFFD97B3F), // ember
    Color(0xFFC9A0DC), // lilac
  ];
}

/// Time-of-day design mode — "radio that follows the Indian day".
/// The dark theme accent + screen gradients shift with the daypart.
enum Daypart {
  prabhat(
    labelEn: 'Prabhat',
    labelNative: 'प्रभात',
    greetingEn: 'Good morning',
    heroLineEn: 'Prabhat — devotion & your morning brief',
    accent: Color(0xFFE0A93B),
    gradientTop: Color(0xFF2A1A2E),
    icon: Icons.wb_twilight_rounded,
  ),
  din(
    labelEn: 'Din',
    labelNative: 'दिन',
    greetingEn: 'Namaste',
    heroLineEn: 'Din — news, learning & light stories',
    accent: Color(0xFFE0A93B),
    gradientTop: Color(0xFF1F1A15),
    icon: Icons.wb_sunny_rounded,
  ),
  sandhya(
    labelEn: 'Sandhya',
    labelNative: 'संध्या',
    greetingEn: 'Good evening',
    heroLineEn: 'Sandhya — folklore & festival tales',
    accent: Color(0xFFD97B3F),
    gradientTop: Color(0xFF331A14),
    icon: Icons.nights_stay_rounded,
  ),
  ratri(
    labelEn: 'Ratri',
    labelNative: 'रात्रि',
    greetingEn: 'Good night',
    heroLineEn: 'Ratri — soft bedtime stories',
    accent: Color(0xFFB8893A),
    gradientTop: Color(0xFF0D0B09),
    icon: Icons.bedtime_rounded,
  );

  const Daypart({
    required this.labelEn,
    required this.labelNative,
    required this.greetingEn,
    required this.heroLineEn,
    required this.accent,
    required this.gradientTop,
    required this.icon,
  });

  final String labelEn;
  final String labelNative;
  final String greetingEn;
  final String heroLineEn;
  final Color accent;
  final Color gradientTop;
  final IconData icon;

  static Daypart fromHour(int hour) {
    if (hour >= 5 && hour < 9) return Daypart.prabhat;
    if (hour >= 9 && hour < 17) return Daypart.din;
    if (hour >= 17 && hour < 21) return Daypart.sandhya;
    return Daypart.ratri;
  }

  static Daypart now() => fromHour(DateTime.now().hour);
}
