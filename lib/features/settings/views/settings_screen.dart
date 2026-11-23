import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../main.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/settings_appearance_card.dart';
import '../widgets/settings_branding_card.dart';
import '../widgets/settings_identity_card.dart';
import '../widgets/settings_security_sync_card.dart';

/// Settings View composing:
/// - [SettingsIdentityCard]
/// - [SettingsAppearanceCard] (Light/Dark & Ar/En switches)
/// - [SettingsSecuritySyncCard] (Biometric toggle & Offline/Online sync)
/// - [SettingsBrandingCard] (Slogan & Verse of the Year)
/// - Log-out confirmation action.
class SettingsScreen extends StatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await LMTApp.of(context).setThemeMode(newMode);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _switchLocale(Locale locale) async {
    await AppPreferences.setLocale(locale);
    if (!mounted) return;
    await context.setLocale(locale);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleLogout() async {
    final isArabic = context.locale.languageCode == 'ar';
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

    if (confirmed == true && mounted) {
      await context.read<LmtCubit>().logout();
      if (!mounted) return;
      AppRouter.navigateAndRemoveUntil(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = context.locale.languageCode == 'ar';
        final isDark = AppColors.isDark(context);
        final primary = AppColors.primaryOf(context);

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: Text(
              isArabic ? 'الإعدادات (Settings)' : 'Settings',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: AdaptiveContentBox(
            maxWidth: 720,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              physics: const BouncingScrollPhysics(),
              children: [
                SettingsIdentityCard(sloganOfYear: state.sloganOfYear),
                SizedBox(height: 14.h),
                SettingsAppearanceCard(
                  isArabic: isArabic,
                  isDark: isDark,
                  onToggleTheme: _toggleTheme,
                  onSwitchLocale: _switchLocale,
                ),
                SizedBox(height: 14.h),
                SettingsSecuritySyncCard(
                  state: state,
                  isArabic: isArabic,
                ),
                SizedBox(height: 14.h),
                SettingsBrandingCard(
                  state: state,
                  isArabic: isArabic,
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(
                      isArabic ? 'تسجيل الخروج (Log-out)' : 'Log-out',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
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
