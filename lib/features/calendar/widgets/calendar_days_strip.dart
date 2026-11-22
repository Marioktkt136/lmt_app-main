import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';

/// Horizontal 14-day quick selector strip displayed at the top of [CalendarScreen].
class CalendarDaysStrip extends StatelessWidget {
  /// Upcoming days to display in the strip.
  final List<DateTime> upcomingDays;

  /// Currently selected date filter (null means "All").
  final DateTime? selectedDateFilter;

  /// Currently selected month filter (null means "All").
  final DateTime? selectedMonthFilter;

  /// All scheduled calendar events used to render green indicator dots.
  final List<CalendarEventModel> calendarEvents;

  /// Callback invoked when the "All" chip is tapped.
  final VoidCallback onSelectAll;

  /// Callback invoked when a specific day chip is tapped.
  final ValueChanged<DateTime> onSelectDay;

  /// Creates a [CalendarDaysStrip].
  const CalendarDaysStrip({
    super.key,
    required this.upcomingDays,
    required this.selectedDateFilter,
    required this.selectedMonthFilter,
    required this.calendarEvents,
    required this.onSelectAll,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    return SizedBox(
      height: 70.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
        itemCount: upcomingDays.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, idx) {
          if (idx == 0) {
            final isAllSelected =
                selectedDateFilter == null && selectedMonthFilter == null;
            return InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: onSelectAll,
              child: Container(
                width: 60.w,
                decoration: BoxDecoration(
                  color: isAllSelected
                      ? primary
                      : AppColors.cardSurfaceOf(context),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isAllSelected ? primary : border,
                  ),
                  boxShadow: AppColors.cardShadows(
                    context,
                    accent: primary,
                    intensity: isAllSelected ? 0.85 : 0.45,
                  ),
                ),
                child: Center(
                  child: Text(
                    isArabic ? 'الكل\n🗓️' : 'All\n🗓️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isAllSelected ? Colors.white : textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }

          final day = upcomingDays[idx - 1];
          final isSelected = selectedDateFilter != null &&
              selectedDateFilter!.year == day.year &&
              selectedDateFilter!.month == day.month &&
              selectedDateFilter!.day == day.day;
          final hasEvent = calendarEvents.any((e) => e.occursOnDay(day));

          return InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: () => onSelectDay(day),
            child: Container(
              width: 56.w,
              padding: EdgeInsets.symmetric(vertical: 5.h),
              decoration: BoxDecoration(
                color:
                    isSelected ? primary : AppColors.cardSurfaceOf(context),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected
                      ? primary
                      : (hasEvent ? accentGreen : border),
                  width: hasEvent ? 1.8 : 1,
                ),
                boxShadow: AppColors.cardShadows(
                  context,
                  accent: isSelected
                      ? primary
                      : (hasEvent ? accentGreen : primary),
                  intensity: (isSelected || hasEvent) ? 0.75 : 0.4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isSelected ? Colors.white70 : textSecondary,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : textPrimary,
                    ),
                  ),
                  if (hasEvent)
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
