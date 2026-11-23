import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/lmt_cubit.dart';
import '../routes/app_router.dart';
import '../routes/routes.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/app_assets.dart';
import '../utils/device_file_helper.dart';

/// Top application bar displaying the drawer menu button, app title,
/// tappable active-user role pill, profile avatar with online status dot,
/// and notification bell with unread count badge.
class CustomAppBar extends StatelessWidget {
  /// Creates a [CustomAppBar].
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final sloganText = state.sloganOfYear.trim().startsWith('#')
            ? state.sloganOfYear.trim()
            : '#${state.sloganOfYear.trim()}';

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: isArabic ? 'القائمة الجانبية' : 'Navigation Menu',
                onPressed: () {
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold != null && scaffold.hasDrawer) {
                    scaffold.openDrawer();
                  } else {
                    AppRouter.navigateTo(context, Routes.settings);
                  }
                },
                icon: Image.asset(AppAssets.menuIcon, width: 24.w, height: 24.w),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'app_bar_title'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.h5.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        sloganText,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: isArabic ? 'الملف الشخصي' : 'Profile',
                    child: GestureDetector(
                      onTap: () => AppRouter.navigateTo(context, Routes.profile),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 16.r,
                            backgroundColor: Colors.white24,
                            backgroundImage: DeviceFileHelper.imageProviderFor(
                              state.currentUser.avatarPath,
                              fallbackAsset: AppAssets.accountIcon,
                            ),
                            onBackgroundImageError: (_, _) {},
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 9.w,
                              height: 9.w,
                              decoration: BoxDecoration(
                                color: state.isOnline ? const Color(0xFF00E676) : AppColors.warning,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  NotificationIcon(unreadCount: state.unreadNotificationsCount),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Notification bell icon button with an unread count badge.
class NotificationIcon extends StatelessWidget {
  /// Number of unread notifications.
  final int unreadCount;

  /// Creates a [NotificationIcon].
  const NotificationIcon({super.key, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Stack(
      children: [
        IconButton(
          tooltip: isArabic ? 'الإشعارات والتذكيرات' : 'Notifications',
          onPressed: () {
            AppRouter.navigateTo(context, Routes.notification);
          },
          icon: Image.asset(AppAssets.notificationIcon, width: 24.w, height: 24.w),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
