import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_card.dart';
import 'calendar_event_date_badge.dart';
import 'calendar_event_menu.dart';
import 'calendar_event_meta.dart';
import 'calendar_reminder_bar.dart';

/// Displays an individual calendar event card with reminder controls.
///
/// Composes [CalendarEventDateBadge], [CalendarEventMenu],
/// [CalendarEventMeta] and [CalendarReminderBar].
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
    return LmtCard(
      margin: EdgeInsets.only(bottom: 14.h),
      borderRadius: 20.r,
      accentColor: AppColors.primaryOf(context),
      child: Column(
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
                    Text(
                      evt.title,
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (evt.description.trim().isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        evt.description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondaryOf(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManageCalendar) CalendarEventMenu(evt: evt),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(color: AppColors.borderOf(context), height: 1),
          SizedBox(height: 8.h),
          CalendarEventMeta(evt: evt),
          SizedBox(height: 8.h),
          CalendarReminderBar(evt: evt, accentGreen: accentGreen),
        ],
      ),
    );
  }
}
