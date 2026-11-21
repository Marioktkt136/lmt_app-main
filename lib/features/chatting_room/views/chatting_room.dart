import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/chat_cubit.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../../../core/widgets/lmt_search_bar.dart';
import '../widgets/chat_group_form_sheet.dart';
import '../widgets/chat_group_tile.dart';
import '../widgets/group_conversation_room.dart';

/// Chatting Room View coordinating the Chatting Groups list and the
/// active [GroupConversationRoom].
class ChattingRoom extends StatefulWidget {
  /// Creates a [ChattingRoom].
  const ChattingRoom({super.key});

  @override
  State<ChattingRoom> createState() => _ChattingRoomState();
}

class _ChattingRoomState extends State<ChattingRoom> {
  String _searchQuery = '';
  bool _showPinnedOnly = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final selectedGroupId = state.selectedChatGroupId;
        if (selectedGroupId != null) {
          final group = state.chatGroups
              .where((g) => g.id == selectedGroupId)
              .firstOrNull;
          if (group != null) {
            return GroupConversationRoom(
              group: group,
              onBack: () => context.read<LmtCubit>().selectChatGroup(null),
            );
          }
        }

        return _buildGroupsListView(context, state);
      },
    );
  }

  Widget _buildGroupsListView(BuildContext context, LmtState state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final canManageGroups = state.currentUser.role.canManageGroups;

    final groups = state.sortedChatGroups.where((g) {
      if (_showPinnedOnly && !g.isPinned) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return g.name.toLowerCase().contains(q) ||
          g.description.toLowerCase().contains(q) ||
          g.adminName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Top Search & Action Bar
        LmtSearchBar(
          hintText: isArabic
              ? 'ابحث في مجموعات المحادثة...'
              : 'Search chatting groups...',
          onChanged: (val) => setState(() => _searchQuery = val),
          actions: [
            SizedBox(width: 8.w),
            FilterChip(
              selected: _showPinnedOnly,
              onSelected: (v) => setState(() => _showPinnedOnly = v),
              avatar: Icon(
                Icons.push_pin_rounded,
                size: 16.sp,
                color: _showPinnedOnly ? primary : textSecondary,
              ),
              label: Text(
                isArabic ? 'المثبتة' : 'Pinned',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
            if (canManageGroups) ...[
              SizedBox(width: 6.w),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: primary),
                tooltip: isArabic ? 'إنشاء مجموعة جديدة' : 'Create Chat Group',
                onPressed: () => showChatGroupFormSheet(context, state),
                icon: const Icon(Icons.group_add_rounded, color: Colors.white),
              ),
            ],
          ],
        ),
        SizedBox(height: 10.h),

        // Groups List
        Expanded(
          child: groups.isEmpty
              ? LmtEmptyState(
                  icon: Icons.forum_outlined,
                  message: isArabic
                      ? 'لا توجد مجموعات مطابقة للبحث'
                      : 'No matching chat groups found',
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6.h),
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final lastMsg = state.lastMessageForGroup(group.id);
                    final msgCount = state.messagesForGroup(group.id).length;

                    return ChatGroupTile(
                      group: group,
                      lastMessage: lastMsg,
                      messageCount: msgCount,
                      canManageGroups: canManageGroups,
                      onTap: () =>
                          context.read<LmtCubit>().selectChatGroup(group.id),
                      onTogglePin: () => context
                          .read<LmtCubit>()
                          .togglePinChatGroup(group.id),
                      onEdit: () => showChatGroupFormSheet(
                        context,
                        state,
                        existingGroup: group,
                      ),
                      onDelete: () =>
                          context.read<LmtCubit>().deleteChatGroup(group.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
