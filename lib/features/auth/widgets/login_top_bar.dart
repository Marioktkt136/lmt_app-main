import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/app_assets.dart';

/// Top row of the login screen with theme and language toggles.
///
/// Always laid out LTR (theme left, language right) regardless of locale.
class LoginTopBar extends StatelessWidget {
  /// Creates the top bar.
  const LoginTopBar({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.themeTooltip,
    this.languageTooltip,
  });

  /// Whether the dark theme is active.
  final bool isDark;

  /// Toggles light/dark mode.
  final VoidCallback onToggleTheme;

  /// Toggles Arabic/English.
  final VoidCallback onToggleLanguage;

  /// Tooltip for the theme button.
  final String? themeTooltip;

  /// Tooltip for the language button.
  final String? languageTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundToggle(
          isDark: isDark,
          tooltip: themeTooltip,
          onPressed: onToggleTheme,
          icon: Image.asset(
            isDark ? AppAssets.darkModeIcon : AppAssets.lightModeIcon,
            width: 30.w,
            height: 30.w,
          ),
        ),
        _RoundToggle(
          isDark: isDark,
          tooltip: languageTooltip,
          onPressed: onToggleLanguage,
          icon: Image.asset(
            AppAssets.languageModeIcon,
            width: 24.w,
            height: 24.w,
          ),
        ),
      ],
    );
  }
}

class _RoundToggle extends StatelessWidget {
  const _RoundToggle({
    required this.isDark,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  final bool isDark;
  final VoidCallback onPressed;
  final Widget icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondary : AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(4, 6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}
