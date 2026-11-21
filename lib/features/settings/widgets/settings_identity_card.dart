import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';

/// App identity header card displayed at the top of [SettingsScreen].
class SettingsIdentityCard extends StatelessWidget {
  /// The active slogan of the year.
  final String sloganOfYear;

  /// Creates a [SettingsIdentityCard].
  const SettingsIdentityCard({
    super.key,
    required this.sloganOfYear,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: AppColors.cardDecoration(
        context,
        radius: 22.r,
        accentColor: primary,
      ),
      child: Row(
        children: [
          Image.asset(AppAssets.appLogo, width: 64.w, height: 64.w),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Last Message Team',
                  style: AppTypography.h5.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'فريق الرسالة الاخيرة • L.M.T',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '🎭 Act, Drama & Theater • $sloganOfYear',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
