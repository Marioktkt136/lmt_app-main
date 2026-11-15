import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/routes/app_router.dart';
import 'package:lmt/core/routes/routes.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/theme/typography.dart';
import 'package:lmt/core/utils/app_assets.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.sizeOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: mediaQuery.width * 0.13.w,
          child: IconButton(onPressed: () {}, icon: Image.asset(AppAssets.menuIcon)),
        ),
        Text(
          'app_bar_title'.tr(),
          style: AppTypography.h2.copyWith(color: AppColors.textOnPrimary),
        ),
        NotificationIcon(mediaQuery: mediaQuery),
      ],
    );
  }
}

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key, required this.mediaQuery});

  final Size mediaQuery;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: mediaQuery.width * 0.118.w,
          child: IconButton(
            onPressed: () {
              AppRouter.navigateTo(context, Routes.notification);
            },
            icon: Image.asset(AppAssets.notificationIcon),
          ),
        ),
        NotificationAlert(),
      ],
    );
  }
}

class NotificationAlert extends StatelessWidget {
  const NotificationAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 9,
      right: 5,
      child: Container(
        width: 15,
        height: 15,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: Text(
          '0',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.background),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
