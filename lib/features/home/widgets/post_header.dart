import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/theme/typography.dart';

class PostHeader extends StatelessWidget {
  final String name;
  final String timeAgo;
  final String avatarPath;

  const PostHeader({
    super.key,
    required this.name,
    required this.timeAgo,
    required this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18.r,
          backgroundImage: AssetImage(avatarPath),
          backgroundColor: AppColors.background,
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary)),
            Text(timeAgo, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const Spacer(),
        Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
      ],
    );
  }
}
