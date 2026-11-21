import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/members_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Displays a modal bottom sheet for managing a member's role authority or deleting their account.
void showManageMemberSheet(
  BuildContext context,
  LmtState state,
  MemberModel member,
) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final currentUserRole = state.currentUser.role;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      final textPrimary = AppColors.textPrimaryOf(ctx);
      final primary = AppColors.primaryOf(ctx);

      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isArabic ? 'إدارة صلاحيات وحساب:' : 'Manage Account:'} ${member.name} (${member.id})',
              style: AppTypography.h5.copyWith(color: textPrimary),
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
            SizedBox(height: 8.h),
            ...UserRole.values.map((targetRole) {
              final allowed = currentUserRole.canChangeRoleTo(
                member.role,
                targetRole,
              );
              return ListTile(
                enabled: allowed,
                leading: Icon(
                  member.role == targetRole
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
                    ? () {
                        context.read<LmtCubit>().changeMemberRole(
                              memberId: member.id,
                              newRole: targetRole,
                            );
                        Navigator.pop(ctx);
                      }
                    : null,
              );
            }),
            if (currentUserRole.canDeleteMembers &&
                member.id != state.currentUser.id) ...[
              const Divider(),
              ListTile(
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
      );
    },
  );
}

/// Displays a modal bottom sheet for creating a new member account.
void showAddMemberSheet(BuildContext context, LmtState state) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController(text: 'password123');
  final specCtrl =
      TextEditingController(text: 'تمثيل مسرحي (Stage Acting)');
  final commCtrl =
      TextEditingController(text: 'اللجنة الفنية والمسرح (Artistic)');
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
                  SizedBox(height: 10.h),
                  TextField(
                    controller: specCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic
                          ? 'التخصص (Specialist at)'
                          : 'Specialist at',
                      prefixIcon: const Icon(Icons.theater_comedy_outlined),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: commCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'اللجنة (Committee)' : 'Committee',
                      prefixIcon: const Icon(Icons.groups_outlined),
                    ),
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
                              specialistAt: specCtrl.text,
                              committee: commCtrl.text,
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
