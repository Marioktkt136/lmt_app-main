import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../cubit/chat_cubit.dart';

const List<String> _viewerQuickEmojis = [
  '❤️',
  '👍',
  '🔥',
  '👏',
  '😂',
  '😮',
  '🙏',
];

/// Fullscreen viewer for Chat Image & Video messages featuring:
/// - **Top Bar:** Sender name & avatar + Download button (`تحميل`).
/// - **Center:** Pinch-to-zoom image viewer OR Video Option Control center bar.
/// - **Bottom Bar:** Live Emoji Reactions toggle strip & Reply (`رد`) button.
class ChatMediaViewerPage extends StatefulWidget {
  /// The message whose image or video is displayed.
  final ChatMessageModel message;

  /// Callback invoked when the user taps Reply from fullscreen.
  final ValueChanged<ChatMessageModel> onReply;

  /// Creates a [ChatMediaViewerPage].
  const ChatMediaViewerPage({
    super.key,
    required this.message,
    required this.onReply,
  });

  @override
  State<ChatMediaViewerPage> createState() => _ChatMediaViewerPageState();
}

class _ChatMediaViewerPageState extends State<ChatMediaViewerPage> {
  final TransformationController _transformCtrl = TransformationController();
  bool _showControls = true;
  bool _isDownloading = false;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  Future<void> _downloadMedia(
    BuildContext context,
    ChatMessageModel liveMsg,
    bool isVideo,
  ) async {
    if (_isDownloading) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final path = liveMsg.attachmentPath ?? '';
    if (path.isEmpty) return;

    setState(() => _isDownloading = true);
    try {
      final rawName = path.split('/').last.split('\\').last;
      final ext = rawName.contains('.')
          ? rawName.split('.').last.toUpperCase()
          : (isVideo ? 'MP4' : 'PNG');

      final savedPath = await DeviceFileHelper.downloadAndOpenRealFile(
        SharedFileModel(
          id: liveMsg.id,
          title: rawName.isEmpty ? 'LMT_Media_$ext' : rawName,
          description: liveMsg.content,
          category: SharedFileType.image,
          imagePath: path,
          fileExtension: ext,
          fileSize: liveMsg.fileSize ?? (isVideo ? 'Video' : 'Image'),
          uploadedBy: liveMsg.senderName,
          uploadedAt: liveMsg.sentAt,
          localFilePath: DeviceFileHelper.isAssetPath(path) ? null : path,
        ),
        openAfterSave: false,
      );

      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 8),
              Text(isArabic ? 'تم التنزيل' : 'Downloaded'),
            ],
          ),
          content: Text(
            isArabic
                ? 'تم تنزيل الملف بنجاح ✅\n$savedPath'
                : 'Downloaded successfully ✅\n$savedPath',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(isArabic ? 'حسناً' : 'OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text(isArabic ? 'خطأ' : 'Error'),
              ],
            ),
            content: Text(
              isArabic ? 'تعذر تنزيل الملف' : 'Failed to download media',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(isArabic ? 'حسناً' : 'OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _openVideoInNativePlayer(
    BuildContext context,
    String path,
  ) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final error = await DeviceFileHelper.openPath(path);
    if (error != null && context.mounted) {
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Text(isArabic ? 'خطأ' : 'Error'),
            ],
          ),
          content: Text(
            isArabic
                ? 'تعذر فتح مشغل الفيديو: $error'
                : 'Unable to open video player: $error',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(isArabic ? 'حسناً' : 'OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final liveMsg =
            state.chatMessages.where((m) => m.id == widget.message.id).firstOrNull ??
                widget.message;
        final path = liveMsg.attachmentPath ?? AppAssets.actIcon;
        final isVideo = liveMsg.type == MessageType.video ||
            DeviceFileHelper.isVideoPath(path);
        final fileName = path.split('/').last.split('\\').last;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Center Stage (Zoomable Image OR Video Center Option Controls)
                Positioned.fill(
                  child: isVideo
                      ? Center(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 24.w),
                            padding: EdgeInsets.all(22.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      _openVideoInNativePlayer(context, path),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: EdgeInsets.all(22.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.45),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 46.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                Text(
                                  fileName.isEmpty
                                      ? (isArabic ? 'فيديو 🎬' : 'Video 🎬')
                                      : fileName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Video Option Control Row in Center
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _CenterVideoControl(
                                        icon: Icons.play_circle_fill_rounded,
                                        label: isArabic ? 'تشغيل الفيديو' : 'Play',
                                        onTap: () => _openVideoInNativePlayer(
                                          context,
                                          path,
                                        ),
                                      ),
                                      _CenterVideoControl(
                                        icon: Icons.open_in_new_rounded,
                                        label: isArabic
                                            ? 'فتح في مشغل'
                                            : 'External',
                                        onTap: () => _openVideoInNativePlayer(
                                          context,
                                          path,
                                        ),
                                      ),
                                      _CenterVideoControl(
                                        icon: Icons.download_rounded,
                                        label: isArabic ? 'حفظ' : 'Save',
                                        onTap: () => _downloadMedia(
                                          context,
                                          liveMsg,
                                          true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () =>
                              setState(() => _showControls = !_showControls),
                          onDoubleTap: () {
                            if (_transformCtrl.value != Matrix4.identity()) {
                              _resetZoom();
                            } else {
                              _transformCtrl.value = Matrix4.diagonal3Values(
                                2.2,
                                2.2,
                                1.0,
                              );
                            }
                          },
                          child: InteractiveViewer(
                            transformationController: _transformCtrl,
                            minScale: 0.8,
                            maxScale: 4.5,
                            child: Center(
                              child: DeviceFileHelper.buildImage(
                                path,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                ),

                // Top Bar (Sender Name & Avatar + Download Button)
                if (_showControls)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: isArabic ? 'رجوع' : 'Back',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                          LmtAvatar(
                            imagePath: liveMsg.senderAvatar,
                            radius: 17,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  liveMsg.senderName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy • hh:mm a')
                                      .format(liveMsg.sentAt),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: isArabic ? 'تنزيل' : 'Download',
                            onPressed: _isDownloading
                                ? null
                                : () =>
                                    _downloadMedia(context, liveMsg, isVideo),
                            icon: _isDownloading
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.download_rounded,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Bar (Caption + Live Reactions + React & Reply Controls)
                if (_showControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 12.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.92),
                            Colors.black.withValues(alpha: 0.72),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (liveMsg.content.trim().isNotEmpty) ...[
                            Text(
                              liveMsg.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5.sp,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: 8.h),
                          ],
                          if (liveMsg.reactions.isNotEmpty) ...[
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 6.h,
                              children: liveMsg.reactions.entries.map((e) {
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12.r),
                                  onTap: () => context
                                      .read<LmtCubit>()
                                      .toggleMessageReaction(
                                        messageId: liveMsg.id,
                                        emoji: e.key,
                                      ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: Text(
                                      '${e.key} ${e.value.length}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 10.h),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: _viewerQuickEmojis.map((emoji) {
                                        return InkWell(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          onTap: () => context
                                              .read<LmtCubit>()
                                              .toggleMessageReaction(
                                                messageId: liveMsg.id,
                                                emoji: emoji,
                                              ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 4.h,
                                            ),
                                            child: Text(
                                              emoji,
                                              style: TextStyle(fontSize: 19.sp),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 22.h,
                                  color: Colors.white24,
                                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onReply(liveMsg);
                                  },
                                  icon: Icon(Icons.reply_rounded, size: 18.sp),
                                  label: Text(
                                    isArabic ? 'رد' : 'Reply',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CenterVideoControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CenterVideoControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
