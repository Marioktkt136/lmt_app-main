import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../cubit/chat_cubit.dart';
import 'chat_group_form_sheet.dart';
import 'group_members_sheet.dart';

/// Full-width mobile [AppBar] for [GroupConversationPage].
///
/// - Harmonizes status bar and AppBar colors across Light Mode (`AppColors.primary`)
///   and Dark Mode (`AppColors.surfaceDark`).
/// - Tapping the group avatar, name, or member info opens [showChatGroupFormSheet]
///   so the user can update the group directly.
class ConversationHeaderBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// The active chat group being displayed.
  final ChatGroupModel group;

  /// Current state used for opening the group update sheet.
  final LmtState state;

  /// Callback invoked when the back button is tapped.
  final VoidCallback onBack;

  /// Whether to render the back arrow leading button (hidden in desktop split view).
  final bool showBackButton;

  /// Creates a [ConversationHeaderBar].
  const ConversationHeaderBar({
    super.key,
    required this.group,
    required this.state,
    required this.onBack,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(62.h);

  Future<void> _confirmAndLeave(BuildContext context, bool isArabic) async {
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
      onBack();
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, bool isArabic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isArabic ? 'حذف المجموعة؟' : 'Delete Group?'),
        content: Text(
          isArabic
              ? 'سيتم حذف "${group.name}" وجميع رسائلها نهائياً.'
              : 'Are you sure you want to permanently delete "${group.name}"?',
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
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<LmtCubit>().deleteChatGroup(group.id);
    if (context.mounted) {
      onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);
    final appBarBg = isDark ? AppColors.surfaceDark : AppColors.primary;
    final fgColor = isDark ? AppColors.textPrimaryDark : Colors.white;
    final subColor = isDark
        ? AppColors.textSecondaryDark
        : Colors.white.withValues(alpha: 0.88);
    final canEditGroup = group.canUserEditGroup(state.currentUser);
    final canDeleteGroup = state.currentUser.role.canDeleteGroups;

    return AppBar(
      backgroundColor: appBarBg,
      foregroundColor: fgColor,
      elevation: isDark ? 0 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 62.h,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: appBarBg,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      shape: isDark
          ? Border(
              bottom: BorderSide(
                color: primary.withValues(alpha: 0.28),
                width: 1,
              ),
            )
          : null,
      leading: showBackButton
          ? IconButton(
              tooltip: isArabic ? 'رجوع للمجموعات' : 'Back to groups',
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 19.sp,
                color: fgColor,
              ),
            )
          : const SizedBox.shrink(),
      leadingWidth: showBackButton ? null : 12,
      title: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: canEditGroup
            ? () => showChatGroupFormSheet(
                  context,
                  state,
                  existingGroup: group,
                )
            : () => showGroupMembersSheet(context, group.id),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
          child: Row(
            children: [
              LmtAvatar(
                imagePath: group.imagePath,
                radius: 20,
                showShadow: false,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: fgColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (canEditGroup) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.edit_outlined,
                            size: 13.sp,
                            color: subColor,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '${group.memberIds.length} ${isArabic ? 'عضو' : 'members'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: isArabic ? 'تثبيت المجموعة' : 'Pin Group',
          onPressed: () =>
              context.read<LmtCubit>().togglePinChatGroup(group.id),
          icon: Icon(
            group.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            color: group.isPinned
                ? (isDark ? primary : const Color(0xFFFFD54F))
                : subColor,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: isArabic ? 'خيارات المجموعة' : 'Group Options',
          icon: Icon(Icons.more_vert_rounded, color: fgColor),
          onSelected: (action) {
            if (action == 'members') {
              showGroupMembersSheet(context, group.id);
            } else if (action == 'edit') {
              showChatGroupFormSheet(context, state, existingGroup: group);
            } else if (action == 'leave') {
              _confirmAndLeave(context, isArabic);
            } else if (action == 'delete') {
              _confirmAndDelete(context, isArabic);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'members',
              child: Row(
                children: [
                  const Icon(Icons.group_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isArabic
                        ? 'أعضاء ومسؤولو المجموعة'
                        : 'Group Members & Admins',
                  ),
                ],
              ),
            ),
            if (canEditGroup)
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isArabic
                          ? 'تعديل الاسم والوصف والصورة'
                          : 'Edit Group Info & Image',
                    ),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'مغادرة المجموعة' : 'Exit Group',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ],
              ),
            ),
            if (canDeleteGroup)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'حذف المجموعة' : 'Delete Group',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
