import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';

/// A coordinated 3-dropdown filter bar for the Members view allowing filtering
/// by [UserRole] (`الصلاحية`), Department (`القسم`), and Committee (`اللجنة`),
/// displaying the exact member count for each option.
class MembersFilterBar extends StatelessWidget {
  /// All team members (used to calculate counts per role, department, and committee).
  final List<MemberModel> allMembers;

  /// Currently filtered members list.
  final List<MemberModel> filteredMembers;

  /// Selected role filter, or `null` for all roles.
  final UserRole? selectedRole;

  /// Selected department (`القسم`) filter, or `null` for all departments.
  final String? selectedDepartment;

  /// Selected committee (`اللجنة`) filter, or `null` for all committees.
  final String? selectedCommittee;

  /// Callback when the role filter changes.
  final ValueChanged<UserRole?> onRoleChanged;

  /// Callback when the department filter changes.
  final ValueChanged<String?> onDepartmentChanged;

  /// Callback when the committee filter changes.
  final ValueChanged<String?> onCommitteeChanged;

  /// Callback to reset all active filters.
  final VoidCallback onResetFilters;

  /// Creates a [MembersFilterBar].
  const MembersFilterBar({
    super.key,
    required this.allMembers,
    required this.filteredMembers,
    required this.selectedRole,
    required this.selectedDepartment,
    required this.selectedCommittee,
    required this.onRoleChanged,
    required this.onDepartmentChanged,
    required this.onCommitteeChanged,
    required this.onResetFilters,
  });

  int _countForRole(UserRole role) =>
      allMembers.where((m) => m.role == role).length;

  int _countForDepartment(String dept) =>
      allMembers.where((m) => m.departments.contains(dept)).length;

  int _countForCommittee(String comm) =>
      allMembers.where((m) => m.committees.contains(comm)).length;

  bool get _hasActiveFilters =>
      selectedRole != null ||
      selectedDepartment != null ||
      selectedCommittee != null;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // 1. Role Dropdown
            Expanded(
              child: _FilterDropdownBox<UserRole?>(
                label: isArabic ? 'الصلاحية' : 'Role',
                icon: Icons.admin_panel_settings_outlined,
                isActive: selectedRole != null,
                accentColor: primary,
                surfaceColor: surface,
                borderColor: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                value: selectedRole,
                items: [
                  DropdownMenuItem<UserRole?>(
                    value: null,
                    child: Text(
                      isArabic
                          ? 'الكل (${allMembers.length})'
                          : 'All (${allMembers.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...UserRole.values.map(
                    (role) => DropdownMenuItem<UserRole?>(
                      value: role,
                      child: Text(
                        '${role.shortLabel(isArabic)} (${_countForRole(role)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onRoleChanged,
              ),
            ),
            SizedBox(width: 8.w),

            // 2. Department (القسم) Dropdown
            Expanded(
              child: _FilterDropdownBox<String?>(
                label: isArabic ? 'القسم' : 'Department',
                icon: Icons.theater_comedy_outlined,
                isActive: selectedDepartment != null,
                accentColor: primary,
                surfaceColor: surface,
                borderColor: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                value: selectedDepartment,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      isArabic
                          ? 'الكل (${allMembers.length})'
                          : 'All (${allMembers.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...MemberModel.availableDepartments.map(
                    (dept) => DropdownMenuItem<String?>(
                      value: dept,
                      child: Text(
                        '$dept (${_countForDepartment(dept)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onDepartmentChanged,
              ),
            ),
            SizedBox(width: 8.w),

            // 3. Committee (اللجنة) Dropdown
            Expanded(
              child: _FilterDropdownBox<String?>(
                label: isArabic ? 'اللجنة' : 'Committee',
                icon: Icons.groups_2_outlined,
                isActive: selectedCommittee != null,
                accentColor: accentGreen,
                surfaceColor: surface,
                borderColor: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                value: selectedCommittee,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      isArabic
                          ? 'الكل (${allMembers.length})'
                          : 'All (${allMembers.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...MemberModel.availableCommittees.map(
                    (comm) => DropdownMenuItem<String?>(
                      value: comm,
                      child: Text(
                        '$comm (${_countForCommittee(comm)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onCommitteeChanged,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),

        // Summary & Reset Row
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 15.sp, color: primary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  _buildSummaryText(isArabic),
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              if (_hasActiveFilters)
                InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: onResetFilters,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_off_rounded,
                          size: 14.sp,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          isArabic ? 'مسح الفلتر' : 'Reset',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildSummaryText(bool isArabic) {
    final parts = <String>[];
    if (selectedRole != null) {
      parts.add(selectedRole!.shortLabel(isArabic));
    }
    if (selectedDepartment != null) {
      parts.add('${isArabic ? 'قسم' : 'Dept'}: $selectedDepartment');
    }
    if (selectedCommittee != null) {
      parts.add(selectedCommittee!);
    }

    if (parts.isEmpty) {
      return isArabic
          ? 'إجمالي الأعضاء المعروضين: ${filteredMembers.length} عضو'
          : 'Total displayed members: ${filteredMembers.length}';
    }

    final filterDesc = parts.join(' • ');
    return isArabic
        ? '$filterDesc — العدد: (${filteredMembers.length} ${filteredMembers.length == 1 ? 'شخص' : 'أشخاص'})'
        : '$filterDesc — Count: (${filteredMembers.length})';
  }
}

class _FilterDropdownBox<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color accentColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdownBox({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.accentColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isActive
            ? accentColor.withValues(alpha: 0.1)
            : surfaceColor,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(
          color: isActive ? accentColor : borderColor,
          width: isActive ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12.sp,
                color: isActive ? accentColor : textSecondary,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isActive ? accentColor : textSecondary,
                  ),
                ),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17.sp,
                color: isActive ? accentColor : textSecondary,
              ),
              dropdownColor: surfaceColor,
              borderRadius: BorderRadius.circular(14.r),
              style: TextStyle(
                fontSize: 11.2.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? accentColor : textPrimary,
                fontFamily: 'Cairo',
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
