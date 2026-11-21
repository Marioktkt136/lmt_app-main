import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_card.dart';

/// Highlighted card in [CalendarScreen] that opens the full multi-month
/// calendar screen ([FullMonthsCalendarPage]).
class FullCalendarLauncherCard extends StatelessWidget {
  /// Summary text describing the active day/month filter.
  final String activeFilterLabel;

  /// Whether a day or month filter is currently applied.
  final bool hasActiveFilter;

  /// Opens [FullMonthsCalendarPage].
  final VoidCallback onOpenFullCalendar;

  /// Clears any active day/month filter.
  final VoidCallback onClearFilter;

  /// Creates a [FullCalendarLauncherCard].
  const FullCalendarLauncherCard({
    super.key,
    required this.activeFilterLabel,
    required this.hasActiveFilter,
    required this.onOpenFullCalendar,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return LmtCard(
      borderRadius: 20.r,
      accentColor: primary,
      isHighlighted: true,
      onTap: onOpenFullCalendar,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: AppColors.cardShadows(
                context,
                accent: primary,
                intensity: 0.8,
              ),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'فتح تقويم كل الأيام والشهور القادمة 📅'
                      : 'Open Full Calendar (All Days & Months) 📅',
                  style: AppTypography.h6.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  activeFilterLabel,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (hasActiveFilter)
            IconButton(
              tooltip: isArabic ? 'عرض الكل' : 'Show All',
              onPressed: onClearFilter,
              icon: Icon(
                Icons.filter_alt_off_rounded,
                color: AppColors.error,
                size: 20.sp,
              ),
            ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.open_in_full_rounded,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
