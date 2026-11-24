import 'dart:async';

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

/// Aggregates non-empty event locations (both plain text and Google Maps URLs)
/// from [events], ordered by frequency descending then most recent event date.
List<({String location, int count})> popularCalendarLocations(
  List<CalendarEventModel> events, {
  int limit = 10,
}) {
  final counts = <String, int>{};
  final latestAt = <String, DateTime>{};
  final displayByKey = <String, String>{};

  for (final evt in events) {
    final raw = evt.location?.trim() ?? '';
    if (raw.isEmpty) continue;
    final key = raw.toLowerCase();
    counts[key] = (counts[key] ?? 0) + 1;
    displayByKey.putIfAbsent(key, () => raw);
    final prev = latestAt[key];
    if (prev == null || evt.eventDateTime.isAfter(prev)) {
      latestAt[key] = evt.eventDateTime;
      displayByKey[key] = raw;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return latestAt[b.key]!.compareTo(latestAt[a.key]!);
    });

  return sorted
      .take(limit)
      .map((e) => (location: displayByKey[e.key]!, count: e.value))
      .toList();
}

/// Displays a modal bottom sheet for creating or editing a calendar event.
///
/// Features:
/// - Defaults event date/time to current live clock (`DateTime.now()`) until
///   changed by the user.
/// - Dynamic popular locations list ("أو اختر موقعاً سريعاً") aggregated from
///   previously used text venues and Google Maps URLs across all users.
/// - Multi-day Event Toggle and Reminder Date/Time selection.
void showAddOrEditEventSheet(
  BuildContext context, {
  CalendarEventModel? existingEvent,
  DateTime? initialDate,
}) {
  final cubit = context.read<LmtCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider<LmtCubit>.value(
      value: cubit,
      child: _CalendarEventFormBody(
        existingEvent: existingEvent,
        initialDate: initialDate,
      ),
    ),
  );
}

class _CalendarEventFormBody extends StatefulWidget {
  final CalendarEventModel? existingEvent;
  final DateTime? initialDate;

  const _CalendarEventFormBody({
    this.existingEvent,
    this.initialDate,
  });

  @override
  State<_CalendarEventFormBody> createState() => _CalendarEventFormBodyState();
}

