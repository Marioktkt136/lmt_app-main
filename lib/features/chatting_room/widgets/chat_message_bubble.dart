import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';

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
              _buildMessageBody(
                context,
                textPrimary,
                textSecondary,
                primary,
                accentGreen,
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

  Widget _buildMessageBody(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    Color primary,
    Color accentGreen,
  ) {
    switch (msg.type) {
      case MessageType.voiceNote:
        return Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: accentGreen),
                onPressed: onToggleVoicePlay,
                icon: Icon(
                  isPlayingVoice
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: isPlayingVoice ? 0.65 : 0.3,
                      color: accentGreen,
                      backgroundColor: accentGreen.withValues(alpha: 0.2),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '🎤 00:${(msg.voiceDurationSeconds ?? 15).toString().padLeft(2, '0')} • ${msg.content}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.sp, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                height: 150.h,
                width: double.infinity,
                color: Colors.black12,
                child: DeviceFileHelper.buildImage(
                  msg.attachmentPath ?? AppAssets.actIcon,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (msg.content.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                msg.content,
                style: TextStyle(fontSize: 13.sp, color: textPrimary),
              ),
            ],
          ],
        );

      case MessageType.file:
        return InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            if (msg.attachmentPath != null &&
                !DeviceFileHelper.isAssetPath(msg.attachmentPath!) &&
                msg.attachmentPath!.contains('/')) {
              OpenFilex.open(msg.attachmentPath!);
            }
          },
          child: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: primary, size: 28.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.attachmentPath?.split('/').last ?? 'Document.pdf',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${msg.fileSize ?? '1.5 MB'} • ${msg.content}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.sp, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.download_rounded, color: primary),
              ],
            ),
          ),
        );

      case MessageType.sticker:
        final hasStickerImage =
            msg.attachmentPath != null && msg.attachmentPath!.trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasStickerImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: SizedBox(
                  width: 115.w,
                  height: 115.w,
                  child: DeviceFileHelper.buildImage(
                    msg.attachmentPath!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (msg.content.trim().isNotEmpty &&
                msg.content.trim() != 'Sticker' &&
                msg.content.trim() != 'ملصق') ...[
              if (hasStickerImage) SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ],
        );

      case MessageType.text:
        return Text(
          msg.content,
          style: TextStyle(fontSize: 13.5.sp, color: textPrimary, height: 1.4),
        );
    }
  }
}
