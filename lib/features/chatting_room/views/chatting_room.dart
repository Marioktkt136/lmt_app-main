import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../../../core/widgets/lmt_search_bar.dart';
import '../cubit/chat_cubit.dart';
import '../widgets/chat_group_form_sheet.dart';
import '../widgets/chat_group_tile.dart';
import '../widgets/group_conversation_room.dart';
import 'group_conversation_page.dart';

/// Chatting Room View displaying Chatting Groups.
///
/// - On compact mobile screens (`< 960px`), tapping a group pushes
///   [GroupConversationPage] fullscreen.
/// - On wide Web/Desktop viewports (`>= 960px`), displays a responsive
///   Master-Detail split layout with the groups list alongside the active
///   [GroupConversationRoom].
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
  String? _desktopSelectedGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialGroupId = context.read<LmtCubit>().state.selectedChatGroupId;
      if (initialGroupId != null) {
        _openGroup(initialGroupId);
      }
    });
  }

  bool _isDesktopSplit(BuildContext context) =>
      MediaQuery.sizeOf(context).width >=
      AdaptiveBreakpoints.desktopSplitMinWidth;

  Future<void> _openGroup(String groupId, {bool? forceSplit}) async {
    if (!mounted) return;
    final state = context.read<LmtCubit>().state;
    final targetGroup =
        state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    if (targetGroup == null ||
        !targetGroup.memberIds.contains(state.currentUser.id)) {
      context.read<LmtCubit>().selectChatGroup(null);
      return;
    }

    context.read<LmtCubit>().selectChatGroup(null);
    if (forceSplit ?? _isDesktopSplit(context)) {
      setState(() => _desktopSelectedGroupId = groupId);
      return;
    }

    if (_isPushingGroup) return;
    _isPushingGroup = true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GroupConversationPage(groupId: groupId),
      ),
    );
    _isPushingGroup = false;
  }

  Widget _buildGroupListPane({
    required BuildContext context,
    required LmtState state,
    required List<ChatGroupModel> groups,
    required String? activeDesktopId,
    required bool isSplit,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final canManageGroups = state.currentUser.role.canManageGroups;
    final canDeleteGroups = state.currentUser.role.canDeleteGroups;

    return Column(
      children: [
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
                      isSelected: isSplit && activeDesktopId == group.id,
                      onTap: () => _openGroup(group.id, forceSplit: isSplit),
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LmtCubit, LmtState>(
      listenWhen: (prev, curr) =>
          curr.selectedChatGroupId != null &&
          prev.selectedChatGroupId != curr.selectedChatGroupId,
      listener: (context, state) {
        final targetGroupId = state.selectedChatGroupId;
        if (targetGroupId != null) {
          _openGroup(targetGroupId);
        }
      },
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final groups = state.sortedChatGroups.where((g) {
          if (!g.memberIds.contains(state.currentUser.id)) return false;
          if (_showPinnedOnly && !g.isPinned) return false;
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return g.name.toLowerCase().contains(q) ||
              g.description.toLowerCase().contains(q) ||
              g.adminName.toLowerCase().contains(q);
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSplit = constraints.maxWidth >=
                AdaptiveBreakpoints.desktopSplitMinWidth;
            if (!isSplit) {
              return AdaptiveContentBox(
                maxWidth: 820,
                child: _buildGroupListPane(
                  context: context,
                  state: state,
                  groups: groups,
                  activeDesktopId: null,
                  isSplit: false,
                ),
              );
            }

            final memberGroups = state.sortedChatGroups
                .where((g) => g.memberIds.contains(state.currentUser.id))
                .toList();
            final activeGroup = memberGroups
                    .where((g) => g.id == _desktopSelectedGroupId)
                    .firstOrNull ??
                groups.firstOrNull ??
                memberGroups.firstOrNull;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 340,
                  child: _buildGroupListPane(
                    context: context,
                    state: state,
                    groups: groups,
                    activeDesktopId: activeGroup?.id,
                    isSplit: true,
                  ),
                ),
                VerticalDivider(
                  width: 24,
                  thickness: 1,
                  color: AppColors.borderOf(context),
                ),
                Expanded(
                  child: activeGroup == null
                      ? LmtEmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          message: isArabic
                              ? 'اختر مجموعة محادثة لبدء المراسلة'
                              : 'Select a chat group to start messaging',
                        )
                      : GroupConversationRoom(
                          key: ValueKey('desktop_room_${activeGroup.id}'),
                          group: activeGroup,
                          showInlineHeader: true,
                          onBack: () =>
                              setState(() => _desktopSelectedGroupId = null),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
