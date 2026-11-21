import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';
import '../cubit/chat_cubit.dart';

/// Displays the media/attachment selection bottom sheet for a chat room.
void showChatAttachmentMenuSheet({
  required BuildContext context,
  required String groupId,
  required ChatMessageModel? replyTo,
  required VoidCallback onOpenStickers,
  required VoidCallback onStartVoiceRecording,
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
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AttachmentOptionButton(
                  icon: Icons.image_rounded,
                  color: primary,
                  label: isArabic ? 'صورة (Image)' : 'Image',
                  onTap: () {
                    Navigator.pop(ctx);
                    showSendChatImageSheet(
                      context: context,
                      groupId: groupId,
                      replyTo: replyTo,
                      onSent: onMessageSent,
                    );
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
                _AttachmentOptionButton(
                  icon: Icons.emoji_emotions_rounded,
                  color: const Color(0xFFF59E0B),
                  label: isArabic ? 'ملصق (Sticker)' : 'Stickers',
                  onTap: () {
                    Navigator.pop(ctx);
                    onOpenStickers();
                  },
                ),
                _AttachmentOptionButton(
                  icon: Icons.mic_rounded,
                  color: AppColors.error,
                  label: isArabic ? 'تسجيل صوتي' : 'Voice Note',
                  onTap: () {
                    Navigator.pop(ctx);
                    onStartVoiceRecording();
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

/// Displays the sheet for picking and sending an image from the phone or presets.
void showSendChatImageSheet({
  required BuildContext context,
  required String groupId,
  required ChatMessageModel? replyTo,
  required VoidCallback onSent,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final captionCtrl = TextEditingController(
    text: isArabic
        ? 'صورة من بروفة المسرح والتحضيرات 🎭'
        : 'Stage rehearsal photo 🎭',
  );
  String selectedAsset = AppAssets.actIcon;
  final images = [
    AppAssets.actIcon,
    AppAssets.appLogo,
    AppAssets.picturesIcon,
    AppAssets.galleryIcon,
  ];

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
                  isArabic ? 'إرسال صورة للمجموعة 📷' : 'Send Image 📷',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimaryOf(ctx),
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final file = await DeviceFileHelper.pickFileSafely(
                        ctx,
                        type: FileType.image,
                      );
                      if (file != null && file.path != null) {
                        final savedPath =
                            await DeviceFileHelper.persistPickedFile(
                          file.path!,
                          file.name,
                        );
                        setModalState(() => selectedAsset = savedPath);
                      }
                    },
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(
                      isArabic
                          ? 'اختيار صورة من معرض الهاتف 📱'
                          : 'Choose Image from Phone Gallery 📱',
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  height: 90.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, _) => SizedBox(width: 10.w),
                    itemBuilder: (_, idx) {
                      final img = images[idx];
                      final selected = selectedAsset == img;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedAsset = img),
                        child: Container(
                          width: 90.w,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primaryOf(ctx)
                                  : AppColors.borderOf(ctx),
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                          child: DeviceFileHelper.buildImage(
                            img,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: captionCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'وصف الصورة' : 'Image Caption',
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<LmtCubit>().sendChatMessage(
                            groupId: groupId,
                            type: MessageType.image,
                            content: captionCtrl.text.trim(),
                            attachmentPath: selectedAsset,
                            replyTo: replyTo,
                          );
                      Navigator.pop(ctx);
                      onSent();
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: Text(isArabic ? 'إرسال الصورة' : 'Send Image'),
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

/// Displays the sheet for picking and attaching a document/file in a chat room.
void showSendChatFileSheet({
  required BuildContext context,
  required String groupId,
  required ChatMessageModel? replyTo,
  required VoidCallback onSent,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final fileNameCtrl = TextEditingController(
    text: 'اسكريبت_المشهد_الجديد_LMT.pdf',
  );
  final noteCtrl = TextEditingController(
    text: isArabic
        ? 'مرفق ملف الاسكريبت وتوزيع المهام للمراجعة 📄'
        : 'Attached script & task sheet 📄',
  );

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
                      final f = await DeviceFileHelper.pickFileSafely(ctx);
                      if (f != null && f.path != null) {
                        final savedPath =
                            await DeviceFileHelper.persistPickedFile(
                          f.path!,
                          f.name,
                        );
                        setModalState(() {
                          pickedFilePath = savedPath;
                          pickedFileSize = DeviceFileHelper.formatBytes(f.size);
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
                      context.read<LmtCubit>().sendChatMessage(
                            groupId: groupId,
                            type: MessageType.file,
                            content: noteCtrl.text.trim(),
                            attachmentPath:
                                pickedFilePath ?? fileNameCtrl.text.trim(),
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
