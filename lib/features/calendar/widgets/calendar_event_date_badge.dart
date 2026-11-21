import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../helpers/calendar_date_utils.dart';

/// Gradient month/day badge shown at the start of an event card.
class CalendarEventDateBadge extends StatelessWidget {
  /// Event date to display.
  final DateTime date;

  /// Creates a [CalendarEventDateBadge].
  const CalendarEventDateBadge({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    return Container(
      constraints: BoxConstraints(minWidth: 52.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: AppColors.cardShadows(context, accent: primary, intensity: 0.7),
      ),
      child: Column(
        children: [
          Text(
            CalendarDateUtils.format(context, 'MMM', date).toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
