import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// "Calm Audio, Indian Warmth" — Material 3, dark-first, saffron/indigo.
/// Tokens mirror docs/design-and-payments-spec.md §3.
/// "Prabhat" extension: the dark accent follows the time of day (Daypart)
/// and Kids Mode swaps to a rounder, warmer skin.
class AppTheme {
  AppTheme._();

  // Brand tokens
  static const Color saffron = Color(0xFFE0A93B); // primary / CTA / play
  static const Color indigo = Color(0xFF6C4A8C); // secondary accent
  static const Color darkBg = Color(0xFF14110E); // warm near-black
  static const Color darkSurface = Color(0xFF1F1A15);
  static const Color darkOnSurface = Color(0xFFEDE6DA);
  static const Color lightBg = Color(0xFFFBF7F0);

  // Shape / spacing
  static const double radiusCard = 16;
  static const double radiusSheet = 20;
  static const double radiusButton = 12;
  static const double minTap = 48;

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: saffron,
    onPrimary: Color(0xFF1A1300),
    secondary: indigo,
    onSecondary: Color(0xFFFFFFFF),
    surface: darkSurface,
    onSurface: darkOnSurface,
    error: Color(0xFFFFB4AB),
  );

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFF8A5A00),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF5A3C78),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F1A15),
    error: Color(0xFFBA1A1A),
  );

  static ThemeData dark({Daypart? daypart, bool kids = false}) {
    if (kids) return _buildKids();
    final accent = daypart?.accent ?? saffron;
    final scheme = _darkScheme.copyWith(primary: accent);
    return _build(scheme, darkBg, Brightness.dark);
  }

  static ThemeData light() => _build(_lightScheme, lightBg, Brightness.light);

  /// Kids Mode skin: rounder shapes, warm pink accent, playful display font.
  static ThemeData _buildKids() {
    final scheme = _darkScheme.copyWith(
      primary: DesignTokens.kidsAccent,
      onPrimary: const Color(0xFF2A0E1A),
      secondary: const Color(0xFF9B8FC7),
    );
    final base = _build(scheme, darkBg, Brightness.dark);
    final playful = GoogleFonts.baloo2TextTheme(base.textTheme);
    return base.copyWith(
      textTheme: playful,
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          minimumSize: const Size(0, minTap),
          textStyle:
              playful.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData _build(ColorScheme scheme, Color bg, Brightness b) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
    );
    // Noto Sans renders all 22 Indian scripts cleanly.
    // Baloo 2 (Devanagari + Latin, glyph-fallback elsewhere) warms up the
    // large display styles only — body text stays Noto Sans.
    final noto = GoogleFonts.notoSansTextTheme(base.textTheme);
    final textTheme = noto.copyWith(
      headlineMedium: GoogleFonts.baloo2(
          textStyle: noto.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      headlineSmall: GoogleFonts.baloo2(
          textStyle:
              noto.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
    );
    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          minimumSize: const Size(0, minTap), // accessible tap target
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    );
  }
}
