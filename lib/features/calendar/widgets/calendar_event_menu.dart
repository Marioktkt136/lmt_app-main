import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../cubit/calendar_cubit.dart';
import '../helpers/calendar_date_utils.dart';
import 'calendar_event_form_sheet.dart';

/// Edit / delete popup menu for an event card (managers only).
///
/// Deleting asks for confirmation first to avoid accidental data loss.
class CalendarEventMenu extends StatelessWidget {
  /// Event the menu acts on.
  final CalendarEventModel evt;

  /// Creates a [CalendarEventMenu].
  const CalendarEventMenu({super.key, required this.evt});

  Future<void> _confirmDelete(BuildContext context) async {
    final isArabic = CalendarDateUtils.isArabic(context);
    final cubit = context.read<LmtCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'حذف الفعالية؟' : 'Delete event?'),
        content: Text(evt.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await cubit.deleteCalendarEvent(evt.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'تم حذف الفعالية' : 'Event deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = CalendarDateUtils.isArabic(context);
    return PopupMenuButton<String>(
      tooltip: isArabic ? 'خيارات الفعالية' : 'Event options',
      onSelected: (val) {
        if (val == 'edit') {
          showAddOrEditEventSheet(context, existingEvent: evt);
        } else if (val == 'delete') {
          _confirmDelete(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Text(isArabic ? 'تعديل الفعالية' : 'Edit Event'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            isArabic ? 'حذف الفعالية' : 'Delete Event',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
