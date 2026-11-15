import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/theme/typography.dart';
import 'package:lmt/core/utils/app_assets.dart';

class HeaderBanner extends StatelessWidget {
  const HeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(
          width: 70.w,
          height: 70.h,
          child: Image.asset(AppAssets.appLogo),
        ),
        Text(
          'تغيروا_2026',
          style: AppTypography.h1Finger.copyWith(color: AppColors.primary),
        ),
        SizedBox(
          width: 45.w,
          height: 45.h,
          child: Image.asset(AppAssets.hashtageIcon),
        ),
      ],
    );
  }
}
