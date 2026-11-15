
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/theme/typography.dart';

class PostTypeTabs extends StatelessWidget {
  const PostTypeTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        children: const [
          Expanded(
            child: PostTypeTab(
              icon: Icons.article_outlined,
              label: 'منشور',
              isSelected: false,
            ),
          ),
          Expanded(
            child: PostTypeTab(
              icon: Icons.image_outlined,
              label: 'صورة',
              isSelected: true,
            ),
          ),
          Expanded(
            child: PostTypeTab(
              icon: Icons.poll_outlined,
              label: 'تصويت',
              isSelected: false,
            ),
          ),
        ],
      ),
    );
  }
}

class PostTypeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const PostTypeTab({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
