import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/calendar_cubit.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_card.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/calendar_event_form_sheet.dart';

/// Full-page calendar screen displaying all 12 months, year navigation,
/// monthly day grid, and events for any selected month or day.
class FullMonthsCalendarPage extends StatefulWidget {
  /// Optional initially selected day.
  final DateTime? initialSelectedDate;

  /// The month initially focused in the grid.
  final DateTime initialFocusedMonth;

  /// Creates a [FullMonthsCalendarPage].
  const FullMonthsCalendarPage({
    super.key,
    this.initialSelectedDate,
    required this.initialFocusedMonth,
  });

  @override
  State<FullMonthsCalendarPage> createState() => _FullMonthsCalendarPageState();
}

class _FullMonthsCalendarPageState extends State<FullMonthsCalendarPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialSelectedDate;
    final base = _selectedDate ?? widget.initialFocusedMonth;
    _focusedMonth = DateTime(base.year, base.month, 1);
  }

  void _changeMonth(int deltaMonths) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + deltaMonths,
        1,
      );
      _selectedDate = null;
    });
  }

  void _selectMonth(int month) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, month, 1);
      _selectedDate = null;
    });
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
        final canManageCalendar = state.currentUser.role.canManageCalendar;

        final daysInMonth = DateUtils.getDaysInMonth(
          _focusedMonth.year,
          _focusedMonth.month,
        );
        final firstDayOfMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month, 1);
        final int leadingEmptyDays = firstDayOfMonth.weekday % 7;

        final monthEvents = state.calendarEvents.where((e) {
          if (_selectedDate != null) {
            return e.eventDateTime.year == _selectedDate!.year &&
                e.eventDateTime.month == _selectedDate!.month &&
                e.eventDateTime.day == _selectedDate!.day;
          }
          return e.eventDateTime.year == _focusedMonth.year &&
              e.eventDateTime.month == _focusedMonth.month;
        }).toList();

        final weekDayLabels = isArabic
            ? const ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت']
            : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: Text(
              isArabic
                  ? 'التقويم الكامل (كل الأيام والشهور) 🗓️'
                  : 'Full Calendar (All Days & Months) 🗓️',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            actions: [
              if (canManageCalendar)
                IconButton(
                  tooltip: isArabic ? 'إضافة فعالية' : 'Add Event',
                  onPressed: () => showAddOrEditEventSheet(
                    context,
                    initialDate: _selectedDate ?? _focusedMonth,
                  ),
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(14.w),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. Year & All 12 Months Selector Bar
              LmtCard(
                padding: EdgeInsets.all(12.w),
                borderRadius: 20.r,
                accentColor: primary,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: Icon(Icons.chevron_left_rounded, color: primary),
                        ),
                        Column(
                          children: [
                            Text(
                              DateFormat('MMMM yyyy').format(_focusedMonth),
                              style: AppTypography.h4.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isArabic
                                  ? 'تصفح كل شهور السنة لمعرفة الأحداث القادمة'
                                  : 'Browse all months of the year for upcoming events',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon:
                              Icon(Icons.chevron_right_rounded, color: primary),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Horizontal 12-Months Strip with Event Count Badges
                    SizedBox(
                      height: 44.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: 12,
                        separatorBuilder: (_, _) => SizedBox(width: 8.w),
                        itemBuilder: (context, idx) {
                          final m = idx + 1;
                          final monthDate = DateTime(_focusedMonth.year, m, 1);
                          final isSelectedMonth = _focusedMonth.month == m;
                          final countInMonth = state.calendarEvents
                              .where((e) =>
                                  e.eventDateTime.year == _focusedMonth.year &&
                                  e.eventDateTime.month == m)
                              .length;

                          return InkWell(
                            borderRadius: BorderRadius.circular(14.r),
                            onTap: () => _selectMonth(m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelectedMonth
                                    ? primary
                                    : AppColors.surfaceOf(context),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: isSelectedMonth
                                      ? primary
                                      : (countInMonth > 0
                                          ? accentGreen
                                          : AppColors.borderOf(context)),
                                  width: countInMonth > 0 ? 1.5 : 1,
                                ),
                                boxShadow: AppColors.cardShadows(
                                  context,
                                  accent:
                                      isSelectedMonth ? primary : accentGreen,
                                  intensity: isSelectedMonth ? 0.8 : 0.4,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('MMM').format(monthDate),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isSelectedMonth
                                          ? Colors.white
                                          : textPrimary,
                                    ),
                                  ),
                                  if (countInMonth > 0) ...[
                                    SizedBox(width: 5.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelectedMonth
                                            ? Colors.white
                                            : accentGreen,
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                      child: Text(
                                        '$countInMonth',
                                        style: TextStyle(
                                          fontSize: 9.5.sp,
                                          fontWeight: FontWeight.bold,
                                          color: isSelectedMonth
                                              ? primary
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // 2. Full Month Days Grid Card
              LmtCard(
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
                          _focusedMonth.year,
                          _focusedMonth.month,
                          dayNum,
                        );
                        final now = DateTime.now();
                        final isToday = dayDate.year == now.year &&
                            dayDate.month == now.month &&
                            dayDate.day == now.day;
                        final isSelected = _selectedDate != null &&
                            _selectedDate!.year == dayDate.year &&
                            _selectedDate!.month == dayDate.month &&
                            _selectedDate!.day == dayDate.day;
                        final dayEvents = state.calendarEvents
                            .where(
                              (e) =>
                                  e.eventDateTime.year == dayDate.year &&
                                  e.eventDateTime.month == dayDate.month &&
                                  e.eventDateTime.day == dayDate.day,
                            )
                            .toList();
                        final hasEvents = dayEvents.isNotEmpty;

                        return InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () {
                            setState(() {
                              _selectedDate = isSelected ? null : dayDate;
                            });
                          },
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
                                width: (isSelected || hasEvents || isToday)
                                    ? 1.6
                                    : 1,
                              ),
                              boxShadow: (isSelected || hasEvents)
                                  ? AppColors.cardShadows(
                                      context,
                                      accent:
                                          isSelected ? primary : accentGreen,
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
                                    fontWeight:
                                        (isSelected || hasEvents || isToday)
                                            ? FontWeight.w900
                                            : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (hasEvents
                                            ? accentGreen
                                            : textPrimary),
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
                                      color: isSelected
                                          ? Colors.white
                                          : accentGreen,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      '${dayEvents.length}',
                                      style: TextStyle(
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? primary
                                            : Colors.white,
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
              ),
              SizedBox(height: 14.h),

              // 3. Apply Filter / Show All Events in Selected Month or Day
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? (isArabic
                              ? 'أحداث يوم ${DateFormat('dd MMMM yyyy').format(_selectedDate!)} (${monthEvents.length})'
                              : 'Events on ${DateFormat('dd MMM yyyy').format(_selectedDate!)} (${monthEvents.length})')
                          : (isArabic
                              ? 'أحداث شهر ${DateFormat('MMMM yyyy').format(_focusedMonth)} (${monthEvents.length})'
                              : 'Events in ${DateFormat('MMMM yyyy').format(_focusedMonth)} (${monthEvents.length})'),
                      style: AppTypography.h6.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop<Map<String, DateTime?>>(context, {
                        'date': _selectedDate,
                        'month': _selectedDate == null ? _focusedMonth : null,
                      });
                    },
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isArabic ? 'تطبيق الفلتر' : 'Apply Filter',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              if (monthEvents.isEmpty)
                LmtCard(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 38.sp,
                        color: textSecondary,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isArabic
                            ? 'لا توجد فعاليات مسجلة في هذا اليوم/الشهر بعد'
                            : 'No events scheduled on this date/month yet',
                        style: TextStyle(color: textSecondary),
                      ),
                      if (canManageCalendar) ...[
                        SizedBox(height: 10.h),
                        ElevatedButton.icon(
                          onPressed: () => showAddOrEditEventSheet(
                            context,
                            initialDate: _selectedDate ?? _focusedMonth,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            isArabic
                                ? 'إضافة فعالية في هذا التاريخ'
                                : 'Add Event on This Date',
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                ...monthEvents.map(
                  (evt) => CalendarEventCard(
                    evt: evt,
                    canManageCalendar: canManageCalendar,
                    accentGreen: accentGreen,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