class _CalendarEventFormBodyState extends State<_CalendarEventFormBody> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;

  late DateTime _startDate;
  late bool _isMultiDay;
  late DateTime _endDate;
  late DateTime _reminderDate;
  late bool _hasCustomStartDate;
  late bool _hasCustomReminderDate;
  Timer? _liveClockTimer;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _locationCtrl = TextEditingController(text: existing?.location ?? '');

    final now = DateTime.now();
    _hasCustomStartDate = existing != null;
    _hasCustomReminderDate = existing?.reminderDateTime != null;

    if (existing != null) {
      _startDate = existing.eventDateTime;
    } else if (widget.initialDate != null) {
      final d = widget.initialDate!;
      _startDate = (d.hour == 0 && d.minute == 0)
          ? DateTime(d.year, d.month, d.day, now.hour, now.minute)
          : d;
    } else {
      _startDate = now;
    }

    _isMultiDay = existing?.isMultiDay ?? false;
    _endDate = existing?.endDateTime ?? _startDate.add(const Duration(days: 4));
    _reminderDate = existing?.reminderDateTime ??
        _startDate.subtract(const Duration(hours: 2));

    if (!_hasCustomStartDate && widget.initialDate == null) {
      _liveClockTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!mounted || _hasCustomStartDate) return;
        final currentNow = DateTime.now();
        setState(() {
          _startDate = currentNow;
          if (!_hasCustomReminderDate) {
            _reminderDate = currentNow.subtract(const Duration(hours: 2));
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  int _calculatedDays() {
    if (!_isMultiDay) return 1;
    final s = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final e = DateTime(_endDate.year, _endDate.month, _endDate.day);
    final diff = e.difference(s).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  Future<void> _openGoogleMapsForLocation() async {
    final query = _locationCtrl.text.trim();
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

  Future<void> _showGoogleMapsPickerDialog(bool isArabic) async {
    final searchCtrl = TextEditingController(
      text: _locationCtrl.text.trim(),
    );
    final events = context.read<LmtCubit>().state.calendarEvents;
    final popularLocations = popularCalendarLocations(events);

    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final picked = await showDialog<String>(
      context: context,
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
                        ? 'مثال: المسرح الكبير أو رابط الخريطة...'
                        : 'e.g. Theater Hall or Maps link...',
                    prefixIcon: const Icon(Icons.place_rounded),
                    suffixIcon: IconButton(
                      tooltip:
                          isArabic ? 'لصق من الحافظة' : 'Paste from clipboard',
                      icon: const Icon(Icons.content_paste_rounded),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
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
                      ? 'أو اختر موقعاً سريعاً (الأكثر اختياراً من الأعضاء):'
                      : 'Or quick-select a frequently used location:',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 6.h),
                if (popularLocations.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      isArabic
                          ? 'لا توجد مواقع مسجلة بعد — أي موقع (نص أو رابط خريطة) يختاره الأعضاء سيظهر هنا تلقائياً حسب الأكثر استخداماً.'
                          : 'No previous venues saved yet — any location or map link saved by members will appear here ranked by usage.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: textSecondary,
                      ),
                    ),
                  )
                else
                  ...popularLocations.map((entry) {
                    final isLink = entry.location.startsWith('http://') ||
                        entry.location.startsWith('https://');
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isLink
                            ? Icons.map_rounded
                            : Icons.location_on_rounded,
                        color: isLink ? accentGreen : primary,
                        size: 18.sp,
                      ),
                      title: Text(
                        entry.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textPrimary,
                        ),
                      ),
                      trailing: entry.count > 1
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '×${entry.count}',
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => Navigator.pop(dCtx, entry.location),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dCtx, searchCtrl.text.trim()),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(isArabic ? 'حفظ الموقع' : 'Save Location'),
            ),
          ],
        );
      },
    );

    searchCtrl.dispose();
    if (picked != null && mounted) {
      setState(() {
        _locationCtrl.text = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final existingEvent = widget.existingEvent;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 4.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
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
                controller: _titleCtrl,
                onChanged: (_) {
                  if (_validationError != null) {
                    setState(() => _validationError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText:
                      isArabic ? 'عنوان الفعالية (Title)' : 'Event Title',
                  prefixIcon: const Icon(Icons.event_rounded),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الوصف والتفاصيل' : 'Descriptions',
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _locationCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: isArabic
                      ? 'المكان (اختياري • Google Maps 📍)'
                      : 'Location (Optional • Google Maps 📍)',
                  hintText: isArabic
                      ? 'اتركه فارغاً أو حدد موقعاً من خرائط جوجل...'
                      : 'Leave empty or pick from Google Maps...',
                  prefixIcon: IconButton(
                    tooltip:
                        isArabic ? 'فتح Google Maps' : 'Open Google Maps',
                    onPressed: () => _showGoogleMapsPickerDialog(isArabic),
                    icon: Icon(
                      Icons.location_on_rounded,
                      color: accentGreen,
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_locationCtrl.text.trim().isNotEmpty)
                        IconButton(
                          tooltip: isArabic ? 'مسح الموقع' : 'Clear',
                          onPressed: () =>
                              setState(() => _locationCtrl.clear()),
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
                        onPressed: () => _showGoogleMapsPickerDialog(isArabic),
                        icon: Icon(Icons.map_outlined, color: primary),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showGoogleMapsPickerDialog(isArabic),
                      icon: Icon(
                        Icons.pin_drop_rounded,
                        size: 15.sp,
                        color: accentGreen,
                      ),
                      label: Text(
                        isArabic
                            ? 'اختيار موقع من Google Maps 🗺️'
                            : 'Pick from Google Maps 🗺️',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                          color: accentGreen,
                        ),
                      ),
                    ),
                  ),
                  if (_locationCtrl.text.trim().isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Flexible(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _openGoogleMapsForLocation,
                        icon: Icon(
                          Icons.directions_rounded,
                          size: 15.sp,
                          color: primary,
                        ),
                        label: Text(
                          isArabic ? 'عرض على الخريطة' : 'View on Map',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 6.h),
              Material(
                color: primary.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  side: BorderSide(
                    color: _isMultiDay
                        ? primary.withValues(alpha: 0.4)
                        : AppColors.borderOf(context),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
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
                    _isMultiDay
                        ? (isArabic
                            ? 'مدة الفعالية المحددة: ${_calculatedDays()} أيام'
                            : 'Selected duration: ${_calculatedDays()} days')
                        : (isArabic
                            ? 'تفعيل لتحديد تاريخ البداية وتاريخ النهاية'
                            : 'Enable to set Start Date and End Date'),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _isMultiDay ? accentGreen : textSecondary,
                      fontWeight:
                          _isMultiDay ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  value: _isMultiDay,
                  activeTrackColor: primary,
                  onChanged: (val) {
                    setState(() {
                      _isMultiDay = val;
                      if (_isMultiDay && !_endDate.isAfter(_startDate)) {
                        _endDate = _startDate.add(const Duration(days: 4));
                      }
                    });
                  },
                ),
                ),
              ),
              SizedBox(height: 6.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_month_rounded, color: primary),
                title: Text(
                  _isMultiDay
                      ? (isArabic
                          ? 'تاريخ ووقت البداية (Start Date)'
                          : 'Start Date & Time')
                      : (isArabic
                          ? 'تاريخ ووقت الفعالية'
                          : 'Event Date & Time'),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy • hh:mm a').format(_startDate),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (d == null || !context.mounted) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_startDate),
                    );
                    if (t == null || !mounted) return;
                    setState(() {
                      _hasCustomStartDate = true;
                      _liveClockTimer?.cancel();
                      _startDate = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t.hour,
                        t.minute,
                      );
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate.add(const Duration(days: 4));
                      }
                      if (!_hasCustomReminderDate) {
                        _reminderDate =
                            _startDate.subtract(const Duration(hours: 2));
                      }
                    });
                  },
                  child: Text(isArabic ? 'تغيير' : 'Change'),
                ),
              ),
              if (_isMultiDay)
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
                    '${DateFormat('dd/MM/yyyy • hh:mm a').format(_endDate)} (${_calculatedDays()} ${isArabic ? 'أيام' : 'days'})',
                    style: TextStyle(
                      color: accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _endDate.isBefore(_startDate)
                            ? _startDate
                            : _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (d == null || !context.mounted) return;
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_endDate),
                      );
                      if (t == null || !mounted) return;
                      setState(() {
                        _endDate = DateTime(
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(
                  isArabic
                      ? 'تاريخ ووقت التذكير (Reminder)'
                      : 'Reminder Date & Time',
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy • hh:mm a').format(_reminderDate),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _reminderDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (d == null || !context.mounted) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_reminderDate),
                    );
                    if (t == null || !mounted) return;
                    setState(() {
                      _hasCustomReminderDate = true;
                      _reminderDate = DateTime(
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
              if (_validationError != null) ...[
                SizedBox(height: 6.h),
                Text(
                  _validationError!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_titleCtrl.text.trim().isEmpty) {
                      setState(() {
                        _validationError = isArabic
                            ? 'يرجى إدخال عنوان الفعالية أولاً'
                            : 'Please enter an event title first';
                      });
                      return;
                    }
                    final effectiveStart = (!_hasCustomStartDate &&
                            widget.existingEvent == null &&
                            widget.initialDate == null)
                        ? DateTime.now()
                        : _startDate;
                    final effectiveReminder = (!_hasCustomReminderDate &&
                            !_hasCustomStartDate &&
                            widget.existingEvent == null &&
                            widget.initialDate == null)
                        ? effectiveStart.subtract(const Duration(hours: 2))
                        : _reminderDate;
                    final nullableLoc = _locationCtrl.text.trim().isEmpty
                        ? null
                        : _locationCtrl.text.trim();
                    final effectiveEnd = _isMultiDay ? _endDate : null;

                    if (existingEvent == null) {
                      context.read<LmtCubit>().addCalendarEvent(
                            title: _titleCtrl.text,
                            description: _descCtrl.text,
                            eventDateTime: effectiveStart,
                            endDateTime: effectiveEnd,
                            reminderDateTime: effectiveReminder,
                            location: nullableLoc,
                          );
                    } else {
                      context.read<LmtCubit>().updateCalendarEvent(
                            existingEvent.copyWith(
                              title: _titleCtrl.text.trim(),
                              description: _descCtrl.text.trim(),
                              eventDateTime: effectiveStart,
                              endDateTime: effectiveEnd,
                              clearEndDateTime: !_isMultiDay,
                              reminderDateTime: effectiveReminder,
                              location: nullableLoc,
                              clearLocation: nullableLoc == null,
                            ),
                          );
                    }
                    Navigator.pop(context);
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
  }
}
