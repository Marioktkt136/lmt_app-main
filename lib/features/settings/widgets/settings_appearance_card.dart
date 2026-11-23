import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Appearance & Localization section card (Light/Dark theme switch and
/// Arabic/English language selector).
class SettingsAppearanceCard extends StatelessWidget {
  /// Whether the current locale is Arabic.
  final bool isArabic;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Callback invoked when the Light/Dark switch is toggled.
  final ValueChanged<bool> onToggleTheme;

  /// Callback invoked when a new [Locale] is selected.
  final ValueChanged<Locale> onSwitchLocale;

  /// Creates a [SettingsAppearanceCard].
  const SettingsAppearanceCard({
    super.key,
    required this.isArabic,
    required this.isDark,
    required this.onToggleTheme,
    required this.onSwitchLocale,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: AppColors.cardDecoration(
        context,
        radius: 22.r,
        accentColor: primary,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'المظهر واللغة (Appearance & Localization)'
                  : 'Appearance & Localization',
              style: AppTypography.h6.copyWith(
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: CircleAvatar(
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: primary,
                ),
              ),
              title: Text(
                isArabic
                    ? 'الوضع الليلي / النهاري (Light/Dark Switch)'
                    : 'Dark / Light Mode Switch',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5.sp,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                isDark
                    ? (isArabic
                        ? 'الوضع الليلي مفعل (#121212 / #1E1E24 WCAG AA)'
                        : 'Dark Mode Active (#121212 / #1E1E24 WCAG AA)')
                    : (isArabic
                        ? 'الوضع النهاري مفعل (#FFFFFF / #488FE1)'
                        : 'Light Mode Active (#FFFFFF / #488FE1)'),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textSecondary,
                ),
              ),
              value: isDark,
              activeTrackColor: primary,
              onChanged: onToggleTheme,
            ),
            const Divider(),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompactRow = constraints.maxWidth < 390;
                final selector = SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                    ButtonSegment(value: 'en', label: Text('EN')),
                  ],
                  selected: {isArabic ? 'ar' : 'en'},
                  onSelectionChanged: (set) => onSwitchLocale(Locale(set.first)),
                );
                if (isCompactRow) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primary.withValues(alpha: 0.12),
                              child: Icon(
                                Icons.language_rounded,
                                color: primary,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic
                                        ? 'لغة التطبيق (Ar / En)'
                                        : 'Application Language (Ar / En)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5.sp,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    isArabic
                                        ? 'العربية (مصر) / English (USA)'
                                        : 'English (USA) / العربية (Egypt)',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: selector,
                        ),
                      ],
                    ),
                  );
                }
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: primary.withValues(alpha: 0.12),
                    child: Icon(Icons.language_rounded, color: primary),
                  ),
                  title: Text(
                    isArabic
                        ? 'لغة التطبيق (Language Switch Ar/En)'
                        : 'Application Language (Ar / En)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5.sp,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isArabic
                        ? 'العربية (مصر) / English (USA)'
                        : 'English (USA) / العربية (Egypt)',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: textSecondary,
                    ),
                  ),
                  trailing: selector,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
