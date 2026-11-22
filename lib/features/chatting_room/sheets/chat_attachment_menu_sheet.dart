import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/device_file_helper.dart';
import '../cubit/chat_cubit.dart';

/// Displays the media/attachment selection bottom sheet for a chat room:
/// - **Gallery (Image / Video)**: Opens the phone's Photo Gallery directly
///   (`FileType.media`) with no intermediate preset screen.
/// - **File Attach**: Opens the phone's File Browser (`FileType.any`).
void showChatAttachmentMenuSheet({
  required BuildContext context,
  required String groupId,
  required ChatMessageModel? replyTo,
  required VoidCallback onMessageSent,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final primary = AppColors.primaryOf(context);
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
          children: [
            Text(
              isArabic
                  ? 'إرسال وسائط أو مرفقات للمجموعة'
                  : 'Send Media or Attachment to Group',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimaryOf(ctx),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOptionButton(
                  icon: Icons.perm_media_rounded,
                  color: primary,
                  label: isArabic ? 'صور وفيديو (المعرض)' : 'Gallery (Photo/Video)',
                  onTap: () async {
                    final cubit = context.read<LmtCubit>();
                    Navigator.pop(ctx);
                    final picked = await DeviceFileHelper.pickFileSafely(
                      context,
                      type: FileType.media,
                    );
                    if (picked == null || picked.path == null) return;
                    final savedPath = await DeviceFileHelper.persistPickedFile(
                      picked.path!,
                      picked.name,
                    );
                    final isVideo = DeviceFileHelper.isVideoPath(savedPath) ||
                        DeviceFileHelper.isVideoPath(picked.name);
                    await cubit.sendChatMessage(
                      groupId: groupId,
                      type: isVideo ? MessageType.video : MessageType.image,
                      content: '',
                      attachmentPath: savedPath,
                      fileSize: DeviceFileHelper.formatBytes(picked.size),
                      replyTo: replyTo,
                    );
                    onMessageSent();
                  },
                ),
                _AttachmentOptionButton(
                  icon: Icons.attach_file_rounded,
                  color: accentGreen,
                  label: isArabic ? 'ملف (File)' : 'File Attach',
                  onTap: () {
                    Navigator.pop(ctx);
                    showSendChatFileSheet(
                      context: context,
                      groupId: groupId,
                      replyTo: replyTo,
                      onSent: onMessageSent,
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ),
      );
    },
  );
}

/// Displays the sheet for picking and attaching a document/file in a chat room
/// from the device's file browser.
void showSendChatFileSheet({
  required BuildContext context,
  required String groupId,
  required ChatMessageModel? replyTo,
  required VoidCallback onSent,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final fileNameCtrl = TextEditingController(text: '');
  final noteCtrl = TextEditingController(text: '');

  String? pickedFilePath;
  String pickedFileSize = '1.8 MB';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 18.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? 'إرفاق ملف في المحادثة 📎' : 'Attach File 📎',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimaryOf(ctx),
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await DeviceFileHelper.pickFileSafely(
                        ctx,
                        type: FileType.any,
                      );
                      if (f != null && f.path != null) {
                        final savedPath =
                            await DeviceFileHelper.persistPickedFile(
                          f.path!,
                          f.name,
                        );
                        setModalState(() {
                          pickedFilePath = savedPath;
                          pickedFileSize =
                              DeviceFileHelper.formatBytes(f.size);
                          fileNameCtrl.text = f.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    label: Text(
                      isArabic
                          ? 'اختيار ملف من الهاتف 📱'
                          : 'Choose File from Phone 📱',
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: fileNameCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسم الملف' : 'File Name',
                    prefixIcon: const Icon(Icons.insert_drive_file_outlined),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'رسالة مع الملف' : 'Message Note',
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final resolvedPath =
                          pickedFilePath ?? fileNameCtrl.text.trim();
                      if (resolvedPath.isEmpty) return;
                      context.read<LmtCubit>().sendChatMessage(
                            groupId: groupId,
                            type: MessageType.file,
                            content: noteCtrl.text.trim(),
                            attachmentPath: resolvedPath,
                            fileSize: pickedFileSize,
                            replyTo: replyTo,
                          );
                      Navigator.pop(ctx);
                      onSent();
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(isArabic ? 'إرسال الملف' : 'Send File'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _AttachmentOptionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOptionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
