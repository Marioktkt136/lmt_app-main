import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/profile_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Displays a modal bottom sheet for editing the current user's profile
/// information, supporting multi-selection for departments (`القسم`) and
/// committees (`اللجنة`).
void showEditProfileSheet(BuildContext context, MemberModel user) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final nameCtrl = TextEditingController(text: user.name);
  final selectedDepartments = Set<String>.from(user.departments);
  final selectedCommittees = Set<String>.from(user.committees);
  final canEditDeptsAndComms = user.role.canEditDepartmentsAndCommittees;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final textPrimary = AppColors.textPrimaryOf(ctx);
          final textSecondary = AppColors.textSecondaryOf(ctx);

          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 18.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      isArabic
                          ? 'تعديل الملف الشخصي'
                          : 'Edit Profile Information',
                      style: AppTypography.h5.copyWith(color: textPrimary),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الاسم بالكامل' : 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  if (!canEditDeptsAndComms) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOf(ctx).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color:
                              AppColors.primaryOf(ctx).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 18.sp,
                            color: AppColors.primaryOf(ctx),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'تعديل القسم واللجنة متاح للمسؤول (Administrator) فقط 🔒'
                                  : 'Editing Department & Committee is restricted to Administrator only 🔒',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  Text(
                    isArabic
                        ? (canEditDeptsAndComms
                            ? 'القسم (يمكن اختيار قسم أو أكثر):'
                            : 'القسم الحالي (للعرض فقط):')
                        : 'القسم (Department):',
                    style: AppTypography.labelLarge.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: MemberModel.availableDepartments.map((dept) {
                      final isSelected = selectedDepartments.contains(dept);
                      return FilterChip(
                        selected: isSelected,
                        onSelected: canEditDeptsAndComms
                            ? (val) {
                                setModalState(() {
                                  if (val) {
                                    selectedDepartments.add(dept);
                                  } else if (selectedDepartments.length > 1) {
                                    selectedDepartments.remove(dept);
                                  }
                                });
                              }
                            : null,
                        label: Text(dept),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    isArabic
                        ? (canEditDeptsAndComms
                            ? 'اللجنة (يمكن اختيار لجنة أو أكثر):'
                            : 'اللجنة الحالية (للعرض فقط):')
                        : 'اللجنة (Committee):',
                    style: AppTypography.labelLarge.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: MemberModel.availableCommittees.map((comm) {
                      final isSelected = selectedCommittees.contains(comm);
                      return FilterChip(
                        selected: isSelected,
                        onSelected: canEditDeptsAndComms
                            ? (val) {
                                setModalState(() {
                                  if (val) {
                                    selectedCommittees.add(comm);
                                  } else if (selectedCommittees.length > 1) {
                                    selectedCommittees.remove(comm);
                                  }
                                });
                              }
                            : null,
                        label: Text(comm),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<LmtCubit>().updateProfileInfo(
                              name: nameCtrl.text,
                              departments: selectedDepartments.toList(),
                              committees: selectedCommittees.toList(),
                            );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(isArabic ? 'حفظ التغييرات' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
