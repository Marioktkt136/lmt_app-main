import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';

/// Compact single-line button in [CalendarScreen] that opens the full
/// multi-month calendar screen ([FullMonthsCalendarPage]).
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

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary.withValues(alpha: 0.12),
                foregroundColor: primary,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                side: BorderSide(
                  color: primary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: onOpenFullCalendar,
              icon: Icon(Icons.calendar_month_rounded, size: 18.sp),
              label: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasActiveFilter
                          ? activeFilterLabel
                          : (isArabic
                              ? 'فتح التقويم الكامل (كل الأيام والشهور) 📅'
                              : 'Open Full Calendar (All Days & Months) 📅'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.open_in_full_rounded,
                    size: 14.sp,
                    color: primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasActiveFilter) ...[
          SizedBox(width: 6.w),
          SizedBox(
            height: 38.h,
            width: 38.h,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.10),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              tooltip: isArabic ? 'إلغاء الفلتر' : 'Clear Filter',
              onPressed: onClearFilter,
              icon: Icon(
                Icons.filter_alt_off_rounded,
                color: AppColors.error,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
