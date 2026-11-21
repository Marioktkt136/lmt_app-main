import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/profile_cubit.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';
import '../widgets/profile_info_row.dart';
import '../widgets/profile_sheets.dart';

/// Profile View displaying user information (ID, Name, Role, Joined Groups,
/// Specialist at, Committee) and password update controls.
class ProfileScreen extends StatelessWidget {
  /// Whether this screen is pushed as a standalone page with an [AppBar].
  final bool isStandalonePage;

  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key, this.isStandalonePage = true});

  @override
  Widget build(BuildContext context) {
    final content = BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final user = state.currentUser;
        final primary = AppColors.primaryOf(context);
        final accentGreen = AppColors.accentGreenOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);
        final border = AppColors.borderOf(context);

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Avatar & Identity Card
              LmtCard(
                padding: EdgeInsets.all(20.w),
                borderRadius: 22.r,
                accentColor: primary,
                child: Column(
                  children: [
                    LmtAvatar(
                      imagePath: user.avatarPath,
                      radius: 46,
                      badge: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: accentGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceOf(context),
                            width: 2.2,
                          ),
                          boxShadow: AppColors.cardShadows(
                            context,
                            accent: accentGreen,
                            intensity: 0.6,
                          ),
                        ),
                        child: Text(
                          user.role.badgeEmoji,
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
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
                      label: isArabic
                          ? 'التخصص (Specialist at)'
                          : 'Specialist at',
                      value: user.specialistAt,
                    ),
                    ProfileInfoRow(
                      icon: Icons.category_outlined,
                      label: isArabic ? 'اللجنة (Committee)' : 'Committee',
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
            ],
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
