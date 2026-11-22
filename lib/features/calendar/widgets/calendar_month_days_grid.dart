import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_card.dart';

/// Renders the 7-column monthly day grid inside [FullMonthsCalendarPage].
class CalendarMonthDaysGrid extends StatelessWidget {
  /// The currently focused month (`DateTime(year, month, 1)`).
  final DateTime focusedMonth;

  /// The currently selected day (if any).
  final DateTime? selectedDate;

  /// All scheduled calendar events used to render per-day count badges.
  final List<CalendarEventModel> calendarEvents;

  /// Callback invoked when a day cell is tapped.
  final ValueChanged<DateTime> onDayTapped;

  /// Creates a [CalendarMonthDaysGrid].
  const CalendarMonthDaysGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.calendarEvents,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final int leadingEmptyDays = firstDayOfMonth.weekday % 7;

    final weekDayLabels = isArabic
        ? const ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت']
        : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return LmtCard(
      padding: EdgeInsets.all(14.w),
      borderRadius: 22.r,
      accentColor: primary,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDayLabels
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 10.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyDays + daysInMonth,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 6.w,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays) {
                return const SizedBox.shrink();
              }
              final dayNum = index - leadingEmptyDays + 1;
              final dayDate = DateTime(
                focusedMonth.year,
                focusedMonth.month,
                dayNum,
              );
              final now = DateTime.now();
              final isToday = dayDate.year == now.year &&
                  dayDate.month == now.month &&
                  dayDate.day == now.day;
              final isSelected = selectedDate != null &&
                  selectedDate!.year == dayDate.year &&
                  selectedDate!.month == dayDate.month &&
                  selectedDate!.day == dayDate.day;
              final dayEvents =
                  calendarEvents.where((e) => e.occursOnDay(dayDate)).toList();
              final hasEvents = dayEvents.isNotEmpty;

              return InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () => onDayTapped(dayDate),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : (hasEvents
                            ? accentGreen.withValues(alpha: 0.14)
                            : (isToday
                                ? primary.withValues(alpha: 0.12)
                                : AppColors.surfaceOf(context))),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : (hasEvents
                              ? accentGreen
                              : (isToday
                                  ? primary
                                  : AppColors.borderOf(context))),
                      width: (isSelected || hasEvents || isToday) ? 1.6 : 1,
                    ),
                    boxShadow: (isSelected || hasEvents)
                        ? AppColors.cardShadows(
                            context,
                            accent: isSelected ? primary : accentGreen,
                            intensity: 0.55,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: (isSelected || hasEvents || isToday)
                              ? FontWeight.w900
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (hasEvents ? accentGreen : textPrimary),
                        ),
                      ),
                      if (hasEvents)
                        Container(
                          margin: EdgeInsets.only(top: 2.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : accentGreen,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${dayEvents.length}',
                            style: TextStyle(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? primary : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
