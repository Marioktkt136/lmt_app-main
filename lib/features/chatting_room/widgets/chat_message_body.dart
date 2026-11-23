import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/expandable_text.dart';
import '../views/chat_media_viewer_page.dart';
import 'voice_note_player_widget.dart';

/// Renders the inner body of a [ChatMessageModel] according to its [MessageType]
/// (Text, Voice Note, Image, Video, File attachment, or Sticker).
class ChatMessageBody extends StatelessWidget {
  /// The message model to render.
  final ChatMessageModel msg;

  /// Whether this voice note message is currently playing.
  final bool isPlayingVoice;

  /// Callback invoked when the voice note play/pause button is tapped.
  final VoidCallback onToggleVoicePlay;

  /// Callback invoked when the user triggers a Reply from the fullscreen media viewer.
  final ValueChanged<ChatMessageModel> onReply;

  /// Optional callback invoked to save a received sticker into My Saved Stickers.
  final ValueChanged<ChatMessageModel>? onSaveSticker;

  /// Creates a [ChatMessageBody].
  const ChatMessageBody({
    super.key,
    required this.msg,
    required this.isPlayingVoice,
    required this.onToggleVoicePlay,
    required this.onReply,
    this.onSaveSticker,
  });

  void _openFullscreenMedia(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatMediaViewerPage(
          message: msg,
          onReply: onReply,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final isVideoFile = msg.type == MessageType.video ||
        (msg.type == MessageType.image &&
            DeviceFileHelper.isVideoPath(msg.attachmentPath));

    switch (msg.type) {
      case MessageType.voiceNote:
        return VoiceNotePlayerWidget(
          msg: msg,
          isPlayingVoice: isPlayingVoice,
          onToggleVoicePlay: onToggleVoicePlay,
        );

      case MessageType.image:
      case MessageType.video:
        if (isVideoFile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () => _openFullscreenMedia(context),
                child: Container(
                  height: 155.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32.sp,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Text(
                              msg.attachmentPath?.split('/').last ??
                                  (isArabic ? 'فيديو 🎬' : 'Video 🎬'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 6.h,
                        right: 6.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.fullscreen_rounded,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (msg.content.isNotEmpty) ...[
                SizedBox(height: 6.h),
                LmtExpandableText(
                  text: msg.content,
                  style: TextStyle(fontSize: 13.sp, color: textPrimary),
                ),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () => _openFullscreenMedia(context),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      height: 155.h,
                      width: double.infinity,
                      color: Colors.black12,
                      child: DeviceFileHelper.buildImage(
                        msg.attachmentPath ?? AppAssets.actIcon,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6.h,
                    right: 6.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.fullscreen_rounded,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (msg.content.isNotEmpty) ...[
              SizedBox(height: 6.h),
              LmtExpandableText(
                text: msg.content,
                style: TextStyle(fontSize: 13.sp, color: textPrimary),
              ),
            ],
          ],
        );

      case MessageType.file:
        return InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            final path = msg.attachmentPath;
            if (path != null && !DeviceFileHelper.isAssetPath(path)) {
              DeviceFileHelper.openPath(path);
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
                        DeviceFileHelper.displayFileName(
                          msg.attachmentPath,
                          fallback: 'Document.pdf',
                        ),
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
              Stack(
                children: [
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
                  if (onSaveSticker != null)
                    Positioned(
                      bottom: 4.h,
                      right: 4.w,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => onSaveSticker!(msg),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark_add_rounded,
                                size: 13.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                isArabic ? 'حفظ' : 'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
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
        return LmtExpandableText(
          text: msg.content,
          style: TextStyle(fontSize: 13.5.sp, color: textPrimary, height: 1.4),
        );
    }
  }
}
