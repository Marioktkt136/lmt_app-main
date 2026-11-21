import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../helpers/calendar_date_utils.dart';

/// Date/time and location line of an event card.
class CalendarEventMeta extends StatelessWidget {
  /// Event to describe.
  final CalendarEventModel evt;

  /// Creates a [CalendarEventMeta].
  const CalendarEventMeta({super.key, required this.evt});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11.5.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryOf(context),
    );
    return Wrap(
      spacing: 12.w,
      runSpacing: 6.h,
      children: [
        _item(
          Icons.access_time_filled_rounded,
          AppColors.primaryOf(context),
          CalendarDateUtils.format(
            context,
            'EEE, dd/MM/yyyy • hh:mm a',
            evt.eventDateTime,
          ),
          style,
        ),
        if (evt.location.trim().isNotEmpty)
          _item(Icons.location_on_rounded, AppColors.error, evt.location, style),
      ],
    );
  }

  Widget _item(IconData icon, Color color, String text, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15.sp, color: color),
        SizedBox(width: 4.w),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
