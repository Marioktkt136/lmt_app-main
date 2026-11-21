import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/settings_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../main.dart';

/// Settings View
/// - Light/Dark Switch
/// - Language Switch (Ar/En)
/// - Biometric Login Switch (Fingerprint & Face Recognition)
/// - Slogan & Verse of the Year
/// - Offline/Online Data Sync
/// - Log-out
class SettingsScreen extends StatefulWidget {
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
      await AppPreferences.clearLogin();
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
        final accentGreen = AppColors.accentGreenOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);

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
          body: ListView(
            padding: EdgeInsets.all(16.w),
            physics: const BouncingScrollPhysics(),
            children: [
              // App Identity Header Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: AppColors.cardDecoration(
                  context,
                  radius: 22.r,
                  accentColor: primary,
                ),
                child: Row(
                  children: [
                    Image.asset(AppAssets.appLogo, width: 64.w, height: 64.w),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Last Message Team',
                            style: AppTypography.h5.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'فريق الرسالة الاخيرة • L.M.T',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '🎭 Act, Drama & Theater • ${state.sloganOfYear}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // 1. Appearance & Language Section (Light/Dark Switch & Language Switch Ar/En)
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: AppColors.cardDecoration(
                  context,
                  radius: 22.r,
                  accentColor: primary,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      isArabic
                          ? 'المظهر واللغة (Appearance & Localization)'
                          : 'Appearance & Localization',
                      style: AppTypography.h6.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),

                    // Light / Dark Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: CircleAvatar(
                        backgroundColor: primary.withValues(alpha: 0.12),
                        child: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: primary,
                        ),
                      ),
                      title: Text(
                        isArabic
                            ? 'الوضع الليلي / النهاري (Light/Dark Switch)'
                            : 'Dark / Light Mode Switch',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5.sp,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isDark
                            ? (isArabic
                                ? 'الوضع الليلي مفعل (#121212 / #1E1E24 WCAG AA)'
                                : 'Dark Mode Active (#121212 / #1E1E24 WCAG AA)')
                            : (isArabic
                                ? 'الوضع النهاري مفعل (#FFFFFF / #488FE1)'
                                : 'Light Mode Active (#FFFFFF / #488FE1)'),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textSecondary,
                        ),
                      ),
                      value: isDark,
                      activeTrackColor: primary,
                      onChanged: _toggleTheme,
                    ),
                    const Divider(),

                    // Language Switch (Ar / En)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: primary.withValues(alpha: 0.12),
                        child: Icon(Icons.language_rounded, color: primary),
                      ),
                      title: Text(
                        isArabic
                            ? 'لغة التطبيق (Language Switch Ar/En)'
                            : 'Application Language (Ar / En)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5.sp,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isArabic
                            ? 'العربية (مصر) / English (USA)'
                            : 'English (USA) / العربية (Egypt)',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textSecondary,
                        ),
                      ),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ar', label: Text('العربية')),
                          ButtonSegment(value: 'en', label: Text('EN')),
                        ],
                        selected: {isArabic ? 'ar' : 'en'},
                        onSelectionChanged: (set) {
                          _switchLocale(Locale(set.first));
                        },
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // 2. Security, Biometric Login & Sync Section
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: AppColors.cardDecoration(
                  context,
                  radius: 22.r,
                  accentColor: primary,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      isArabic
                          ? 'الأمان والمزامنة (Security & Offline Sync)'
                          : 'Security & Offline/Online Sync',
                      style: AppTypography.h6.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: CircleAvatar(
                        backgroundColor: accentGreen.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          color: accentGreen,
                        ),
                      ),
                      title: Text(
                        isArabic
                            ? 'الدخول بالبصمة والوجه (Fingerprint & Face ID)'
                            : 'Fingerprint & Face Recognition Login',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        isArabic
                            ? 'تفعيل المصادقة البيومترية السريعة (Android / iOS)'
                            : 'Enable biometric authentication (Android / iOS)',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textSecondary,
                        ),
                      ),
                      value: state.biometricEnabled,
                      activeTrackColor: accentGreen,
                      onChanged: (v) =>
                          context.read<LmtCubit>().setBiometricEnabled(v),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: (state.isOnline
                                ? accentGreen
                                : AppColors.warning)
                            .withValues(alpha: 0.14),
                        child: Icon(
                          state.isOnline
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color:
                              state.isOnline ? accentGreen : AppColors.warning,
                        ),
                      ),
                      title: Text(
                        state.isOnline
                            ? (isArabic
                                ? 'متصل بالإنترنت (Online Sync)'
                                : 'Online • Real-Time Sync Connected')
                            : (isArabic
                                ? 'وضع عدم الاتصال (Offline Mode)'
                                : 'Offline • Local Cache Active'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${isArabic ? 'آخر مزامنة:' : 'Last synced:'} ${DateFormat('hh:mm:ss a').format(state.lastSyncedAt)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textSecondary,
                        ),
                      ),
                      trailing: OutlinedButton.icon(
                        onPressed: state.isSyncing
                            ? null
                            : () => context.read<LmtCubit>().syncNow(),
                        icon: state.isSyncing
                            ? SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 16),
                        label: Text(isArabic ? 'مزامنة' : 'Sync'),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // 3. Slogan & Verse of the Year Section
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: AppColors.cardDecoration(
                  context,
                  radius: 22.r,
                  accentColor: primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic
                              ? 'شعار وآية السنة (Slogan & Verse of the Year)'
                              : 'Slogan & Verse of the Year',
                          style: AppTypography.h6.copyWith(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.currentUser.role.canDoAnything ||
                            state.currentUser.role == UserRole.editor)
                          IconButton(
                            onPressed: () =>
                                _showEditBrandingDialog(context, state),
                            icon: Icon(Icons.edit_outlined, color: primary),
                          ),
                      ],
                    ),
                    Text(
                      state.sloganOfYear,
                      style: AppTypography.h4.copyWith(color: primary),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      state.verseOfYear,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        color: textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // 4. Log-out Button
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
                    isArabic
                        ? 'تسجيل الخروج (Log-out)'
                        : 'Log-out',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditBrandingDialog(BuildContext context, LmtState state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final sloganCtrl = TextEditingController(text: state.sloganOfYear);
    final verseCtrl = TextEditingController(text: state.verseOfYear);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isArabic
              ? 'تحديث شعار وآية السنة'
              : 'Update Slogan & Verse of the Year',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sloganCtrl,
              decoration: InputDecoration(
                labelText:
                    isArabic ? 'شعار السنة (Slogan)' : 'Slogan of the Year',
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: verseCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isArabic ? 'آية السنة (Verse)' : 'Verse of the Year',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LmtCubit>().updateYearBranding(
                    slogan: sloganCtrl.text.trim(),
                    verse: verseCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}
