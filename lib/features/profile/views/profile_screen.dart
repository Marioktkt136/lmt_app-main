import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_info_row.dart';
import '../widgets/profile_sheets.dart';

/// Profile View displaying user information (ID, Name, Role, Joined Groups,
/// Specialist at, Committee), password update controls, and a Log-out button.
class ProfileScreen extends StatelessWidget {
  /// Whether this screen is pushed as a standalone page with an [AppBar].
  final bool isStandalonePage;

  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key, this.isStandalonePage = true});

  Future<void> _confirmAndLogout(BuildContext context, bool isArabic) async {
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
      await context.read<LmtCubit>().logout();
      if (!context.mounted) return;
      AppRouter.navigateAndRemoveUntil(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final user = state.currentUser;
        final primary = AppColors.primaryOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);
        final border = AppColors.borderOf(context);

        return AdaptiveContentBox(
          maxWidth: 720,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Avatar & Identity Card (tap avatar to change photo)
                LmtCard(
                  padding: EdgeInsets.all(20.w),
                  borderRadius: 22.r,
                  accentColor: primary,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => showPickProfileAvatarSheet(
                          context,
                          user: user,
                        ),
                        child: LmtAvatar(
                          imagePath: user.avatarPath,
                          radius: 48,
                          badge: Container(
                            padding: EdgeInsets.all(7.w),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surfaceOf(context),
                                width: 2.2,
                              ),
                              boxShadow: AppColors.cardShadows(
                                context,
                                accent: primary,
                                intensity: 0.7,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 15.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => showPickProfileAvatarSheet(
                          context,
                          user: user,
                        ),
                        icon: Icon(
                          Icons.add_a_photo_outlined,
                          size: 16.sp,
                          color: primary,
                        ),
                        label: Text(
                          isArabic
                              ? 'تغيير الصورة الشخصية'
                              : 'Change Profile Photo',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        user.name,
                        style: AppTypography.h3.copyWith(color: textPrimary),
                      ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${user.id} • ${user.role.label(isArabic)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Profile Details Card (ID, Name, Role, Specialist at, Committee, Groups)
              LmtCard(
                padding: EdgeInsets.all(16.w),
                borderRadius: 22.r,
                accentColor: primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic
                              ? 'بيانات العضو (User Information)'
                              : 'User Information',
                          style: AppTypography.h5.copyWith(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          tooltip: isArabic ? 'تعديل البيانات' : 'Edit Profile',
                          onPressed: () => showEditProfileSheet(context, user),
                          icon: Icon(Icons.edit_outlined, color: primary),
                        ),
                      ],
                    ),
                    Divider(color: border),
                    ProfileInfoRow(
                      icon: Icons.badge_outlined,
                      label: isArabic ? 'كود العضو (ID)' : 'ID',
                      value: user.id,
                    ),
                    ProfileInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: isArabic ? 'الاسم (Name)' : 'Name',
                      value: user.name,
                    ),
                    ProfileInfoRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: isArabic ? 'الصلاحية (Role)' : 'Role',
                      value: user.role.label(isArabic),
                    ),
                    ProfileInfoRow(
                      icon: Icons.theater_comedy_outlined,
                      label: isArabic ? 'القسم' : 'Department (القسم)',
                      value: user.specialistAt,
                    ),
                    ProfileInfoRow(
                      icon: Icons.category_outlined,
                      label: isArabic ? 'اللجنة' : 'Committee (اللجنة)',
                      value: user.committee,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      isArabic
                          ? 'المجموعات المشترك بها (Which Groups he in):'
                          : 'Which Groups he is in:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: user.groups.map((grpName) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                            ),
                            boxShadow: AppColors.cardShadows(
                              context,
                              accent: primary,
                              intensity: 0.45,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 15.sp,
                                color: primary,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                grpName,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),

              // Update Password Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: AppColors.cardShadows(
                    context,
                    accent: primary,
                    intensity: 1.0,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    onPressed: () => showUpdatePasswordSheet(context),
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: Text(
                      isArabic
                          ? 'تحديث كلمة المرور (Update Password)'
                          : 'Update Password',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Logout Button at the bottom of the Profile Page
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: AppColors.cardShadows(
                    context,
                    accent: AppColors.error,
                    intensity: 0.9,
                  ),
                ),
                child: SizedBox(
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
                    onPressed: () => _confirmAndLogout(context, isArabic),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(
                      isArabic ? 'تسجيل الخروج (Log-out)' : 'Log-out',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
        );
      },
    );

    if (!isStandalonePage) return content;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.primaryOf(context),
        foregroundColor: Colors.white,
        title: Text(
          isArabic ? 'الملف الشخصي (Profile)' : 'Profile View',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: content,
    );
  }
}
