import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_card.dart';
import '../cubit/calendar_cubit.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/calendar_event_form_sheet.dart';
import '../widgets/calendar_month_days_grid.dart';
import '../widgets/calendar_month_selector_card.dart';

/// Full-page calendar screen displaying all 12 months, year navigation,
/// monthly day grid, and events for any selected month or day.
///
/// Automatically selects Today and the current month when opened with no active
/// selection and resets back to Today after [idleResetDuration] of inactivity.
class FullMonthsCalendarPage extends StatefulWidget {
  /// Optional initially selected day.
  final DateTime? initialSelectedDate;

  /// The month initially focused in the grid.
  final DateTime initialFocusedMonth;

  /// Duration of inactivity after which the calendar automatically resets to
  /// Today and the current month.
  final Duration idleResetDuration;

  /// Creates a [FullMonthsCalendarPage].
  const FullMonthsCalendarPage({
    super.key,
    this.initialSelectedDate,
    required this.initialFocusedMonth,
    this.idleResetDuration = const Duration(seconds: 15),
  });

  @override
  State<FullMonthsCalendarPage> createState() => _FullMonthsCalendarPageState();
}

class _FullMonthsCalendarPageState extends State<FullMonthsCalendarPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  Timer? _idleResetTimer;
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isInitialMonthCurrent =
        widget.initialFocusedMonth.year == today.year &&
            widget.initialFocusedMonth.month == today.month;
    _selectedDate = widget.initialSelectedDate ??
        (isInitialMonthCurrent ? today : null);
    final base = _selectedDate ?? widget.initialFocusedMonth;
    _focusedMonth = DateTime(base.year, base.month, 1);
  }

  @override
  void dispose() {
    _idleResetTimer?.cancel();
    super.dispose();
  }

  void _scheduleIdleReset() {
    _idleResetTimer?.cancel();
    if (_isModalOpen) return;
    _idleResetTimer = Timer(widget.idleResetDuration, _resetToToday);
  }

  void _resetToToday() {
    if (!mounted || _isModalOpen) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonth = DateTime(now.year, now.month, 1);
    final isAlreadyToday = _selectedDate != null &&
        _selectedDate!.year == today.year &&
        _selectedDate!.month == today.month &&
        _selectedDate!.day == today.day &&
        _focusedMonth.year == currentMonth.year &&
        _focusedMonth.month == currentMonth.month;
    if (!isAlreadyToday) {
      setState(() {
        _focusedMonth = currentMonth;
        _selectedDate = today;
      });
    }
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
    _scheduleIdleReset();
  }

  void _selectMonth(int month) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, month, 1);
      final now = DateTime.now();
      if (_focusedMonth.year == now.year && month == now.month) {
        _selectedDate = DateTime(now.year, now.month, now.day);
      } else {
        _selectedDate = null;
      }
    });
    _scheduleIdleReset();
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

        final monthEvents = state.calendarEvents.where((e) {
          if (_selectedDate != null) {
            return e.occursOnDay(_selectedDate!);
          }
          return e.occursInMonth(_focusedMonth.year, _focusedMonth.month);
        }).toList();

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
                  onPressed: () {
                    _isModalOpen = true;
                    _idleResetTimer?.cancel();
                    showAddOrEditEventSheet(
                      context,
                      initialDate: _selectedDate ?? _focusedMonth,
                    );
                    Future.delayed(const Duration(seconds: 2), () {
                      _isModalOpen = false;
                      if (mounted) _scheduleIdleReset();
                    });
                  },
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _scheduleIdleReset(),
            onPointerMove: (_) => _scheduleIdleReset(),
            child: ListView(
              padding: EdgeInsets.all(14.w),
              physics: const BouncingScrollPhysics(),
              children: [
                CalendarMonthSelectorCard(
                  focusedMonth: _focusedMonth,
                  calendarEvents: state.calendarEvents,
                  onChangeMonthDelta: _changeMonth,
                  onSelectMonth: _selectMonth,
                ),
                SizedBox(height: 14.h),
                CalendarMonthDaysGrid(
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  calendarEvents: state.calendarEvents,
                  onDayTapped: (dayDate) {
                    setState(() {
                      final isSame = _selectedDate != null &&
                          _selectedDate!.year == dayDate.year &&
                          _selectedDate!.month == dayDate.month &&
                          _selectedDate!.day == dayDate.day;
                      _selectedDate = isSame ? null : dayDate;
                    });
                    _scheduleIdleReset();
                  },
                ),
              SizedBox(height: 14.h),
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
          ),
        );
      },
    );
  }
}
