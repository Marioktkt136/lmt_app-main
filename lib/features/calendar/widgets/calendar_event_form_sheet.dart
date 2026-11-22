import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../cubit/calendar_cubit.dart';

/// Displays a modal bottom sheet for creating or editing a calendar event.
///
/// Features:
/// - Multi-day Event Toggle (opens Start Date & End Date pickers, e.g., for a 5-day trip).
/// - Nullable Location field integrated with Google Maps (opens Google Maps to
///   search/pin a venue, paste a copied Maps address/URL, or pick a saved location).
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
    text: existingEvent?.location ?? '',
  );

  DateTime startDate = existingEvent?.eventDateTime ??
      initialDate ??
      DateTime.now().add(const Duration(days: 2));
  bool isMultiDay = existingEvent?.isMultiDay ?? false;
  DateTime endDate = existingEvent?.endDateTime ??
      startDate.add(const Duration(days: 4));
  DateTime reminderDate = existingEvent?.reminderDateTime ??
      startDate.subtract(const Duration(hours: 2));

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final primary = AppColors.primaryOf(ctx);
          final accentGreen = AppColors.accentGreenOf(ctx);
          final textPrimary = AppColors.textPrimaryOf(ctx);
          final textSecondary = AppColors.textSecondaryOf(ctx);

          int calculatedDays() {
            if (!isMultiDay) return 1;
            final s = DateTime(startDate.year, startDate.month, startDate.day);
            final e = DateTime(endDate.year, endDate.month, endDate.day);
            final diff = e.difference(s).inDays + 1;
            return diff < 1 ? 1 : diff;
          }

          Future<void> openGoogleMapsForLocation() async {
            final query = locationCtrl.text.trim();
            final urlStr = query.isEmpty
                ? 'https://www.google.com/maps'
                : (query.startsWith('http://') || query.startsWith('https://')
                    ? query
                    : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
            final uri = Uri.parse(urlStr);
            try {
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
            } catch (_) {}
          }

          Future<void> showGoogleMapsPickerDialog() async {
            final searchCtrl = TextEditingController(
              text: locationCtrl.text.trim(),
            );
            final suggestedLocations = [
              'قاعة المسرح الرئيسية - القاهرة',
              'بيت الخلوة والمؤتمرات - وادي النطرون',
              'جمعية عين شمس - القاعة الكبرى',
              'المسرح الكبير - وسط البلد، القاهرة',
              'بيت مؤتمرات الأسكندرية - أبي قير',
            ];

            final picked = await showDialog<String>(
              context: ctx,
              builder: (dCtx) {
                return AlertDialog(
                  backgroundColor: AppColors.surfaceOf(dCtx),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.map_rounded, color: accentGreen, size: 24.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'تحديد الموقع عبر Google Maps 🗺️'
                              : 'Select Location with Google Maps 🗺️',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            labelText: isArabic
                                ? 'ابحث عن مكان أو الصق رابط Google Maps'
                                : 'Enter place or paste Google Maps link',
                            hintText: isArabic
                                ? 'مثال: وادي النطرون أو رابط الخريطة...'
                                : 'e.g. Theater Hall or Maps link...',
                            prefixIcon: const Icon(Icons.place_rounded),
                            suffixIcon: IconButton(
                              tooltip: isArabic
                                  ? 'لصق من الحافظة'
                                  : 'Paste from clipboard',
                              icon: const Icon(Icons.content_paste_rounded),
                              onPressed: () async {
                                final data =
                                    await Clipboard.getData('text/plain');
                                if (data?.text != null &&
                                    data!.text!.trim().isNotEmpty) {
                                  searchCtrl.text = data.text!.trim();
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentGreen,
                              side: BorderSide(color: accentGreen, width: 1.4),
                            ),
                            onPressed: () async {
                              final q = searchCtrl.text.trim();
                              final url = q.isEmpty
                                  ? 'https://www.google.com/maps'
                                  : (q.startsWith('http')
                                      ? q
                                      : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}');
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: Text(
                              isArabic
                                  ? 'فتح خرائط جوجل (Google Maps) 🗺️'
                                  : 'Open Google Maps App 🗺️',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          isArabic
                              ? 'أو اختر موقعاً سريعاً:'
                              : 'Or quick-select a venue:',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        ...suggestedLocations.map(
                          (loc) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.location_on_rounded,
                              color: primary,
                              size: 18.sp,
                            ),
                            title: Text(
                              loc,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: textPrimary,
                              ),
                            ),
                            onTap: () => Navigator.pop(dCtx, loc),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx),
                      child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(dCtx, searchCtrl.text.trim()),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isArabic ? 'حفظ الموقع' : 'Save Location',
                      ),
                    ),
                  ],
                );
              },
            );

            if (picked != null) {
              setModalState(() {
                locationCtrl.text = picked;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 4.h,
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

                    // Nullable Location Field Integrated with Google Maps
                    TextField(
                      controller: locationCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'المكان (اختياري • Google Maps 📍)'
                            : 'Location (Optional • Google Maps 📍)',
                        hintText: isArabic
                            ? 'اتركه فارغاً أو حدد موقعاً من خرائط جوجل...'
                            : 'Leave empty or pick from Google Maps...',
                        prefixIcon: IconButton(
                          tooltip: isArabic
                              ? 'فتح Google Maps'
                              : 'Open Google Maps',
                          onPressed: showGoogleMapsPickerDialog,
                          icon: Icon(
                            Icons.location_on_rounded,
                            color: accentGreen,
                          ),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (locationCtrl.text.trim().isNotEmpty)
                              IconButton(
                                tooltip: isArabic ? 'مسح الموقع' : 'Clear',
                                onPressed: () => setModalState(
                                  () => locationCtrl.clear(),
                                ),
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18.sp,
                                  color: textSecondary,
                                ),
                              ),
                            IconButton(
                              tooltip: isArabic
                                  ? 'اختيار / فتح في Google Maps'
                                  : 'Pick / Open in Google Maps',
                              onPressed: showGoogleMapsPickerDialog,
                              icon: Icon(
                                Icons.map_outlined,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: showGoogleMapsPickerDialog,
                          icon: Icon(
                            Icons.pin_drop_rounded,
                            size: 15.sp,
                            color: accentGreen,
                          ),
                          label: Text(
                            isArabic
                                ? 'اختيار موقع من Google Maps 🗺️'
                                : 'Pick from Google Maps 🗺️',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.bold,
                              color: accentGreen,
                            ),
                          ),
                        ),
                        if (locationCtrl.text.trim().isNotEmpty) ...[
                          const Spacer(),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: openGoogleMapsForLocation,
                            icon: Icon(
                              Icons.directions_rounded,
                              size: 15.sp,
                              color: primary,
                            ),
                            label: Text(
                              isArabic ? 'عرض على الخريطة' : 'View on Map',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6.h),

                    // Multi-Day Event Toggle (e.g., 5-day Trip)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isMultiDay
                              ? primary.withValues(alpha: 0.4)
                              : AppColors.borderOf(ctx),
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          isArabic
                              ? 'فعالية لعدة أيام (مثل رحلة أو مؤتمر) 🏕️'
                              : 'Multi-day Event (e.g. 5-day Trip) 🏕️',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          isMultiDay
                              ? (isArabic
                                  ? 'مدة الفعالية المحددة: ${calculatedDays()} أيام'
                                  : 'Selected duration: ${calculatedDays()} days')
                              : (isArabic
                                  ? 'تفعيل لتحديد تاريخ البداية وتاريخ النهاية'
                                  : 'Enable to set Start Date and End Date'),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isMultiDay ? accentGreen : textSecondary,
                            fontWeight: isMultiDay
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        value: isMultiDay,
                        activeTrackColor: primary,
                        onChanged: (val) {
                          setModalState(() {
                            isMultiDay = val;
                            if (isMultiDay && !endDate.isAfter(startDate)) {
                              endDate = startDate.add(const Duration(days: 4));
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Start Date & Time (or Single Event Date & Time)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.calendar_month_rounded,
                        color: primary,
                      ),
                      title: Text(
                        isMultiDay
                            ? (isArabic
                                ? 'تاريخ ووقت البداية (Start Date)'
                                : 'Start Date & Time')
                            : (isArabic
                                ? 'تاريخ ووقت الفعالية'
                                : 'Event Date & Time'),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy • hh:mm a').format(startDate),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: startDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 730)),
                          );
                          if (d == null || !ctx.mounted) return;
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(startDate),
                          );
                          if (t == null) return;
                          setModalState(() {
                            startDate = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              t.hour,
                              t.minute,
                            );
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate.add(const Duration(days: 4));
                            }
                            reminderDate =
                                startDate.subtract(const Duration(hours: 2));
                          });
                        },
                        child: Text(isArabic ? 'تغيير' : 'Change'),
                      ),
                    ),

                    // End Date & Time (Shown when Multi-Day toggle is enabled)
                    if (isMultiDay)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.event_available_rounded,
                          color: accentGreen,
                        ),
                        title: Text(
                          isArabic
                              ? 'تاريخ ووقت النهاية (End Date)'
                              : 'End Date & Time',
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy • hh:mm a').format(endDate)} (${calculatedDays()} ${isArabic ? 'أيام' : 'days'})',
                          style: TextStyle(
                            color: accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate:
                                  endDate.isBefore(startDate) ? startDate : endDate,
                              firstDate: startDate,
                              lastDate:
                                  DateTime.now().add(const Duration(days: 730)),
                            );
                            if (d == null || !ctx.mounted) return;
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(endDate),
                            );
                            if (t == null) return;
                            setModalState(() {
                              endDate = DateTime(
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

                    // Reminder Date & Time
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
                          final nullableLoc = locationCtrl.text.trim().isEmpty
                              ? null
                              : locationCtrl.text.trim();
                          final effectiveEnd = isMultiDay ? endDate : null;

                          if (existingEvent == null) {
                            context.read<LmtCubit>().addCalendarEvent(
                                  title: titleCtrl.text,
                                  description: descCtrl.text,
                                  eventDateTime: startDate,
                                  endDateTime: effectiveEnd,
                                  reminderDateTime: reminderDate,
                                  location: nullableLoc,
                                );
                          } else {
                            context.read<LmtCubit>().updateCalendarEvent(
                                  existingEvent.copyWith(
                                    title: titleCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    eventDateTime: startDate,
                                    endDateTime: effectiveEnd,
                                    clearEndDateTime: !isMultiDay,
                                    reminderDateTime: reminderDate,
                                    location: nullableLoc,
                                    clearLocation: nullableLoc == null,
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
