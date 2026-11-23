import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../cubit/calendar_cubit.dart';
import '../widgets/calendar_days_strip.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/calendar_event_details_sheet.dart';
import '../widgets/calendar_event_form_sheet.dart';
import '../widgets/full_calendar_launcher_card.dart';
import 'full_months_calendar_page.dart';

/// Main Calendar View displaying the quick horizontal days strip,
/// the [FullCalendarLauncherCard], and scheduled team events.
class CalendarScreen extends StatefulWidget {
  /// Duration of inactivity after which the calendar automatically resets to
  /// Today and the current month.
  final Duration idleResetDuration;

  /// Creates a [CalendarScreen].
  const CalendarScreen({
    super.key,
    this.idleResetDuration = const Duration(seconds: 15),
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _selectedDateFilter;
  DateTime? _selectedMonthFilter;
  Timer? _idleResetTimer;
  bool _isModalOrSubpageOpen = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateFilter = DateTime(now.year, now.month, now.day);
    _selectedMonthFilter = DateTime(now.year, now.month, 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<LmtCubit>();
      final targetEventId = cubit.state.selectedCalendarEventId;
      if (targetEventId != null) {
        _openTargetedEvent(cubit.state, targetEventId);
      }
    });
  }

  @override
  void dispose() {
    _idleResetTimer?.cancel();
    super.dispose();
  }

  void _scheduleIdleReset() {
    _idleResetTimer?.cancel();
    if (_isModalOrSubpageOpen) return;
    _idleResetTimer = Timer(widget.idleResetDuration, _resetToToday);
  }

  void _resetToToday() {
    if (!mounted || _isModalOrSubpageOpen) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonth = DateTime(now.year, now.month, 1);
    final isAlreadyToday = _selectedDateFilter != null &&
        _selectedDateFilter!.year == today.year &&
        _selectedDateFilter!.month == today.month &&
        _selectedDateFilter!.day == today.day &&
        _selectedMonthFilter != null &&
        _selectedMonthFilter!.year == currentMonth.year &&
        _selectedMonthFilter!.month == currentMonth.month;
    if (!isAlreadyToday) {
      setState(() {
        _selectedDateFilter = today;
        _selectedMonthFilter = currentMonth;
      });
    }
  }

  void _openTargetedEvent(LmtState state, String eventId) {
    final evt =
        state.calendarEvents.where((e) => e.id == eventId).firstOrNull;
    context.read<LmtCubit>().clearSelectedCalendarEvent();
    if (evt != null && mounted) {
      setState(() {
        _selectedDateFilter = null;
        _selectedMonthFilter = null;
      });
      _idleResetTimer?.cancel();
      showCalendarEventDetailsSheet(context, evt);
    }
  }

  Future<void> _openFullCalendarPage(BuildContext context) async {
    _isModalOrSubpageOpen = true;
    _idleResetTimer?.cancel();
    final result = await Navigator.push<Map<String, DateTime?>>(
      context,
      MaterialPageRoute(
        builder: (_) => FullMonthsCalendarPage(
          initialSelectedDate: _selectedDateFilter,
          initialFocusedMonth: _selectedMonthFilter ?? DateTime.now(),
        ),
      ),
    );
    _isModalOrSubpageOpen = false;

    if (result != null && mounted) {
      setState(() {
        _selectedDateFilter = result['date'];
        _selectedMonthFilter = result['month'];
      });
    }
    if (mounted) _scheduleIdleReset();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LmtCubit, LmtState>(
      listenWhen: (prev, curr) =>
          curr.selectedCalendarEventId != null &&
          prev.selectedCalendarEventId != curr.selectedCalendarEventId,
      listener: (context, state) {
        final targetId = state.selectedCalendarEventId;
        if (targetId != null) {
          _openTargetedEvent(state, targetId);
        }
      },
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final primary = AppColors.primaryOf(context);
        final accentGreen = AppColors.accentGreenOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);
        final canManageCalendar = state.currentUser.role.canManageCalendar;

        final now = DateTime.now();
        final upcomingDays = List.generate(
          14,
          (i) => DateTime(now.year, now.month, now.day + i),
        );

        final filteredEvents = state.calendarEvents.where((evt) {
          if (_selectedDateFilter != null) {
            return evt.occursOnDay(_selectedDateFilter!);
          }
          if (_selectedMonthFilter != null) {
            return evt.occursInMonth(
              _selectedMonthFilter!.year,
              _selectedMonthFilter!.month,
            );
          }
          return true;
        }).toList();

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _scheduleIdleReset(),
          onPointerMove: (_) => _scheduleIdleReset(),
          child: AdaptiveContentBox(
            maxWidth: AdaptiveBreakpoints.wideDesktopMaxWidth,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            CalendarDaysStrip(
              upcomingDays: upcomingDays,
              selectedDateFilter: _selectedDateFilter,
              selectedMonthFilter: _selectedMonthFilter,
              calendarEvents: state.calendarEvents,
              onSelectAll: () {
                setState(() {
                  _selectedDateFilter = null;
                  _selectedMonthFilter = null;
                });
                _scheduleIdleReset();
              },
              onSelectDay: (day) {
                setState(() {
                  _selectedDateFilter = day;
                  _selectedMonthFilter = DateTime(day.year, day.month, 1);
                });
                _scheduleIdleReset();
              },
            ),
            SizedBox(height: 10.h),
            FullCalendarLauncherCard(
              activeFilterLabel: _activeFilterLabel(isArabic),
              hasActiveFilter:
                  _selectedDateFilter != null || _selectedMonthFilter != null,
              onOpenFullCalendar: () => _openFullCalendarPage(context),
              onClearFilter: () {
                setState(() {
                  _selectedDateFilter = null;
                  _selectedMonthFilter = null;
                });
                _scheduleIdleReset();
              },
            ),
            SizedBox(height: 12.h),
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
                  : LayoutBuilder(
                      builder: (context, listConstraints) {
                        if (listConstraints.maxWidth >= 820) {
                          final rowCount = (filteredEvents.length + 1) ~/ 2;
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 4.h,
                            ),
                            itemCount: rowCount,
                            itemBuilder: (context, rowIndex) {
                              final leftIdx = rowIndex * 2;
                              final rightIdx = leftIdx + 1;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: CalendarEventCard(
                                      evt: filteredEvents[leftIdx],
                                      canManageCalendar: canManageCalendar,
                                      accentGreen: accentGreen,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: rightIdx < filteredEvents.length
                                        ? CalendarEventCard(
                                            evt: filteredEvents[rightIdx],
                                            canManageCalendar:
                                                canManageCalendar,
                                            accentGreen: accentGreen,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        return ListView.builder(
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
                        );
                      },
                    ),
            ),
          ],
        ),
        ),
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
