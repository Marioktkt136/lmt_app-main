import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import 'calendar_date_utils.dart';

/// Opens a date picker followed by a time picker and returns the result.
///
/// Returns `null` when the user cancels either step. Used by the event form
/// and the reminder bar so the logic exists once.
Future<DateTime?> pickCalendarDateTime(
  BuildContext context,
  DateTime initial,
) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(const Duration(days: 1)),
    lastDate: DateTime.now().add(const Duration(days: 730)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Shows the "reminder set" confirmation snackbar.
void showReminderSetSnackBar(BuildContext context, DateTime when) {
  final text = CalendarDateUtils.format(context, 'dd/MM/yyyy hh:mm a', when);
  final isArabic = CalendarDateUtils.isArabic(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? 'تم ضبط التذكير ليوم $text 🔔' : 'Reminder set for $text 🔔',
        ),
        backgroundColor: AppColors.accentGreenOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
