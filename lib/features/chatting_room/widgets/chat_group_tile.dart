import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays an individual chatting group card in the groups list.
class ChatGroupTile extends StatelessWidget {
  /// The group model to render.
  final ChatGroupModel group;

  /// Optional latest message in this group for previewing.
  final ChatMessageModel? lastMessage;

  /// Total number of messages in this group.
  final int messageCount;

  /// Whether the current user has permission to edit groups (Admin & Editor).
  final bool canEditGroups;

  /// Whether the current user has permission to delete groups (Admin only).
  final bool canDeleteGroups;

  /// Callback invoked when the group card is tapped.
  final VoidCallback onTap;

  /// Callback invoked when pin/unpin is selected.
  final VoidCallback onTogglePin;

  /// Callback invoked when edit group is selected.
  final VoidCallback onEdit;

  /// Callback invoked when delete group is selected.
  final VoidCallback onDelete;

  /// Whether this group is currently active in desktop split view.
  final bool isSelected;

  /// Creates a [ChatGroupTile].
  const ChatGroupTile({
    super.key,
    required this.group,
    required this.lastMessage,
    required this.messageCount,
    required this.canEditGroups,
    required this.canDeleteGroups,
    required this.onTap,
    required this.onTogglePin,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return LmtCard(
      padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 10.w),
      borderRadius: 18.r,
      accentColor: primary,
      isHighlighted: isSelected || group.isPinned,
      onTap: onTap,
      child: Row(
        children: [
          LmtAvatar(
            imagePath: group.imagePath,
            radius: 26,
            badge: group.isPinned
                ? Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.push_pin_rounded,
                      size: 11.sp,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h6.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (lastMessage != null)
                      Text(
                        DateFormat('hh:mm a').format(lastMessage!.sentAt),
                        style: AppTypography.caption.copyWith(
                          color: textSecondary,
                          fontSize: 10.sp,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  lastMessage != null
                      ? '${lastMessage!.senderName}: ${_previewForMessage(lastMessage!, isArabic)}'
                      : group.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 13.sp,
                      color: primary,
                    ),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        '${isArabic ? 'مسؤول المجموعة:' : 'Admin:'} ${group.adminName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.people_alt_outlined,
                      size: 13.sp,
                      color: textSecondary,
                    ),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        '${group.memberIds.length} ${isArabic ? 'عضو' : 'members'} • $messageCount ${isArabic ? 'رسالة' : 'msgs'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: textSecondary,
            ),
            onSelected: (action) {
              if (action == 'pin') {
                onTogglePin();
              } else if (action == 'edit') {
                onEdit();
              } else if (action == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      group.isPinned
                          ? Icons.push_pin_outlined
                          : Icons.push_pin_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group.isPinned
                          ? (isArabic ? 'إلغاء تثبيت المجموعة' : 'Unpin Group')
                          : (isArabic ? 'تثبيت المجموعة بالأعلى' : 'Pin Group'),
                    ),
                  ],
                ),
              ),
              if (canEditGroups)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'تعديل بيانات المجموعة' : 'Update Group',
                      ),
                    ],
                  ),
                ),
              if (canDeleteGroups)
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
                        style: const TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _previewForMessage(ChatMessageModel msg, bool isArabic) {
    switch (msg.type) {
      case MessageType.voiceNote:
        return isArabic
            ? '🎤 رسالة صوتية (${msg.voiceDurationSeconds ?? 15} ث)'
            : '🎤 Voice note (${msg.voiceDurationSeconds ?? 15}s)';
      case MessageType.image:
        return isArabic ? '📷 صورة: ${msg.content}' : '📷 Image: ${msg.content}';
      case MessageType.video:
        return isArabic ? '🎬 فيديو: ${msg.content}' : '🎬 Video: ${msg.content}';
      case MessageType.file:
        return isArabic
            ? '📎 ملف: ${msg.attachmentPath ?? msg.content}'
            : '📎 File: ${msg.attachmentPath ?? msg.content}';
      case MessageType.sticker:
        return isArabic
            ? '🎭 ملصق: ${msg.content}'
            : '🎭 Sticker: ${msg.content}';
      case MessageType.text:
        return msg.content;
    }
  }
}
