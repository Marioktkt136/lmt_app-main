import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../../../core/widgets/lmt_search_bar.dart';
import '../cubit/chat_cubit.dart';
import '../widgets/chat_group_form_sheet.dart';
import '../widgets/chat_group_tile.dart';
import 'group_conversation_page.dart';

/// Chatting Room View displaying the Chatting Groups list and pushing
/// [GroupConversationPage] as a dedicated full-screen route when any group is
/// opened (so popping/backing always returns to the Groups List).
class ChattingRoom extends StatefulWidget {
  /// Creates a [ChattingRoom].
  const ChattingRoom({super.key});

  @override
  State<ChattingRoom> createState() => _ChattingRoomState();
}

class _ChattingRoomState extends State<ChattingRoom> {
  String _searchQuery = '';
  bool _showPinnedOnly = false;
  bool _isPushingGroup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialGroupId = context.read<LmtCubit>().state.selectedChatGroupId;
      if (initialGroupId != null) {
        _openGroupScreen(initialGroupId);
      }
    });
  }

  Future<void> _openGroupScreen(String groupId) async {
    if (_isPushingGroup || !mounted) return;
    final state = context.read<LmtCubit>().state;
    final targetGroup =
        state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    if (targetGroup == null ||
        !targetGroup.memberIds.contains(state.currentUser.id)) {
      context.read<LmtCubit>().selectChatGroup(null);
      return;
    }
    _isPushingGroup = true;
    context.read<LmtCubit>().selectChatGroup(null);

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GroupConversationPage(groupId: groupId),
      ),
    );
    _isPushingGroup = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LmtCubit, LmtState>(
      listenWhen: (prev, curr) =>
          curr.selectedChatGroupId != null &&
          prev.selectedChatGroupId != curr.selectedChatGroupId,
      listener: (context, state) {
        final targetGroupId = state.selectedChatGroupId;
        if (targetGroupId != null) {
          _openGroupScreen(targetGroupId);
        }
      },
      builder: (context, state) {
        return _buildGroupsListView(context, state);
      },
    );
  }

  Widget _buildGroupsListView(BuildContext context, LmtState state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final canManageGroups = state.currentUser.role.canManageGroups;
    final canDeleteGroups = state.currentUser.role.canDeleteGroups;

    final groups = state.sortedChatGroups.where((g) {
      if (!g.memberIds.contains(state.currentUser.id)) return false;
      if (_showPinnedOnly && !g.isPinned) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return g.name.toLowerCase().contains(q) ||
          g.description.toLowerCase().contains(q) ||
          g.adminName.toLowerCase().contains(q);
    }).toList();

    return AdaptiveContentBox(
      maxWidth: 820,
      child: Column(
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
                      canEditGroups: canManageGroups,
                      canDeleteGroups: canDeleteGroups,
                      onTap: () => _openGroupScreen(group.id),
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
    ),
    );
  }
}
