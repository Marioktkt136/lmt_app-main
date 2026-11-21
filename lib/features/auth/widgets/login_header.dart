import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';

/// Logo, title and subtitle shown above the login form.
class LoginHeader extends StatelessWidget {
  /// Creates the header.
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120.h,
          child: Image.asset(AppAssets.appLogo, fit: BoxFit.contain),
        ),
        SizedBox(height: 10.h),
        Text(
          'login_title'.tr(),
          textAlign: TextAlign.center,
          style: AppTypography.h2
              .copyWith(color: AppColors.textPrimaryOf(context)),
        ),
        SizedBox(height: 4.h),
        Text(
          'login_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primaryOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
