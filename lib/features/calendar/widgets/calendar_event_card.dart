import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/calendar_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_card.dart';
import 'calendar_event_form_sheet.dart';

/// Displays an individual calendar event card with reminder scheduling controls.
class CalendarEventCard extends StatelessWidget {
  /// The calendar event model to render.
  final CalendarEventModel evt;

  /// Whether the current user has permission to edit or delete events.
  final bool canManageCalendar;

  /// The accent green color for active reminder badges.
  final Color accentGreen;

  /// Creates a [CalendarEventCard].
  const CalendarEventCard({
    super.key,
    required this.evt,
    required this.canManageCalendar,
    required this.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    return LmtCard(
      margin: EdgeInsets.only(bottom: 14.h),
      borderRadius: 20.r,
      accentColor: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: AppColors.cardShadows(
                    context,
                    accent: primary,
                    intensity: 0.7,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM')
                          .format(evt.eventDateTime)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${evt.eventDateTime.day}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evt.title,
                      style: AppTypography.h6.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      evt.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManageCalendar)
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') {
                      showAddOrEditEventSheet(
                        context,
                        existingEvent: evt,
                      );
                    } else if (val == 'delete') {
                      context.read<LmtCubit>().deleteCalendarEvent(evt.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        isArabic ? 'تعديل الفعالية' : 'Edit Event',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        isArabic ? 'حذف الفعالية' : 'Delete Event',
                        style: const TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(color: border, height: 1),
          SizedBox(height: 8.h),

          // Date & Time + Location
          Wrap(
            spacing: 12.w,
            runSpacing: 6.h,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 15.sp,
                    color: primary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    DateFormat('EEE, dd/MM/yyyy • hh:mm a')
                        .format(evt.eventDateTime),
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 15,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    evt.location,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Reminder Setting Bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: evt.isReminderActive
                  ? accentGreen.withValues(alpha: 0.1)
                  : AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: evt.isReminderActive
                    ? accentGreen.withValues(alpha: 0.45)
                    : border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  evt.isReminderActive
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  size: 18.sp,
                  color: evt.isReminderActive ? accentGreen : textSecondary,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    evt.isReminderActive && evt.reminderDateTime != null
                        ? '${isArabic ? 'التذكير مفعل:' : 'Reminder set:'} ${DateFormat('dd/MM hh:mm a').format(evt.reminderDateTime!)}'
                        : (isArabic
                            ? 'التذكير غير مفعل لهذا الحدث'
                            : 'Reminder disabled'),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          evt.isReminderActive ? accentGreen : textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _pickCustomReminderDateTime(context, evt),
                  child: Text(
                    isArabic ? 'ضبط التذكير' : 'Set Time',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                ),
                Switch(
                  value: evt.isReminderActive,
                  activeTrackColor: accentGreen,
                  onChanged: (_) =>
                      context.read<LmtCubit>().toggleEventReminder(evt.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomReminderDateTime(
    BuildContext context,
    CalendarEventModel event,
  ) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final initialDate = event.reminderDateTime ?? event.eventDateTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !context.mounted) return;

    final customReminder = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await context.read<LmtCubit>().toggleEventReminder(
          event.id,
          customReminderTime: customReminder,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم ضبط التذكير ليوم ${DateFormat('dd/MM/yyyy hh:mm a').format(customReminder)} 🔔'
              : 'Reminder set for ${DateFormat('dd/MM/yyyy hh:mm a').format(customReminder)} 🔔',
        ),
        backgroundColor: AppColors.accentGreenOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
