import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../../../core/widgets/lmt_search_bar.dart';
import '../cubit/members_cubit.dart';
import '../widgets/member_card.dart';
import '../widgets/member_sheets.dart';
import '../widgets/members_filter_bar.dart';

/// Member List View displaying all team members with search, coordinated
/// dropdown filtering by Role (`الصلاحية`), Department (`القسم`), and Committee
/// (`اللجنة`), and role-based member management.
class MembersScreen extends StatefulWidget {
  /// Whether this screen is pushed as a standalone route with an [AppBar].
  final bool isStandalonePage;

  /// Creates a [MembersScreen].
  const MembersScreen({super.key, this.isStandalonePage = false});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _searchQuery = '';
  UserRole? _roleFilter;
  String? _departmentFilter;
  String? _committeeFilter;

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final primary = AppColors.primaryOf(context);
        final canManageMembers = state.currentUser.role.canManageMembers;
        final canCreateMembers = state.currentUser.role.canCreateMembers;

        final filteredMembers = state.members.where((m) {
          if (_roleFilter != null && m.role != _roleFilter) return false;
          if (_departmentFilter != null &&
              !m.departments.contains(_departmentFilter)) {
            return false;
          }
          if (_committeeFilter != null &&
              !m.committees.contains(_committeeFilter)) {
            return false;
          }
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return m.name.toLowerCase().contains(q) ||
              m.id.toLowerCase().contains(q) ||
              m.specialistAt.toLowerCase().contains(q) ||
              m.committee.toLowerCase().contains(q);
        }).toList();

        return AdaptiveContentBox(
          maxWidth: AdaptiveBreakpoints.wideDesktopMaxWidth,
          child: Column(
            children: [
              // Search & Add Account Bar (Admin only)
              LmtSearchBar(
                hintText: isArabic
                    ? 'ابحث بالاسم، الكود (ID)، القسم، أو اللجنة...'
                    : 'Search by Name, ID, Department, Committee...',
                onChanged: (v) => setState(() => _searchQuery = v),
                actions: [
                  if (canCreateMembers) ...[
                    SizedBox(width: 8.w),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: primary),
                      tooltip: isArabic
                          ? 'إنشاء حساب عضو جديد'
                          : 'Add New Member Account',
                      onPressed: () => showAddMemberSheet(context, state),
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8.h),

              // Coordinated 3-Dropdown Filter Bar (Role, Department, Committee)
              MembersFilterBar(
                allMembers: state.members,
                filteredMembers: filteredMembers,
                selectedRole: _roleFilter,
                selectedDepartment: _departmentFilter,
                selectedCommittee: _committeeFilter,
                onRoleChanged: (role) => setState(() => _roleFilter = role),
                onDepartmentChanged: (dept) =>
                    setState(() => _departmentFilter = dept),
                onCommitteeChanged: (comm) =>
                    setState(() => _committeeFilter = comm),
                onResetFilters: () => setState(() {
                  _roleFilter = null;
                  _departmentFilter = null;
                  _committeeFilter = null;
                }),
              ),
              SizedBox(height: 8.h),

              // Responsive Members List (1 column on phones, multi-column on tablets/landscape)
              Expanded(
                child: filteredMembers.isEmpty
                    ? LmtEmptyState(
                        icon: Icons.people_outline_rounded,
                        message: isArabic
                            ? 'لا يوجد أعضاء مطابقين لهذا الفلتر حالياً'
                            : 'No members match the selected filters',
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >=
                              AdaptiveBreakpoints.compactMaxWidth) {
                            final rowCount = (filteredMembers.length + 1) ~/ 2;
                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 4.h,
                              ),
                              itemCount: rowCount,
                              itemBuilder: (context, rowIndex) {
                                final leftIdx = rowIndex * 2;
                                final rightIdx = leftIdx + 1;
                                final left = filteredMembers[leftIdx];
                                final right = rightIdx < filteredMembers.length
                                    ? filteredMembers[rightIdx]
                                    : null;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: MemberCard(
                                        member: left,
                                        canManageMembers: canManageMembers,
                                        onManage: () => showManageMemberSheet(
                                          context,
                                          state,
                                          left,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: right == null
                                          ? const SizedBox.shrink()
                                          : MemberCard(
                                              member: right,
                                              canManageMembers:
                                                  canManageMembers,
                                              onManage: () =>
                                                  showManageMemberSheet(
                                                context,
                                                state,
                                                right,
                                              ),
                                            ),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 4.h,
                            ),
                            itemCount: filteredMembers.length,
                            itemBuilder: (context, index) {
                              final member = filteredMembers[index];
                              return MemberCard(
                                member: member,
                                canManageMembers: canManageMembers,
                                onManage: () => showManageMemberSheet(
                                  context,
                                  state,
                                  member,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );

    if (!widget.isStandalonePage) return body;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.primaryOf(context),
        foregroundColor: Colors.white,
        title: Text(
          isArabic ? 'قائمة أعضاء الفريق (Member List)' : 'Team Member List',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(14.w),
        child: body,
      ),
    );
  }
}
