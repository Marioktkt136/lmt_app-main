import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'calendar_event_date_badge.dart';
import 'calendar_event_meta.dart';
import 'calendar_reminder_bar.dart';

/// Displays a dedicated modal bottom sheet with full details and actions for
/// a specific [CalendarEventModel] (used when navigating from a Calendar
/// notification or reminder).
void showCalendarEventDetailsSheet(
  BuildContext context,
  CalendarEventModel evt,
) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final primary = AppColors.primaryOf(context);
  final accentGreen = AppColors.accentGreenOf(context);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CalendarEventDateBadge(date: evt.eventDateTime),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          evt.category,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        evt.title,
                        style: AppTypography.h5.copyWith(
                          color: AppColors.textPrimaryOf(ctx),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (evt.description.trim().isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                evt.description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondaryOf(ctx),
                  height: 1.45,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Divider(color: AppColors.borderOf(ctx), height: 1),
            SizedBox(height: 10.h),
            CalendarEventMeta(evt: evt),
            SizedBox(height: 12.h),
            CalendarReminderBar(evt: evt, accentGreen: accentGreen),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isArabic ? 'إغلاق' : 'Close'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
