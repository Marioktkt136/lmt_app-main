import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/profile_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Displays a modal bottom sheet for editing the current user's profile information.
void showEditProfileSheet(BuildContext context, MemberModel user) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final nameCtrl = TextEditingController(text: user.name);
  final specCtrl = TextEditingController(text: user.specialistAt);
  final commCtrl = TextEditingController(text: user.committee);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 18.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile Information',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimaryOf(ctx),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: isArabic ? 'الاسم بالكامل' : 'Full Name',
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: specCtrl,
              decoration: InputDecoration(
                labelText:
                    isArabic ? 'التخصص (Specialist at)' : 'Specialist at',
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: commCtrl,
              decoration: InputDecoration(
                labelText: isArabic ? 'اللجنة (Committee)' : 'Committee',
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<LmtCubit>().updateProfileInfo(
                        name: nameCtrl.text,
                        specialistAt: specCtrl.text,
                        committee: commCtrl.text,
                      );
                  Navigator.pop(ctx);
                },
                child: Text(isArabic ? 'حفظ التغييرات' : 'Save Changes'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Displays a modal bottom sheet for updating the current user's password.
void showUpdatePasswordSheet(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 18.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'تحديث كلمة المرور (Update Password) 🔒'
                    : 'Update Password 🔒',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimaryOf(ctx),
                ),
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText:
                      isArabic ? 'كلمة المرور الحالية' : 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? (isArabic ? 'هذا الحقل مطلوب' : 'Required')
                    : null,
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText:
                      isArabic ? 'كلمة المرور الجديدة' : 'New Password',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? (isArabic
                        ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                        : 'Minimum 6 characters')
                    : null,
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isArabic
                      ? 'تأكيد كلمة المرور الجديدة'
                      : 'Confirm New Password',
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                ),
                validator: (v) => v != newCtrl.text
                    ? (isArabic
                        ? 'كلمتا المرور غير متطابقتين'
                        : 'Passwords do not match')
                    : null,
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreenOf(ctx),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await context.read<LmtCubit>().updatePassword(
                          currentPassword: currentCtrl.text,
                          newPassword: newCtrl.text,
                        );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'تم تحديث كلمة المرور بنجاح ✅'
                              : 'Password updated successfully ✅',
                        ),
                        backgroundColor: AppColors.accentGreenOf(context),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    isArabic ? 'حفظ كلمة المرور الجديدة' : 'Update Password',
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
