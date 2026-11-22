import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';
import 'voice_note_player_widget.dart';

/// Renders the inner body of a [ChatMessageModel] according to its [MessageType]
/// (Text, Voice Note, Image, File attachment, or Sticker).
class ChatMessageBody extends StatelessWidget {
  /// The message model to render.
  final ChatMessageModel msg;

  /// Whether this voice note message is currently playing.
  final bool isPlayingVoice;

  /// Callback invoked when the voice note play/pause button is tapped.
  final VoidCallback onToggleVoicePlay;

  /// Creates a [ChatMessageBody].
  const ChatMessageBody({
    super.key,
    required this.msg,
    required this.isPlayingVoice,
    required this.onToggleVoicePlay,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    switch (msg.type) {
      case MessageType.voiceNote:
        return VoiceNotePlayerWidget(
          msg: msg,
          isPlayingVoice: isPlayingVoice,
          onToggleVoicePlay: onToggleVoicePlay,
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
