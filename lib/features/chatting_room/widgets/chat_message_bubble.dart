import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
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
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          margin: EdgeInsets.symmetric(
            vertical: 6.h,
            horizontal: 4.w,
          ),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isMe
                ? primary.withValues(alpha: 0.14)
                : AppColors.cardSurfaceOf(context),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
              bottomRight: Radius.circular(isMe ? 4.r : 18.r),
            ),
            border: Border.all(
              color: isMe
                  ? primary.withValues(alpha: 0.45)
                  : primary.withValues(alpha: 0.2),
            ),
            boxShadow: AppColors.cardShadows(
              context,
              accent: primary,
              intensity: 0.55,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender Name & Role Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${msg.senderName} ${msg.senderRole.badgeEmoji}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const Spacer(),
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
              if (msg.replyToPreview != null) ...[
                SizedBox(height: 6.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border(
                      left: BorderSide(
                        color: primary,
                        width: 3,
                      ),
                    ),
                  ),
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
                        msg.replyToPreview!,
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

              // Timestamp, Edited flag & Seen/Listened indicator
              Row(
                mainAxisSize: MainAxisSize.min,
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
                  InkWell(
                    onTap: onShowSeenBy,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 14.sp,
                          color: accentGreen,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${msg.seenBy.length}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
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
}
