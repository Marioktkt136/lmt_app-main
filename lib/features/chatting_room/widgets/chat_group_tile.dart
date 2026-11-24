import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_avatar.dart';

/// Displays an individual chatting group row styled cleanly like the
/// recommended messaging list (avatar, group name, smart timestamp, last
/// message preview with status ticks/media icon, pin icon, and green unread
/// badge) without exposing creator/admin metadata.
class ChatGroupTile extends StatelessWidget {
  static const Color _unreadGreen = Color(0xFF25D366);
  static const Color _readBlue = Color(0xFF34B7F1);

  /// The group model to render.
  final ChatGroupModel group;

  /// Optional latest message in this group for previewing.
  final ChatMessageModel? lastMessage;

  /// Number of unseen incoming messages for the current user.
  final int unreadCount;

  /// ID of the active user viewing the list.
  final String currentUserId;

  /// Whether the current user has permission to edit this group.
  final bool canEditGroups;

  /// Whether the current user has permission to delete groups (App Admin only).
  final bool canDeleteGroups;

  /// Callback invoked when the group row is tapped.
  final VoidCallback onTap;

  /// Callback invoked when pin/unpin is selected.
  final VoidCallback onTogglePin;

  /// Callback invoked when edit group is selected.
  final VoidCallback onEdit;

  /// Callback invoked when the user chooses to leave this group.
  final VoidCallback onLeave;

  /// Callback invoked when delete group is selected.
  final VoidCallback onDelete;

  /// Whether this group is currently active in desktop split view.
  final bool isSelected;

  /// Creates a [ChatGroupTile].
  const ChatGroupTile({
    super.key,
    required this.group,
    required this.lastMessage,
    required this.unreadCount,
    required this.currentUserId,
    required this.canEditGroups,
    required this.canDeleteGroups,
    required this.onTap,
    required this.onTogglePin,
    required this.onEdit,
    required this.onLeave,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final hasUnread = unreadCount > 0;
    final last = lastMessage;
    final isSentByMe = last != null && last.senderId == currentUserId;
    final hasAnyOtherSeen = isSentByMe &&
        last.seenBy.any((s) => s.memberId != currentUserId);

    final previewText = last != null
        ? (isSentByMe
            ? _previewForMessage(last, isArabic)
            : '${last.senderName}: ${_previewForMessage(last, isArabic)}')
        : group.description;

    return Material(
      color: isSelected
          ? primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
          child: Row(
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (last != null) ...[
                          SizedBox(width: 8.w),
                          Text(
                            _formatGroupTimestamp(last.sentAt, isArabic),
                            style: TextStyle(
                              color: hasUnread ? _unreadGreen : textSecondary,
                              fontSize: 11.5.sp,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        if (isSentByMe) ...[
                          Icon(
                            Icons.done_all_rounded,
                            size: 16.sp,
                            color: hasAnyOtherSeen ? _readBlue : textSecondary,
                          ),
                          SizedBox(width: 4.w),
                        ] else if (last != null &&
                            _leadingIconForMessage(last.type) != null) ...[
                          Icon(
                            _leadingIconForMessage(last.type),
                            size: 15.sp,
                            color: last.type == MessageType.voiceNote
                                ? _unreadGreen
                                : textSecondary,
                          ),
                          SizedBox(width: 4.w),
                        ],
                        Expanded(
                          child: Text(
                            previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (group.isPinned || hasUnread) SizedBox(width: 8.w),
                        if (group.isPinned)
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: hasUnread ? 6.w : 0,
                            ),
                            child: Transform.rotate(
                              angle: 0.55,
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 15.sp,
                                color: textSecondary.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        if (hasUnread)
                          Container(
                            constraints: BoxConstraints(
                              minWidth: 21.w,
                              minHeight: 21.w,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: _unreadGreen,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 19.sp,
                  color: textSecondary.withValues(alpha: 0.72),
                ),
                onSelected: (action) {
                  if (action == 'pin') {
                    onTogglePin();
                  } else if (action == 'edit') {
                    onEdit();
                  } else if (action == 'leave') {
                    onLeave();
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
                              ? (isArabic
                                  ? 'إلغاء تثبيت المجموعة'
                                  : 'Unpin Group')
                              : (isArabic ? 'تثبيت المجموعة' : 'Pin Group'),
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
                  PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'مغادرة المجموعة' : 'Exit Group',
                          style: TextStyle(color: AppColors.warning),
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
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatGroupTimestamp(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(msgDay).inDays;

    if (diffDays <= 0) {
      return DateFormat('h:mm a').format(dt);
    }
    if (diffDays == 1) {
      return isArabic ? 'أمس' : 'Yesterday';
    }
    if (diffDays < 7) {
      return DateFormat('EEEE', isArabic ? 'ar' : 'en').format(dt);
    }
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  IconData? _leadingIconForMessage(MessageType type) {
    switch (type) {
      case MessageType.voiceNote:
        return Icons.mic_rounded;
      case MessageType.sticker:
        return Icons.sticky_note_2_outlined;
      case MessageType.image:
        return Icons.image_outlined;
      case MessageType.video:
        return Icons.videocam_outlined;
      case MessageType.file:
        return Icons.attach_file_rounded;
      case MessageType.text:
        return null;
    }
  }

  String _previewForMessage(ChatMessageModel msg, bool isArabic) {
    switch (msg.type) {
      case MessageType.voiceNote:
        final secs = msg.voiceDurationSeconds ?? 15;
        final mins = (secs ~/ 60).toString();
        final remSecs = (secs % 60).toString().padLeft(2, '0');
        return isArabic
            ? 'رسالة صوتية ($mins:$remSecs)'
            : 'Voice message ($mins:$remSecs)';
      case MessageType.image:
        return msg.content.trim().isNotEmpty
            ? msg.content
            : (isArabic ? 'صورة' : 'Photo');
      case MessageType.video:
        return msg.content.trim().isNotEmpty
            ? msg.content
            : (isArabic ? 'فيديو' : 'Video');
      case MessageType.file:
        return msg.content.trim().isNotEmpty
            ? msg.content
            : (isArabic ? 'ملف مرفق' : 'Attachment');
      case MessageType.sticker:
        return isArabic ? 'ملصق' : 'Sticker';
      case MessageType.text:
        return msg.content;
    }
  }
}
