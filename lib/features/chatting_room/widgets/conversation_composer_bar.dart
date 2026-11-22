import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';

/// Banner shown above the chat input when the user is replying to or editing
/// an existing [ChatMessageModel].
class ReplyEditBanner extends StatelessWidget {
  /// Message being replied to (if any).
  final ChatMessageModel? replyingTo;

  /// Message being edited (if any).
  final ChatMessageModel? editingMessage;

  /// Clears the active reply or edit state.
  final VoidCallback onCancel;

  /// Creates a [ReplyEditBanner].
  const ReplyEditBanner({
    super.key,
    required this.replyingTo,
    required this.editingMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (replyingTo == null && editingMessage == null) {
      return const SizedBox.shrink();
    }
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            editingMessage != null ? Icons.edit_rounded : Icons.reply_rounded,
            color: primary,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              editingMessage != null
                  ? '${isArabic ? 'تعديل الرسالة:' : 'Editing:'} ${editingMessage!.content}'
                  : '${isArabic ? 'الرد على' : 'Replying to'} ${replyingTo!.senderName}: ${replyingTo!.content}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, color: textPrimary),
            ),
          ),
          IconButton(
            tooltip: isArabic ? 'إلغاء' : 'Cancel',
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

/// Active voice-note recording bar displaying the elapsed seconds timer,
/// cancel button, and send button.
class VoiceRecordingBar extends StatelessWidget {
  /// Elapsed recording duration in seconds.
  final int recordingSeconds;

  /// Cancels and discards the current recording.
  final VoidCallback onCancel;

  /// Stops and sends the recorded voice note.
  final VoidCallback onSend;

  /// Creates a [VoiceRecordingBar].
  const VoiceRecordingBar({
    super.key,
    required this.recordingSeconds,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final accentGreen = AppColors.accentGreenOf(context);
    final formatted = recordingSeconds.toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: AppColors.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isArabic
                  ? 'جاري التسجيل... 00:$formatted'
                  : 'Recording Voice Note... 00:$formatted',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(isArabic ? 'إرسال' : 'Send'),
          ),
        ],
      ),
    );
  }
}

/// Bottom chat composer bar that ALWAYS preserves a Left-to-Right arrangement:
/// `(+) Attachment`, `(😊) Stickers`, `[TextField]`, `(🎤) Mic`, `(➤) Send`.
class ConversationComposerBar extends StatelessWidget {
  /// Controller for the message input field.
  final TextEditingController messageController;

  /// Opens the media/file attachment menu sheet.
  final VoidCallback onOpenAttachments;

  /// Opens the WhatsApp-style saved stickers sheet.
  final VoidCallback onOpenStickers;

  /// Starts recording a voice note.
  final VoidCallback onStartVoiceRecording;

  /// Sends the typed text message.
  final VoidCallback onSendText;

  /// Optional callback invoked whenever the text input changes (used for typing animation).
  final ValueChanged<String>? onChanged;

  /// Creates a [ConversationComposerBar].
  const ConversationComposerBar({
    super.key,
    required this.messageController,
    required this.onOpenAttachments,
    required this.onOpenStickers,
    required this.onStartVoiceRecording,
    required this.onSendText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: AppColors.cardShadows(
          context,
          accent: primary,
          intensity: 0.65,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            IconButton(
              tooltip: isArabic ? 'مرفقات وملصقات' : 'Attachments',
              onPressed: onOpenAttachments,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: primary,
              ),
            ),
            IconButton(
              tooltip: isArabic ? 'ملصقات' : 'Stickers',
              onPressed: onOpenStickers,
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: primary,
              ),
            ),
            Expanded(
              child: Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: TextField(
                  controller: messageController,
                  onChanged: onChanged,
                  style: TextStyle(color: textPrimary, fontSize: 13.sp),
                  onSubmitted: (_) => onSendText(),
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'اكتب رسالة للفريق...'
                        : 'Type a message...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            IconButton(
              tooltip: isArabic ? 'تسجيل صوتي' : 'Voice Note',
              onPressed: onStartVoiceRecording,
              icon: Icon(Icons.mic_none_rounded, color: primary),
            ),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: primary),
              tooltip: isArabic ? 'إرسال' : 'Send',
              onPressed: onSendText,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
