import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/calendar_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Displays a modal bottom sheet for creating or editing a calendar event.
void showAddOrEditEventSheet(
  BuildContext context, {
  CalendarEventModel? existingEvent,
  DateTime? initialDate,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final titleCtrl = TextEditingController(text: existingEvent?.title ?? '');
  final descCtrl =
      TextEditingController(text: existingEvent?.description ?? '');
  final locationCtrl = TextEditingController(
    text: existingEvent?.location ?? 'قاعة المسرح الرئيسية',
  );
  DateTime eventDate = existingEvent?.eventDateTime ??
      initialDate ??
      DateTime.now().add(const Duration(days: 2));
  DateTime reminderDate = existingEvent?.reminderDateTime ??
      eventDate.subtract(const Duration(hours: 2));

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final textPrimary = AppColors.textPrimaryOf(ctx);

          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 18.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            ),
            child: SingleChildScrollView(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingEvent == null
                          ? (isArabic
                              ? 'إضافة فعالية أو بروفة للتقويم 🗓️'
                              : 'Add Calendar Event 🗓️')
                          : (isArabic
                              ? 'تعديل الفعالية ✏️'
                              : 'Update Calendar Event ✏️'),
                      style: AppTypography.h4.copyWith(color: textPrimary),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText:
                            isArabic ? 'عنوان الفعالية (Title)' : 'Event Title',
                        prefixIcon: const Icon(Icons.event_rounded),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText:
                            isArabic ? 'الوصف والتفاصيل' : 'Descriptions',
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: locationCtrl,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'المكان (Location)' : 'Location',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_rounded),
                      title: Text(
                        isArabic
                            ? 'تاريخ ووقت الفعالية'
                            : 'Event Date & Time',
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy • hh:mm a').format(eventDate),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: eventDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 730)),
                          );
                          if (d == null || !ctx.mounted) return;
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(eventDate),
                          );
                          if (t == null) return;
                          setModalState(() {
                            eventDate = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              t.hour,
                              t.minute,
                            );
                            reminderDate =
                                eventDate.subtract(const Duration(hours: 2));
                          });
                        },
                        child: Text(isArabic ? 'تغيير' : 'Change'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: Text(
                        isArabic
                            ? 'تاريخ ووقت التذكير (Reminder)'
                            : 'Reminder Date & Time',
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy • hh:mm a').format(reminderDate),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: reminderDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 730)),
                          );
                          if (d == null || !ctx.mounted) return;
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(reminderDate),
                          );
                          if (t == null) return;
                          setModalState(() {
                            reminderDate = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              t.hour,
                              t.minute,
                            );
                          });
                        },
                        child: Text(isArabic ? 'تغيير' : 'Change'),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty) return;
                          if (existingEvent == null) {
                            context.read<LmtCubit>().addCalendarEvent(
                                  title: titleCtrl.text,
                                  description: descCtrl.text,
                                  eventDateTime: eventDate,
                                  reminderDateTime: reminderDate,
                                  location: locationCtrl.text,
                                );
                          } else {
                            context.read<LmtCubit>().updateCalendarEvent(
                                  existingEvent.copyWith(
                                    title: titleCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    eventDateTime: eventDate,
                                    reminderDateTime: reminderDate,
                                    location: locationCtrl.text.trim(),
                                  ),
                                );
                          }
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          existingEvent == null
                              ? (isArabic ? 'حفظ الفعالية' : 'Save Event')
                              : (isArabic ? 'حفظ التعديلات' : 'Update Event'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
