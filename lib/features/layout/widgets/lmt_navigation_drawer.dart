import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/layout_cubit.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_preferences.dart';

/// Side navigation drawer providing quick access to Khelwa, YouTube, Settings, and Log-out.
class LmtNavigationDrawer extends StatelessWidget {
  /// Creates an [LmtNavigationDrawer].
  const LmtNavigationDrawer({super.key});

  Future<void> _handleDrawerLogout(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Log-out'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من رغبتك في تسجيل الخروج من حساب L.M.T؟'
              : 'Are you sure you want to log out of your L.M.T account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Log-out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AppPreferences.clearLogin();
      if (!context.mounted) return;
      AppRouter.navigateAndRemoveUntil(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final user = state.currentUser;
        final accentGreen = AppColors.accentGreenOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);

        return Drawer(
          backgroundColor: AppColors.surfaceOf(context),
          child: SafeArea(
            child: Column(
              children: [
                // User Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    gradient: AppColors.isDark(context)
                        ? AppColors.darkPrimaryGradient
                        : AppColors.primaryGradient,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(user.avatarPath),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: AppTypography.h5.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${user.id} • ${user.role.shortLabel(isArabic)}',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              user.committee,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5.sp, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Drawer Navigation Links
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    children: [
                      _DrawerNavItem(
                        icon: Icons.self_improvement_rounded,
                        title: isArabic ? 'الخلوة اليومية' : 'Daily Khelwa',
                        color: accentGreen,
                        onTap: () {
                          Navigator.pop(context);
                          AppRouter.navigateTo(context, Routes.khelwa);
                        },
                      ),
                      _DrawerNavItem(
                        icon: Icons.ondemand_video_rounded,
                        title: isArabic ? 'عروض المسرح على يوتيوب (YouTube)' : 'YouTube Gallery',
                        color: AppColors.error,
                        onTap: () {
                          Navigator.pop(context);
                          AppRouter.navigateTo(context, Routes.youtube);
                        },
                      ),
                      const Divider(),
                      _DrawerNavItem(
                        icon: Icons.settings_rounded,
                        title: isArabic ? 'الإعدادات' : 'Settings',
                        color: textPrimary,
                        onTap: () {
                          Navigator.pop(context);
                          AppRouter.navigateTo(context, Routes.settings);
                        },
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(bottom: 12.h, left: 16.w, right: 16.w),
                  child: Text(
                    'Developed by\n Mario Naiem Ktkt \n Version : $appBuildName',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: const Color.fromARGB(82, 43, 94, 153),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 3.h, left: 16.w, right: 16.w),
                  child: Text(
                    'The Last Message Team (L.M.T)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: AppColors.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Log-out Button at the Bottom
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: AppColors.cardShadows(
                        context,
                        accent: AppColors.error,
                        intensity: 0.85,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      onPressed: () => _handleDrawerLogout(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        isArabic ? 'تسجيل الخروج (Log-out)' : 'Log-out',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryOf(context),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textSecondaryOf(context),
      ),
      onTap: onTap,
    );
  }
}
