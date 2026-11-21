import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../cubit/calendar_cubit.dart';
import '../helpers/calendar_date_time_picker.dart';
import '../helpers/calendar_date_utils.dart';

/// Reminder status row of an event card: label, "Set Time" and on/off switch.
class CalendarReminderBar extends StatelessWidget {
  /// Event whose reminder is shown.
  final CalendarEventModel evt;

  /// Accent color used while the reminder is active.
  final Color accentGreen;

  /// Creates a [CalendarReminderBar].
  const CalendarReminderBar({
    super.key,
    required this.evt,
    required this.accentGreen,
  });

  Future<void> _pickCustom(BuildContext context) async {
    final cubit = context.read<LmtCubit>();
    final picked = await pickCalendarDateTime(
      context,
      evt.reminderDateTime ?? evt.eventDateTime,
    );
    if (picked == null) return;
    await cubit.toggleEventReminder(evt.id, customReminderTime: picked);
    if (!context.mounted) return;
    showReminderSetSnackBar(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = CalendarDateUtils.isArabic(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final active = evt.isReminderActive;
    final color = active ? accentGreen : textSecondary;
    final label = active && evt.reminderDateTime != null
        ? '${isArabic ? 'التذكير مفعل:' : 'Reminder set:'} '
            '${CalendarDateUtils.format(context, 'dd/MM hh:mm a', evt.reminderDateTime!)}'
        : (isArabic ? 'التذكير غير مفعل لهذا الحدث' : 'Reminder disabled');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: active
            ? accentGreen.withValues(alpha: 0.1)
            : AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: active
              ? accentGreen.withValues(alpha: 0.45)
              : AppColors.borderOf(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            active
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_outlined,
            size: 18.sp,
            color: color,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: Size(48.w, 48.h)),
            onPressed: () => _pickCustom(context),
            child: Text(
              isArabic ? 'ضبط التذكير' : 'Set Time',
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
          Tooltip(
            message: isArabic ? 'تفعيل/إيقاف التذكير' : 'Toggle reminder',
            child: Switch(
              value: active,
              activeTrackColor: accentGreen,
              onChanged: (_) =>
                  context.read<LmtCubit>().toggleEventReminder(evt.id),
            ),
          ),
        ],
      ),
    );
  }
}
