import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';

/// Small green pill showing one attendee's number and name.
class KhelwaAttendeeChip extends StatelessWidget {
  /// 1-based position in today's list.
  final int index;

  /// Attendee display name.
  final String name;

  /// Creates a [KhelwaAttendeeChip].
  const KhelwaAttendeeChip({super.key, required this.index, required this.name});

  @override
  Widget build(BuildContext context) {
    final accentGreen = AppColors.accentGreenOf(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: accentGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accentGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: accentGreen, size: 15.sp),
          SizedBox(width: 5.w),
          Text(
            '$index. $name',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
