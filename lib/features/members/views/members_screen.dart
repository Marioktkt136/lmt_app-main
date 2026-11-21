import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/members_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_search_bar.dart';
import '../widgets/member_card.dart';
import '../widgets/member_sheets.dart';

/// Member List View displaying all team members with search, role filtering,
/// and role-based member management.
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

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final primary = AppColors.primaryOf(context);
        final canManageMembers = state.currentUser.role.canManageMembers;

        final filteredMembers = state.members.where((m) {
          if (_roleFilter != null && m.role != _roleFilter) return false;
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return m.name.toLowerCase().contains(q) ||
              m.id.toLowerCase().contains(q) ||
              m.specialistAt.toLowerCase().contains(q) ||
              m.committee.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            // Search & Add Account Bar (Admin & Editor)
            LmtSearchBar(
              hintText: isArabic
                  ? 'ابحث بالاسم، الكود (ID)، التخصص، أو اللجنة...'
                  : 'Search by Name, ID, Specialist, Committee...',
              onChanged: (v) => setState(() => _searchQuery = v),
              actions: [
                if (canManageMembers) ...[
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

            // Role Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    selected: _roleFilter == null,
                    onSelected: (_) => setState(() => _roleFilter = null),
                    label: Text(
                      '${isArabic ? 'الكل' : 'All'} (${state.members.length})',
                    ),
                  ),
                  SizedBox(width: 6.w),
                  ...UserRole.values.map(
                    (role) => Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: ChoiceChip(
                        selected: _roleFilter == role,
                        onSelected: (_) =>
                            setState(() => _roleFilter = role),
                        label: Text(role.shortLabel(isArabic)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            // Members Cards List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
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
              ),
            ),
          ],
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
