import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays an individual team member's profile card in the Member List View.
class MemberCard extends StatelessWidget {
  /// The member model to render.
  final MemberModel member;

  /// Whether the current user can manage member accounts and roles.
  final bool canManageMembers;

  /// Callback invoked when the manage account icon is pressed.
  final VoidCallback onManage;

  /// Creates a [MemberCard].
  const MemberCard({
    super.key,
    required this.member,
    required this.canManageMembers,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);
    final roleColor = _roleBadgeColor(member.role, primary, accentGreen);

    return LmtCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      borderRadius: 20.r,
      accentColor: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LmtAvatar(
                imagePath: member.avatarPath,
                radius: 23,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: AppTypography.h6.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            member.role.shortLabel(isArabic),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'ID: ${member.id} • @${member.username}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManageMembers)
                IconButton(
                  tooltip: isArabic
                      ? 'تغيير الصلاحية / إدارة الحساب'
                      : 'Manage Role & Account',
                  onPressed: onManage,
                  icon: Icon(
                    Icons.manage_accounts_rounded,
                    color: primary,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(color: border, height: 1),
          SizedBox(height: 8.h),

          // Department (القسم) & Committee (اللجنة)
          Row(
            children: [
              Icon(
                Icons.theater_comedy_outlined,
                size: 15.sp,
                color: primary,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  '${isArabic ? 'القسم:' : 'القسم (Department):'} ${member.specialistAt}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                Icons.groups_2_outlined,
                size: 15.sp,
                color: accentGreen,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  '${isArabic ? 'اللجنة:' : 'اللجنة (Committee):'} ${member.committee}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Which Groups he is in
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: member.groups.map((grp) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 3.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: border),
                ),
                child: Text(
                  '💬 $grp',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _roleBadgeColor(UserRole role, Color primary, Color accentGreen) {
    switch (role) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.editor:
        return primary;
      case UserRole.member:
        return accentGreen;
    }
  }
}
