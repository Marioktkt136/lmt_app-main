import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/lmt_cubit.dart';
import '../routes/app_router.dart';
import '../routes/routes.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/app_assets.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Drawer / Menu Button
              IconButton(
                tooltip: 'Menu',
                onPressed: () {
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold != null && scaffold.hasDrawer) {
                    scaffold.openDrawer();
                  } else {
                    AppRouter.navigateTo(context, Routes.settings);
                  }
                },
                icon: Image.asset(
                  AppAssets.menuIcon,
                  width: 26.w,
                  height: 26.w,
                ),
              ),

              // Title & Active Role Pill
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'app_bar_title'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${state.currentUser.name} ${state.currentUser.role.badgeEmoji}',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile + Notification Icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => AppRouter.navigateTo(context, Routes.profile),
                    child: CircleAvatar(
                      radius: 15.r,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          AssetImage(state.currentUser.avatarPath),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  NotificationIcon(
                    unreadCount: state.unreadNotificationsCount,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final int unreadCount;

  const NotificationIcon({
    super.key,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            AppRouter.navigateTo(context, Routes.notification);
          },
          icon: Image.asset(
            AppAssets.notificationIcon,
            width: 24.w,
            height: 24.w,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
