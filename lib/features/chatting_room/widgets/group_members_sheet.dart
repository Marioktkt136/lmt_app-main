import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../cubit/chat_cubit.dart';

/// Displays live members and group administrators for [groupId], enabling
/// authorized Group Admins and App Administrators to add/remove members,
/// promote or demote multiple Co-Admins, transfer full leadership in their
/// place, or exit the group.
void showGroupMembersSheet(BuildContext context, String groupId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) => _GroupMembersSheetBody(groupId: groupId),
  );
}

class _GroupMembersSheetBody extends StatefulWidget {
  final String groupId;

  const _GroupMembersSheetBody({required this.groupId});

  @override
  State<_GroupMembersSheetBody> createState() => _GroupMembersSheetBodyState();
}

class _GroupMembersSheetBodyState extends State<_GroupMembersSheetBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _showAddMembersSection = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmTransferLeadership(
    BuildContext context,
    ChatGroupModel group,
    MemberModel target,
    bool isArabic,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          isArabic ? 'نقل إدارة المجموعة؟' : 'Transfer Group Leadership?',
        ),
        content: Text(
          isArabic
              ? 'سيتم تعيين "${target.name}" مسؤولاً عن المجموعة بدلاً منك ومنحه كامل صلاحيات الإدارة والتعديل.'
              : '"${target.name}" will become the group admin in your place with full management authority.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(isArabic ? 'تأكيد النقل' : 'Transfer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<LmtCubit>().transferGroupOwnership(
          groupId: group.id,
          newOwnerId: target.id,
          stepDownSelf: true,
        );
  }

  Future<void> _confirmLeaveGroup(
    BuildContext context,
    ChatGroupModel group,
    bool isArabic,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isArabic ? 'مغادرة المجموعة؟' : 'Exit Group?'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من مغادرة "${group.name}"؟'
              : 'Are you sure you want to leave "${group.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(isArabic ? 'مغادرة' : 'Exit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<LmtCubit>().leaveChatGroup(group.id);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final group =
            state.chatGroups.where((g) => g.id == widget.groupId).firstOrNull;
        if (group == null || !group.memberIds.contains(state.currentUser.id)) {
          return Padding(
            padding: EdgeInsets.all(24.w),
            child: Center(
              child: Text(
                isArabic ? 'لم تعد عضواً في هذه المجموعة' : 'Group unavailable',
                style: TextStyle(color: textSecondary),
              ),
            ),
          );
        }

        final canManage = group.canUserEditGroup(state.currentUser);
        final memberMap = {for (final m in state.members) m.id: m};
        final groupMembers = group.memberIds
            .map((id) => memberMap[id])
            .whereType<MemberModel>()
            .toList();
        final nonMembers = state.members
            .where((m) => !group.memberIds.contains(m.id))
            .where((m) {
          if (_query.trim().isEmpty) return true;
          final q = _query.trim().toLowerCase();
          return m.name.toLowerCase().contains(q) ||
              m.id.toLowerCase().contains(q);
        }).toList();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollCtrl) {
            return Padding(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      LmtAvatar(
                        imagePath: group.imagePath,
                        radius: 26,
                        showShadow: false,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            if (group.description.trim().isNotEmpty)
                              Text(
                                group.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: textSecondary,
                                ),
                              ),
                            SizedBox(height: 2.h),
                            Text(
                              '${group.memberIds.length} ${isArabic ? 'عضو' : 'members'}',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canManage && nonMembers.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(
                            () => _showAddMembersSection =
                                !_showAddMembersSection,
                          ),
                          icon: Icon(
                            _showAddMembersSection
                                ? Icons.close_rounded
                                : Icons.person_add_alt_1_rounded,
                            size: 18.sp,
                          ),
                          label: Text(
                            _showAddMembersSection
                                ? (isArabic ? 'إغلاق' : 'Close')
                                : (isArabic ? 'إضافة' : 'Add'),
                          ),
                        ),
                    ],
                  ),
                  if (_showAddMembersSection && canManage) ...[
                    SizedBox(height: 10.h),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: isArabic
                            ? 'ابحث لإضافة عضو للمجموعة...'
                            : 'Search member to add...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (nonMembers.isEmpty)
                      Text(
                        isArabic
                            ? 'كل الأعضاء مضافون بالفعل'
                            : 'All matching members are already added',
                        style: TextStyle(fontSize: 12.sp, color: textSecondary),
                      )
                    else
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: nonMembers.map((m) {
                          return ActionChip(
                            avatar: Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16.sp,
                              color: accentGreen,
                            ),
                            label: Text(m.name),
                            onPressed: () {
                              context.read<LmtCubit>().updateChatGroup(
                                    group.copyWith(
                                      memberIds: [...group.memberIds, m.id],
                                    ),
                                  );
                            },
                          );
                        }).toList(),
                      ),
                  ],
                  SizedBox(height: 12.h),
                  Divider(height: 1, color: AppColors.borderOf(context)),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: groupMembers.length,
                      itemBuilder: (context, index) {
                        final member = groupMembers[index];
                        final isGroupAdmin =
                            group.isGroupAdminMember(member.id);
                        final isMe = member.id == state.currentUser.id;
                        final canRemoveThisMember = canManage &&
                            groupMembers.length > 1 &&
                            (!isMe || state.currentUser.role == UserRole.admin);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: LmtAvatar(
                            imagePath: member.avatarPath,
                            radius: 20,
                            showShadow: false,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isMe
                                      ? '${member.name} (${isArabic ? 'أنت' : 'You'})'
                                      : member.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              if (isGroupAdmin) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentGreen.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: accentGreen.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isArabic ? 'مسؤول جروب' : 'Group Admin',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: accentGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            member.specialistAt,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: textSecondary,
                            ),
                          ),
                          trailing: canManage && !isMe
                              ? PopupMenuButton<String>(
                                  onSelected: (action) {
                                    final cubit = context.read<LmtCubit>();
                                    if (action == 'toggle_admin') {
                                      cubit.setGroupMemberAdmin(
                                        groupId: group.id,
                                        memberId: member.id,
                                        isAdmin: !isGroupAdmin,
                                      );
                                    } else if (action == 'transfer') {
                                      _confirmTransferLeadership(
                                        context,
                                        group,
                                        member,
                                        isArabic,
                                      );
                                    } else if (action == 'remove' &&
                                        canRemoveThisMember) {
                                      cubit.updateChatGroup(
                                        group.copyWith(
                                          memberIds: group.memberIds
                                              .where((id) => id != member.id)
                                              .toList(),
                                          groupAdminIds: group.effectiveAdminIds
                                              .where((id) => id != member.id)
                                              .toList(),
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'toggle_admin',
                                      child: Row(
                                        children: [
                                          Icon(
                                            isGroupAdmin
                                                ? Icons.remove_moderator_outlined
                                                : Icons.admin_panel_settings_outlined,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isGroupAdmin
                                                ? (isArabic
                                                    ? 'إلغاء صلاحية مسؤول الجروب'
                                                    : 'Remove Group Admin')
                                                : (isArabic
                                                    ? 'تعيين كمسؤول جروب معي'
                                                    : 'Make Group Co-Admin'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'transfer',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.swap_horiz_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isArabic
                                                ? 'تعيين مسؤول بدلي'
                                                : 'Make Admin Instead of Me',
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (canRemoveThisMember)
                                      PopupMenuItem(
                                        value: 'remove',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.person_remove_outlined,
                                              size: 18,
                                              color: AppColors.error,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isArabic
                                                  ? 'إزالة من المجموعة'
                                                  : 'Remove from Group',
                                              style: const TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () =>
                          _confirmLeaveGroup(context, group, isArabic),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        isArabic ? 'مغادرة المجموعة' : 'Exit Group',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
