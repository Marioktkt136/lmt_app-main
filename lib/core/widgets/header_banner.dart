import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/lmt_cubit.dart';
import '../theme/colors.dart';
import '../utils/app_assets.dart';

/// Compact top header displaying the L.M.T logo alongside the annual Bible
/// verse (`آية السنة`) as plain text.
class HeaderBanner extends StatelessWidget {
  /// Creates a [HeaderBanner].
  const HeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final primary = AppColors.primaryOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 46.w,
                height: 46.w,
                child: Image.asset(AppAssets.appLogo, fit: BoxFit.contain),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  state.verseOfYear,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                    color: textPrimary,
                    shadows: [Shadow(color: primary.withValues(alpha: 0.12), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
