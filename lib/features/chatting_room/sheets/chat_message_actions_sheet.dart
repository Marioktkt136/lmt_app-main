import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/device_file_helper.dart';
import '../cubit/chat_cubit.dart';

const List<String> _quickEmojis = [
  '❤️',
  '👍',
  '🔥',
  '👏',
  '😂',
  '😮',
  '😢',
  '🙏',
  '🎭',
  '🎬',
  '✨',
  '💯',
];

/// Displays the message actions bottom sheet (Reactions, Reply, Copy, Forward,
/// Seen By, Edit by sender only, Delete by group admin or sender only).
void showChatMessageActionsSheet({
  required BuildContext context,
  required LmtState state,
  required ChatGroupModel group,
  required ChatMessageModel message,
  required ValueChanged<ChatMessageModel> onReply,
  required ValueChanged<ChatMessageModel> onEdit,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final isSender = message.senderId == state.currentUser.id;
  final isGroupAdmin = group.adminId == state.currentUser.id ||
      state.currentUser.role == UserRole.admin;
  final canDelete = isSender || isGroupAdmin;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      final textPrimary = AppColors.textPrimaryOf(ctx);
      final primary = AppColors.primaryOf(ctx);

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'تفاعل مع الرسالة بأي إيموجي'
                    : 'React with any Emoji',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryOf(ctx),
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                alignment: WrapAlignment.center,
                children: [
                  ..._quickEmojis.map(
                    (emoji) => InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        context.read<LmtCubit>().toggleMessageReaction(
                              messageId: message.id,
                              emoji: emoji,
                            );
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: 20.sp),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCustomEmojiInputDialog(context, message);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_reaction_outlined,
                        color: primary,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              ListTile(
                dense: true,
                leading: Icon(Icons.reply_rounded, color: primary),
                title: Text(
                  isArabic ? 'رد على الرسالة (Reply)' : 'Reply to message',
                  style: TextStyle(color: textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply(message);
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.copy_rounded, color: primary),
                title: Text(
                  isArabic ? 'نسخ محتوى الرسالة (Copy)' : 'Copy message text',
                  style: TextStyle(color: textPrimary),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تم نسخ الرسالة للحافظة'
                            : 'Message copied to clipboard',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.forward_rounded, color: primary),
                title: Text(
                  isArabic
                      ? 'إعادة توجيه لمجموعة أخرى (Forward)'
                      : 'Forward to another group',
                  style: TextStyle(color: textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showChatForwardDialog(context, state, message);
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.done_all_rounded,
                  color: AppColors.accentGreenOf(ctx),
                ),
                title: Text(
                  message.type == MessageType.voiceNote
                      ? (isArabic
                          ? 'من قرأ واستمع للرسالة الصوتية (${message.seenBy.length})'
                          : 'Who Seen & Listened (${message.seenBy.length})')
                      : (isArabic
                          ? 'من قرأ الرسالة (${message.seenBy.length})'
                          : 'Seen By (${message.seenBy.length})'),
                  style: TextStyle(color: textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showChatSeenBySheet(context, message);
                },
              ),
              if (isSender)
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                  title: Text(
                    isArabic
                        ? 'تعديل الرسالة (مرسل الرسالة فقط)'
                        : 'Edit Message (Sender only)',
                    style: TextStyle(color: textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit(message);
                  },
                ),
              if (canDelete)
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    isArabic
                        ? 'حذف الرسالة (المسؤول أو المرسل فقط)'
                        : 'Delete Message (Group Admin or Sender only)',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    context.read<LmtCubit>().deleteChatMessage(
                          messageId: message.id,
                          groupId: group.id,
                        );
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

void _showCustomEmojiInputDialog(
  BuildContext context,
  ChatMessageModel message,
) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final emojiCtrl = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        isArabic ? 'أدخل أي إيموجي للتفاعل' : 'Enter any Emoji',
      ),
      content: TextField(
        controller: emojiCtrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '🎉 🤩 🙌 💐 🕊️ ...',
          labelText: isArabic ? 'الإيموجي' : 'Emoji',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final val = emojiCtrl.text.trim();
            if (val.isNotEmpty) {
              context.read<LmtCubit>().toggleMessageReaction(
                    messageId: message.id,
                    emoji: val,
                  );
            }
            Navigator.pop(ctx);
          },
          child: Text(isArabic ? 'تفاعل' : 'React'),
        ),
      ],
    ),
  );
}

/// Displays the bottom sheet to forward a [ChatMessageModel] to another group.
void showChatForwardDialog(
  BuildContext context,
  LmtState state,
  ChatMessageModel message,
) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'اختر المجموعة لإعادة توجيه الرسالة إليها:'
                  : 'Select a group to forward message to:',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimaryOf(ctx),
              ),
            ),
            SizedBox(height: 12.h),
            ...state.chatGroups.map(
              (grp) => ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      DeviceFileHelper.imageProviderFor(grp.imagePath),
                ),
                title: Text(grp.name),
                subtitle: Text('${grp.memberIds.length} members'),
                trailing: const Icon(Icons.send_rounded),
                onTap: () {
                  context.read<LmtCubit>().forwardMessageToGroup(
                        message: message,
                        targetGroupId: grp.id,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تم إعادة توجيه الرسالة إلى ${grp.name}'
                            : 'Forwarded to ${grp.name}',
                      ),
                      backgroundColor: AppColors.accentGreenOf(context),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Displays the bottom sheet listing all members who have seen (or listened to)
/// a [ChatMessageModel].
void showChatSeenBySheet(BuildContext context, ChatMessageModel message) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final isVoice = message.type == MessageType.voiceNote;
  final accentGreen = AppColors.accentGreenOf(context);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.done_all_rounded, color: accentGreen),
                SizedBox(width: 8.w),
                Text(
                  isVoice
                      ? (isArabic
                          ? 'من قرأ واستمع للرسالة الصوتية 🎤'
                          : 'Seen & Listened By 🎤')
                      : (isArabic
                          ? 'من قرأ الرسالة (Seen By) 👀'
                          : 'Seen By 👀'),
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimaryOf(ctx),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...message.seenBy.map(
              (seen) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: AssetImage(seen.avatarPath),
                ),
                title: Text(
                  seen.memberName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(ctx),
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy • hh:mm a').format(seen.timestamp),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondaryOf(ctx),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVoice && seen.hasListened) ...[
                      Icon(
                        Icons.headphones_rounded,
                        color: accentGreen,
                        size: 18.sp,
                      ),
                      SizedBox(width: 4.w),
                    ],
                    Icon(
                      Icons.done_all_rounded,
                      color: accentGreen,
                      size: 18.sp,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
