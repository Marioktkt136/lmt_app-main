import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/colors.dart';

/// Global reusable empty state placeholder widget.
class LmtEmptyState extends StatelessWidget {
  /// The illustrative icon to display.
  final IconData icon;

  /// The descriptive message text.
  final String message;

  /// Optional action widget (such as a reset or create button).
  final Widget? action;

  /// Creates an [LmtEmptyState].
  const LmtEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = AppColors.textSecondaryOf(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44.sp, color: textSecondary),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13.sp),
            ),
            if (action != null) ...[
              SizedBox(height: 10.h),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
