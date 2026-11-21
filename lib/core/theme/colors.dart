import 'package:material_ui/material_ui.dart';

/// Application Color Constants (WCAG AA 4.5:1 Compliant Palette)
/// Adheres strictly to "LMT app.docx" Light & Dark Mode Design System:
/// - Light Mode: Primary #488FE1, Background #FFFFFF, Surface #FFFFFF,
///   Primary Text #000000, Secondary Text #555555, Accent Green #2C8E1F, Border #E5E5E5
/// - Dark Mode: Primary #6AA5EA, Background #121212, Surface #1E1E24,
///   Primary Text #F0F4F8, Secondary Text #9BA3AF, Accent Green #4EBA3E, Border #2D3139
class AppColors {
  AppColors._();

  // ===========================================================================
  // Light Mode Palette (Exact Specification)
  // ===========================================================================
  static const Color primary = Color(0xFF488FE1); // Primary Blue
  static const Color background = Color(0xFFFFFFFF); // App background canvas
  static const Color surface = Color(0xFFFFFFFF); // Cards, modals, bottom sheets
  static const Color textPrimary = Color(0xFF000000); // Headings, high-emphasis text
  static const Color textSecondary = Color(0xFF555555); // Captions, subtitles, disabled
  static const Color accentGreen = Color(0xFF2C8E1F); // Success badges, checkmarks
  static const Color border = Color(0xFFE5E5E5); // List separators, input borders
  static const Color divider = Color(0xFFE5E5E5);

  // ===========================================================================
  // Dark Mode Palette (Exact Specification - WCAG AA Toned-Up Accents & Soft Text)
  // ===========================================================================
  static const Color primaryDarkTheme = Color(0xFF6AA5EA); // Lighter Sky Blue
  static const Color backgroundDark = Color(0xFF121212); // Dark Charcoal (avoids OLED smearing)
  static const Color surfaceDark = Color(0xFF1E1E24); // Elevated Surface
  static const Color textPrimaryDark = Color(0xFFF0F4F8); // Off-White (reduces eye strain)
  static const Color textSecondaryDark = Color(0xFF9BA3AF); // Muted Gray
  static const Color accentGreenDark = Color(0xFF4EBA3E); // Vibrant Leaf Green
  static const Color borderDark = Color(0xFF2D3139); // Subtle Border
  static const Color dividerDark = Color(0xFF2D3139);

  // ===========================================================================
  // Supporting & Legacy Aliases
  // ===========================================================================
  static const Color primaryDark = Color(0xFF2E6BB6);
  static const Color primaryLight = Color(0xFF488FE1);
  static const Color secondary = Color(0xFF6AA5EA);
  static const Color secondaryDark = Color(0xFF3A75C4);
  static const Color secondaryLight = Color(0xFF8BBBF0);
  static const Color accent = Color(0xFF2C8E1F);
  static const Color accentDark = Color(0xFF4EBA3E);
  static const Color accentLight = Color(0xFF6AD15A);

  static const Color textLight = Color(0xFFF0F4F8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF2C8E1F);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF488FE1);

  // ===========================================================================
  // Context-Aware Theme Helpers
  // ===========================================================================
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? primaryDarkTheme : primary;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? backgroundDark : background;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? surfaceDark : surface;

  static Color cardSurfaceOf(BuildContext context) =>
      isDark(context) ? surfaceDark : surface;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondary;

  static Color accentGreenOf(BuildContext context) =>
      isDark(context) ? accentGreenDark : accentGreen;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? borderDark : border;

  // ===========================================================================
  // Cohesive Shadow & Elevation System (Light & Dark Harmony)
  // ===========================================================================
  static List<BoxShadow> cardShadows(
    BuildContext context, {
    Color? accent,
    double intensity = 1.0,
  }) {
    final dark = isDark(context);
    final tint = accent ?? primaryOf(context);
    if (dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: (0.48 * intensity).clamp(0.0, 1.0)),
          blurRadius: 16 * intensity,
          spreadRadius: 0.5,
          offset: Offset(0, 6 * intensity),
        ),
        BoxShadow(
          color: tint.withValues(alpha: (0.14 * intensity).clamp(0.0, 1.0)),
          blurRadius: 12 * intensity,
          offset: Offset(0, 2 * intensity),
        ),
      ];
    }
    return [
      BoxShadow(
        color: tint.withValues(alpha: (0.16 * intensity).clamp(0.0, 1.0)),
        blurRadius: 16 * intensity,
        spreadRadius: 0.5,
        offset: Offset(0, 6 * intensity),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: (0.07 * intensity).clamp(0.0, 1.0)),
        blurRadius: 6 * intensity,
        offset: Offset(0, 2 * intensity),
      ),
    ];
  }

  static BoxDecoration cardDecoration(
    BuildContext context, {
    double radius = 18,
    Color? accentColor,
    Color? fillColor,
    bool isHighlighted = false,
    double shadowIntensity = 1.0,
  }) {
    final dark = isDark(context);
    final tint = accentColor ?? primaryOf(context);
    return BoxDecoration(
      color: fillColor ??
          (isHighlighted
              ? tint.withValues(alpha: dark ? 0.16 : 0.08)
              : cardSurfaceOf(context)),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isHighlighted
            ? tint.withValues(alpha: 0.65)
            : (dark
                ? tint.withValues(alpha: 0.22)
                : tint.withValues(alpha: 0.20)),
        width: isHighlighted ? 1.8 : 1.1,
      ),
      boxShadow: cardShadows(
        context,
        accent: tint,
        intensity: shadowIntensity,
      ),
    );
  }

  // ===========================================================================
  // Gradients
  // ===========================================================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF488FE1), Color(0xFF2B6CB0)],
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF121212)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, accentGreenDark],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundDark, surfaceDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, accentGreenDark],
  );
}
