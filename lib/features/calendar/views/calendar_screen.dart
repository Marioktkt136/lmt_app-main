import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/calendar_cubit.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_card.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/calendar_event_form_sheet.dart';
import 'full_months_calendar_page.dart';

/// Main Calendar View displaying the quick horizontal days strip,
/// the Full Calendar Page launcher card, and scheduled team events.
class CalendarScreen extends StatefulWidget {
  /// Creates a [CalendarScreen].
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _selectedDateFilter;
  DateTime? _selectedMonthFilter;

  Future<void> _openFullCalendarPage(BuildContext context) async {
    final result = await Navigator.push<Map<String, DateTime?>>(
      context,
      MaterialPageRoute(
        builder: (_) => FullMonthsCalendarPage(
          initialSelectedDate: _selectedDateFilter,
          initialFocusedMonth: _selectedMonthFilter ?? DateTime.now(),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedDateFilter = result['date'];
        _selectedMonthFilter = result['month'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final primary = AppColors.primaryOf(context);
        final accentGreen = AppColors.accentGreenOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);
        final border = AppColors.borderOf(context);
        final canManageCalendar = state.currentUser.role.canManageCalendar;

        final now = DateTime.now();
        final upcomingDays = List.generate(
          14,
          (i) => DateTime(now.year, now.month, now.day + i),
        );

        final filteredEvents = state.calendarEvents.where((evt) {
          if (_selectedDateFilter != null) {
            return evt.eventDateTime.year == _selectedDateFilter!.year &&
                evt.eventDateTime.month == _selectedDateFilter!.month &&
                evt.eventDateTime.day == _selectedDateFilter!.day;
          }
          if (_selectedMonthFilter != null) {
            return evt.eventDateTime.year == _selectedMonthFilter!.year &&
                evt.eventDateTime.month == _selectedMonthFilter!.month;
          }
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row + Add Event Button (Admin/Editor)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'تقويم الفعاليات والبروفات 🗓️'
                            : 'Team Events & Rehearsals 🗓️',
                        style: AppTypography.h5.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isArabic
                            ? 'اختر يوماً من الشريط أو افتح تقويم كل الشهور القادمة'
                            : 'Select a day or open the full multi-month calendar',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManageCalendar)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: AppColors.cardShadows(
                        context,
                        accent: primary,
                        intensity: 0.9,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                      ),
                      onPressed: () => showAddOrEditEventSheet(context),
                      icon: const Icon(Icons.add_alarm_rounded, size: 18),
                      label: Text(
                        isArabic ? 'فعالية جديدة' : 'New Event',
                        style: TextStyle(fontSize: 11.5.sp),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),

            // 1. Horizontal Days Strip at the Top
            SizedBox(
              height: 70.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                itemCount: upcomingDays.length + 1,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    final isAllSelected = _selectedDateFilter == null &&
                        _selectedMonthFilter == null;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14.r),
                      onTap: () => setState(() {
                        _selectedDateFilter = null;
                        _selectedMonthFilter = null;
                      }),
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
                              color:
                                  isAllSelected ? Colors.white : textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final day = upcomingDays[idx - 1];
                  final isSelected = _selectedDateFilter != null &&
                      _selectedDateFilter!.year == day.year &&
                      _selectedDateFilter!.month == day.month &&
                      _selectedDateFilter!.day == day.day;
                  final hasEvent = state.calendarEvents.any(
                    (e) =>
                        e.eventDateTime.year == day.year &&
                        e.eventDateTime.month == day.month &&
                        e.eventDateTime.day == day.day,
                  );

                  return InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => setState(() {
                      _selectedDateFilter = day;
                      _selectedMonthFilter = null;
                    }),
                    child: Container(
                      width: 56.w,
                      padding: EdgeInsets.symmetric(vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary
                            : AppColors.cardSurfaceOf(context),
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
                              color: isSelected
                                  ? Colors.white70
                                  : textSecondary,
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
            ),
            SizedBox(height: 10.h),

            // 2. Full Calendar Launcher Card Below It
            LmtCard(
              borderRadius: 20.r,
              accentColor: primary,
              isHighlighted: true,
              onTap: () => _openFullCalendarPage(context),
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
                          _activeFilterLabel(isArabic),
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedDateFilter != null ||
                      _selectedMonthFilter != null)
                    IconButton(
                      tooltip: isArabic ? 'عرض الكل' : 'Show All',
                      onPressed: () {
                        setState(() {
                          _selectedDateFilter = null;
                          _selectedMonthFilter = null;
                        });
                      },
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
            ),
            SizedBox(height: 12.h),

            // 3. Events List
            Expanded(
              child: filteredEvents.isEmpty
                  ? LmtEmptyState(
                      icon: Icons.event_busy_rounded,
                      message: isArabic
                          ? 'لا توجد فعاليات مسجلة في هذا التاريخ'
                          : 'No events scheduled for this period',
                      action: TextButton.icon(
                        onPressed: () => setState(() {
                          _selectedDateFilter = null;
                          _selectedMonthFilter = null;
                        }),
                        icon: const Icon(Icons.restore_rounded),
                        label: Text(
                          isArabic
                              ? 'عرض كل الفعاليات القادمة'
                              : 'Show All Upcoming Events',
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 4.h,
                      ),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final evt = filteredEvents[index];
                        return CalendarEventCard(
                          evt: evt,
                          canManageCalendar: canManageCalendar,
                          accentGreen: accentGreen,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _activeFilterLabel(bool isArabic) {
    if (_selectedDateFilter != null) {
      return isArabic
          ? 'تصفية حسب يوم: ${DateFormat('EEEE, dd MMMM yyyy').format(_selectedDateFilter!)}'
          : 'Filtered by Day: ${DateFormat('EEE, dd MMM yyyy').format(_selectedDateFilter!)}';
    }
    if (_selectedMonthFilter != null) {
      return isArabic
          ? 'تصفية حسب شهر: ${DateFormat('MMMM yyyy').format(_selectedMonthFilter!)}'
          : 'Filtered by Month: ${DateFormat('MMMM yyyy').format(_selectedMonthFilter!)}';
    }
    return isArabic
        ? 'يعرض حالياً: كل أحداث الشهور الحالية والقادمة • اضغط لاختيار شهر أو يوم'
        : 'Showing: All current & upcoming months • Tap to browse any month or day';
  }
}
