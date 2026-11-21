import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/lmt_cubit.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/app_assets.dart';

class HeaderBanner extends StatelessWidget {
  const HeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isDark = AppColors.isDark(context);
        final primary = AppColors.primaryOf(context);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: 65.w,
              height: 65.h,
              child: Image.asset(AppAssets.appLogo, fit: BoxFit.contain),
            ),
            Expanded(
              child: Text(
                state.sloganOfYear.replaceAll('#', ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.h1Finger.copyWith(
                  color: primary,
                ),
              ),
            ),
            SizedBox(
              width: 42.w,
              height: 42.h,
              child: Image.asset(
                isDark ? AppAssets.hashtagDarkIcon : AppAssets.hashtageIcon,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.tag_rounded, color: primary, size: 28.sp),
              ),
            ),
          ],
        );
      },
    );
  }
}
