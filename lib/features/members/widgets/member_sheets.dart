import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/members_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Displays a modal bottom sheet for managing a member's role authority,
/// assigned departments (`القسم`), assigned committees (`اللجنة`), or deleting
/// their account.
void showManageMemberSheet(
  BuildContext context,
  LmtState state,
  MemberModel member,
) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final currentUserRole = state.currentUser.role;
  final canEditDeptsAndComms = currentUserRole.canEditDepartmentsAndCommittees;
  final selectedDepartments = Set<String>.from(member.departments);
  final selectedCommittees = Set<String>.from(member.committees);
  UserRole selectedRole = member.role;

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
          final primary = AppColors.primaryOf(ctx);

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
                  Text(
                    '${isArabic ? 'إدارة صلاحيات وحساب:' : 'Manage Account:'} ${member.name} (${member.id})',
                    style: AppTypography.h5.copyWith(color: textPrimary),
                  ),
                  SizedBox(height: 12.h),
                  if (!canEditDeptsAndComms) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 17.sp,
                            color: primary,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'تعديل القسم واللجنة متاح للمسؤول (Administrator) فقط 🔒'
                                  : 'Editing Department & Committee is restricted to Administrator only 🔒',
                              style: TextStyle(
                                fontSize: 11.sp,
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
                            ? 'القسم (للمسؤول فقط - يمكن تعيين أكثر من قسم):'
                            : 'القسم (متاح للمسؤول فقط 🔒):')
                        : 'القسم (Department - Admin Only):',
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
                  SizedBox(height: 12.h),
                  Text(
                    isArabic
                        ? (canEditDeptsAndComms
                            ? 'اللجنة (للمسؤول فقط - يمكن تعيين أكثر من لجنة):'
                            : 'اللجنة (متاح للمسؤول فقط 🔒):')
                        : 'اللجنة (Committee - Admin Only):',
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
                  SizedBox(height: 12.h),
                  Text(
                    isArabic
                        ? 'تغيير صلاحية العضو (Change Role Authority):'
                        : 'Change Role Authority:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondaryOf(ctx),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ...UserRole.values.map((targetRole) {
                    final allowed = currentUserRole.canChangeRoleTo(
                      member.role,
                      targetRole,
                    );
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      enabled: allowed,
                      leading: Icon(
                        selectedRole == targetRole
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: allowed ? primary : Colors.grey,
                      ),
                      title: Text(targetRole.label(isArabic)),
                      subtitle: !allowed
                          ? Text(
                              isArabic
                                  ? 'متاح للمسؤول (Administrator) فقط'
                                  : 'Requires Administrator authority',
                              style: TextStyle(fontSize: 10.sp),
                            )
                          : null,
                      onTap: allowed
                          ? () => setModalState(() => selectedRole = targetRole)
                          : null,
                    );
                  }),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final cubit = context.read<LmtCubit>();
                        if (selectedRole != member.role) {
                          await cubit.changeMemberRole(
                            memberId: member.id,
                            newRole: selectedRole,
                          );
                        }
                        await cubit.updateMemberDetails(
                          member.copyWith(
                            role: selectedRole,
                            departments: selectedDepartments.toList(),
                            committees: selectedCommittees.toList(),
                          ),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        isArabic ? 'حفظ التعديلات' : 'Save Changes',
                      ),
                    ),
                  ),
                  if (currentUserRole.canDeleteMembers &&
                      member.id != state.currentUser.id) ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.person_remove_rounded,
                        color: AppColors.error,
                      ),
                      title: Text(
                        isArabic
                            ? 'حذف حساب العضو نهائياً'
                            : 'Delete Member Account',
                        style: const TextStyle(color: AppColors.error),
                      ),
                      onTap: () {
                        context.read<LmtCubit>().deleteMember(member.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Displays a modal bottom sheet for creating a new member account with
/// multi-select departments (`القسم`) and committees (`اللجنة`).
void showAddMemberSheet(BuildContext context, LmtState state) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final canEditDeptsAndComms =
      state.currentUser.role.canEditDepartmentsAndCommittees;
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController(text: 'password123');
  final selectedDepartments = <String>{
    MemberModel.availableDepartments.first,
  };
  final selectedCommittees = <String>{
    MemberModel.availableCommittees.first,
  };
  UserRole selectedRole = UserRole.member;

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
          final availableRoles = state.currentUser.role == UserRole.admin
              ? UserRole.values
              : [UserRole.member, UserRole.editor];

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
                  Text(
                    isArabic
                        ? 'إنشاء حساب عضو جديد في الفريق 👤'
                        : 'Create New Member Account 👤',
                    style: AppTypography.h4.copyWith(color: textPrimary),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText:
                          isArabic ? 'الاسم بالكامل (Name)' : 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      labelText:
                          isArabic ? 'اسم المستخدم للدخول' : 'Username',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: passwordCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'كلمة المرور' : 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    isArabic
                        ? (canEditDeptsAndComms
                            ? 'القسم (للمسؤول فقط - يمكن اختيار قسم أو أكثر):'
                            : 'القسم (تعديله متاح للمسؤول فقط 🔒):')
                        : 'القسم (Department - Admin Only):',
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
                  SizedBox(height: 12.h),
                  Text(
                    isArabic
                        ? (canEditDeptsAndComms
                            ? 'اللجنة (للمسؤول فقط - يمكن اختيار لجنة أو أكثر):'
                            : 'اللجنة (تعديلها متاح للمسؤول فقط 🔒):')
                        : 'اللجنة (Committee - Admin Only):',
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
                  SizedBox(height: 12.h),
                  Text(
                    isArabic ? 'الصلاحية (Role Authority):' : 'Role:',
                    style: AppTypography.labelLarge.copyWith(
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 8.w,
                    children: availableRoles.map((r) {
                      return ChoiceChip(
                        selected: selectedRole == r,
                        onSelected: (_) =>
                            setModalState(() => selectedRole = r),
                        label: Text(r.shortLabel(isArabic)),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        context.read<LmtCubit>().addMember(
                              name: nameCtrl.text,
                              username: usernameCtrl.text.trim().isEmpty
                                  ? nameCtrl.text
                                      .trim()
                                      .toLowerCase()
                                      .replaceAll(' ', '_')
                                  : usernameCtrl.text,
                              password: passwordCtrl.text,
                              role: selectedRole,
                              departments: selectedDepartments.toList(),
                              committees: selectedCommittees.toList(),
                              groups: const [
                                'فريق الرسالة الاخيرة - العام',
                                'بروفات مسرحية تغيروا 2026',
                              ],
                            );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        isArabic ? 'إنشاء الحساب' : 'Create Account',
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
