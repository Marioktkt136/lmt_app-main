import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_avatar.dart';
import 'chat_message_body.dart';

/// Displays an individual chat message bubble supporting Text, Voice Note,
/// Image, File attachment, Sticker, Replies, Reactions, and Seen/Listened count.
class ChatMessageBubble extends StatelessWidget {
  /// The message model to render.
  final ChatMessageModel msg;

  /// Whether this message was sent by the current user.
  final bool isMe;

  /// Whether this voice note message is currently playing.
  final bool isPlayingVoice;

  /// Callback invoked when the bubble is tapped or long-pressed.
  final VoidCallback onShowActions;

  /// Callback invoked when the seen/listened count is tapped.
  final VoidCallback onShowSeenBy;

  /// Callback invoked when an emoji reaction pill is tapped.
  final ValueChanged<String> onToggleReaction;

  /// Callback invoked when the voice note play/pause button is tapped.
  final VoidCallback onToggleVoicePlay;

  /// Callback invoked when Reply is triggered from a fullscreen media viewer.
  final ValueChanged<ChatMessageModel> onReply;

  /// Optional callback invoked to save a sticker message to user's stickers.
  final ValueChanged<ChatMessageModel>? onSaveSticker;

  /// Optional callback invoked when the quoted reply box inside this bubble
  /// is tapped, scrolling to and highlighting the original message.
  final VoidCallback? onTapReplyPreview;

  /// Whether this bubble is temporarily highlighted and pointed at as the
  /// target of a tapped reply preview.
  final bool isHighlighted;

  /// Optional live avatar path for the sender resolved from `state.members`.
  final String? senderAvatarOverride;

  /// Creates a [ChatMessageBubble].
  const ChatMessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.isPlayingVoice,
    required this.onShowActions,
    required this.onShowSeenBy,
    required this.onToggleReaction,
    required this.onToggleVoicePlay,
    required this.onReply,
    this.onSaveSticker,
    this.onTapReplyPreview,
    this.isHighlighted = false,
    this.senderAvatarOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    return GestureDetector(
      onLongPress: onShowActions,
      onTap: onShowActions,
      child: Align(
        alignment: isMe
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.sizeOf(context).width * 0.78).clamp(0.0, 520.0),
          ),
          margin: EdgeInsets.symmetric(
            vertical: 6.h,
            horizontal: 4.w,
          ),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isHighlighted
                ? primary.withValues(alpha: 0.26)
                : (isMe
                    ? primary.withValues(alpha: 0.14)
                    : AppColors.cardSurfaceOf(context)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
              bottomRight: Radius.circular(isMe ? 4.r : 18.r),
            ),
            border: Border.all(
              color: isHighlighted
                  ? primary
                  : (isMe
                      ? primary.withValues(alpha: 0.45)
                      : primary.withValues(alpha: 0.2)),
              width: isHighlighted ? 2.2 : 1.0,
            ),
            boxShadow: [
              if (isHighlighted)
                BoxShadow(
                  color: primary.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ...AppColors.cardShadows(
                context,
                accent: primary,
                intensity: isHighlighted ? 0.9 : 0.55,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isHighlighted) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 6.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 13.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isArabic
                            ? 'الرسالة الأصلية 👈'
                            : 'Original message 👈',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Sender Circular Avatar, Name & Role Badge
              Row(
                children: [
                  LmtAvatar(
                    imagePath: senderAvatarOverride ?? msg.senderAvatar,
                    radius: 13,
                    showShadow: false,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      '${msg.senderName} ${msg.senderRole.badgeEmoji}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.more_horiz_rounded,
                    size: 16.sp,
                    color: textSecondary,
                  ),
                ],
              ),

              // Forwarded Tag
              if (msg.forwardedFromGroup != null) ...[
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forward_rounded,
                      size: 13.sp,
                      color: textSecondary,
                    ),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        isArabic
                            ? 'محولة من: ${msg.forwardedFromGroup}'
                            : 'Forwarded from ${msg.forwardedFromGroup}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontStyle: FontStyle.italic,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Replied Message Preview
              if (msg.replyToPreview != null ||
                  msg.replyToMessageId != null) ...[
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Material(
                    color: primary.withValues(alpha: 0.08),
                    child: InkWell(
                      onTap: onTapReplyPreview,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(
                              color: primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.replyToSenderName ?? '',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                    ),
                                  ),
                                  Text(
                                    (msg.replyToPreview?.trim().isNotEmpty ??
                                            false)
                                        ? msg.replyToPreview!
                                        : (isArabic ? 'رسالة' : 'Message'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (onTapReplyPreview != null) ...[
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.north_rounded,
                                size: 14.sp,
                                color: primary.withValues(alpha: 0.8),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 6.h),

              // Message Body by Type
              ChatMessageBody(
                msg: msg,
                isPlayingVoice: isPlayingVoice,
                onToggleVoicePlay: onToggleVoicePlay,
                onReply: onReply,
                onSaveSticker: onSaveSticker,
              ),

              SizedBox(height: 6.h),

              // Reactions Row
              if (msg.reactions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: msg.reactions.entries.map((e) {
                      return InkWell(
                        onTap: () => onToggleReaction(e.key),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: border),
                          ),
                          child: Text(
                            '${e.key} ${e.value.length}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Timestamp, Edited flag & Seen/Listened indicator (Sender ONLY)
              Builder(
                builder: (context) {
                  final viewerCount = msg.seenBy
                      .where((s) => s.memberId != msg.senderId)
                      .length;
                  return Row(
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(msg.sentAt),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: textSecondary,
                        ),
                      ),
                      if (msg.isEdited) ...[
                        SizedBox(width: 4.w),
                        Text(
                          isArabic ? '(معدلة)' : '(edited)',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontStyle: FontStyle.italic,
                            color: textSecondary,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (isMe)
                        InkWell(
                          onTap: onShowSeenBy,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                viewerCount > 0
                                    ? Icons.done_all_rounded
                                    : Icons.check_rounded,
                                size: 14.sp,
                                color:
                                    viewerCount > 0 ? accentGreen : textSecondary,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '$viewerCount',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: viewerCount > 0
                                      ? accentGreen
                                      : textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
