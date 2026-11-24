import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/profile_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/lmt_avatar.dart';

Future<String?> _pickAndPersistAvatarImage(
  BuildContext context, {
  required MemberModel user,
  required bool fromCamera,
}) async {
  final picked = fromCamera
      ? await DeviceFileHelper.capturePhotoFromCamera(context)
      : await DeviceFileHelper.pickFileSafely(context, type: FileType.image);
  if (picked == null || picked.path == null || picked.path!.trim().isEmpty) {
    return null;
  }
  return DeviceFileHelper.persistPickedFile(
    picked.path!,
    'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}_${picked.name}',
  );
}

/// Shows an avatar source selector sheet letting any user pick a new profile
/// picture from their Gallery, Camera, or reset to the default icon.
void showPickProfileAvatarSheet(
  BuildContext context, {
  required MemberModel user,
  ValueChanged<String>? onSelected,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final primary = AppColors.primaryOf(context);
  final cubit = context.read<LmtCubit>();

  showModalBottomSheet<void>(
    context: context,
    constraints: AdaptiveBreakpoints.bottomSheetConstraints(context),
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      Future<void> applyPath(String newPath) async {
        if (onSelected != null) {
          onSelected(newPath);
        } else {
          await cubit.updateProfileAvatar(newPath);
        }
        if (!ctx.mounted) return;
        Navigator.pop(ctx);
      }

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'تعديل الصورة الشخصية 📸'
                    : 'Update Profile Picture 📸',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimaryOf(ctx),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: primary.withValues(alpha: 0.12),
                  child: Icon(Icons.photo_library_rounded, color: primary),
                ),
                title: Text(
                  isArabic ? 'اختيار صورة من المعرض' : 'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  final saved = await _pickAndPersistAvatarImage(
                    ctx,
                    user: user,
                    fromCamera: false,
                  );
                  if (saved != null) await applyPath(saved);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: primary.withValues(alpha: 0.12),
                  child: Icon(Icons.camera_alt_rounded, color: primary),
                ),
                title: Text(
                  isArabic ? 'التقاط صورة بالكاميرا' : 'Take Photo with Camera',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  final saved = await _pickAndPersistAvatarImage(
                    ctx,
                    user: user,
                    fromCamera: true,
                  );
                  if (saved != null) await applyPath(saved);
                },
              ),
              if (user.avatarPath != AppAssets.accountIcon)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.restore_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  title: Text(
                    isArabic
                        ? 'استعادة الصورة الافتراضية'
                        : 'Reset to Default Avatar',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () => applyPath(AppAssets.accountIcon),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Displays a modal bottom sheet for editing the current user's profile
/// information (including profile photo and full name for all users, and
/// departments/committees for administrators).
void showEditProfileSheet(BuildContext context, MemberModel user) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final nameCtrl = TextEditingController(text: user.name);
  final selectedDepartments = Set<String>.from(user.departments);
  final selectedCommittees = Set<String>.from(user.committees);
  var selectedAvatarPath = user.avatarPath;
  final canEditDeptsAndComms = user.role.canEditDepartmentsAndCommittees;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: AdaptiveBreakpoints.bottomSheetConstraints(context),
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final textPrimary = AppColors.textPrimaryOf(ctx);
          final textSecondary = AppColors.textSecondaryOf(ctx);
          final primary = AppColors.primaryOf(ctx);

          Future<void> pickInSheet({required bool fromCamera}) async {
            final saved = await _pickAndPersistAvatarImage(
              ctx,
              user: user,
              fromCamera: fromCamera,
            );
            if (saved != null && ctx.mounted) {
              setModalState(() => selectedAvatarPath = saved);
            }
          }

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
                  SizedBox(height: 14.h),
                  // Profile Picture Editor (Available to ALL users)
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        LmtAvatar(
                          imagePath: selectedAvatarPath,
                          radius: 30,
                          showShadow: false,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic
                                    ? 'الصورة الشخصية (متاحة للجميع)'
                                    : 'Profile Picture',
                                style: TextStyle(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 6.h,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 6.h,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () =>
                                        pickInSheet(fromCamera: false),
                                    icon: Icon(
                                      Icons.photo_library_outlined,
                                      size: 16.sp,
                                    ),
                                    label: Text(
                                      isArabic ? 'المعرض' : 'Gallery',
                                      style: TextStyle(fontSize: 11.5.sp),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 6.h,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () =>
                                        pickInSheet(fromCamera: true),
                                    icon: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 16.sp,
                                    ),
                                    label: Text(
                                      isArabic ? 'كاميرا' : 'Camera',
                                      style: TextStyle(fontSize: 11.5.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
                              avatarPath: selectedAvatarPath,
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
    constraints: AdaptiveBreakpoints.bottomSheetConstraints(context),
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      String? errorMessage;
      var isSaving = false;
      return StatefulBuilder(
        builder: (ctx, setModalState) {
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
                    validator: (v) => (v == null || v.trim().length < 6)
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
                  if (errorMessage != null) ...[
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreenOf(ctx),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() {
                                errorMessage = null;
                                isSaving = true;
                              });
                              final updated = await context
                                  .read<LmtCubit>()
                                  .updatePassword(
                                    currentPassword: currentCtrl.text.trim(),
                                    newPassword: newCtrl.text.trim(),
                                  );
                              if (!ctx.mounted) return;
                              if (!updated) {
                                setModalState(() {
                                  isSaving = false;
                                  errorMessage = isArabic
                                      ? 'كلمة المرور الحالية غير صحيحة ❌'
                                      : 'Current password is incorrect ❌';
                                });
                                return;
                              }
                              Navigator.pop(ctx);
                            },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        isArabic
                            ? 'حفظ كلمة المرور الجديدة'
                            : 'Update Password',
                      ),
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
