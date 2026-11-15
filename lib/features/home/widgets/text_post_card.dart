import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/theme/typography.dart';
import 'package:lmt/core/utils/app_assets.dart';
import 'package:lmt/features/home/widgets/post_bottom.dart';
import 'package:lmt/features/home/widgets/post_header.dart';

class TextPostCard extends StatelessWidget {
  const TextPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.backgroundDark.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostHeader(name: 'Samy Farouk', timeAgo: 'منذ 3 أيام', avatarPath: AppAssets.accountIcon),
          SizedBox(height: 8.h),
          Text(
            'مستنينيكم يوم الأثنين الجاي الساعة ٦ ونص\nهيكون عندنا قاعدة فنية ما تتأخروش',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 12.h),
          PostBottom(),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Icon(
          //       Icons.favorite_rounded,
          //       size: 20.sp,
          //       color: AppColors.error,
          //     ),
          //     Icon(
          //       Icons.insert_comment_outlined,
          //       size: 20.sp,
          //       color: AppColors.textSecondary,
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
