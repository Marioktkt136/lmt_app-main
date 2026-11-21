import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/device_file_helper.dart';

/// Launches an external URL in the device's default browser or application.
Future<void> openExternalLink(String url) async {
  if (url.trim().isEmpty) return;
  final Uri uri = Uri.parse(url);
  try {
    final bool launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    debugPrint('Could not launch $url: $e');
  }
}

/// Downloads a [SharedFileModel] to the device storage and opens it natively.
Future<void> downloadAndOpenSharedFile(
  BuildContext context,
  SharedFileModel file,
) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final accentGreen = AppColors.accentGreenOf(context);

  try {
    final savedPath = await DeviceFileHelper.downloadAndOpenRealFile(
      file,
      openAfterSave: true,
    );
    await LocalNotificationService.showInstantNotification(
      idKey: 'dl_${file.id}',
      title: isArabic ? 'تم تنزيل الملف بنجاح 📥' : 'File Downloaded 📥',
      body: '${file.title} (${file.fileSize})',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم تنزيل وفتح الملف: ${file.title}\nالمسار: $savedPath'
              : 'Downloaded & opened: ${file.title}',
        ),
        backgroundColor: accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'حدث خطأ أثناء فتح الملف: $e'
              : 'Could not open file: $e',
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Handles tapping a [SharedFileModel]: navigates to internal routes, opens
/// external hyperlinks, or displays the interactive preview and download sheet.
void handleSharedFileTap(BuildContext context, SharedFileModel file) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  if (file.internalRoute != null && file.internalRoute!.isNotEmpty) {
    AppRouter.navigateTo(context, file.internalRoute!);
    return;
  }

  if (file.externalUrl != null && file.externalUrl!.isNotEmpty) {
    openExternalLink(file.externalUrl!);
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      final primary = AppColors.primaryOf(ctx);
      final accentGreen = AppColors.accentGreenOf(ctx);
      final textPrimary = AppColors.textPrimaryOf(ctx);
      final textSecondary = AppColors.textSecondaryOf(ctx);

      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: DeviceFileHelper.buildImage(
                    file.localFilePath != null &&
                            file.category == SharedFileType.image
                        ? file.localFilePath!
                        : file.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.title,
                        style: AppTypography.h5.copyWith(color: textPrimary),
                      ),
                      Text(
                        '${file.category.label(isArabic)} • ${file.fileExtension} • ${file.fileSize}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (file.category == SharedFileType.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  height: 220.h,
                  width: double.infinity,
                  color: primary.withValues(alpha: 0.08),
                  child: DeviceFileHelper.buildImage(
                    file.localFilePath ?? file.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: 240.h),
                padding: EdgeInsets.all(14.w),
                decoration: AppColors.cardDecoration(ctx, radius: 14.r),
                child: SingleChildScrollView(
                  child: Text(
                    file.documentContent ??
                        (file.localFilePath != null
                            ? '${file.description}\n\n📄 مسار الملف المرفوع:\n${file.localFilePath}'
                            : file.description),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary, width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final savedPath =
                          await DeviceFileHelper.downloadAndOpenRealFile(
                        file,
                        openAfterSave: false,
                      );
                      await LocalNotificationService.showInstantNotification(
                        idKey: 'save_${file.id}',
                        title: isArabic
                            ? 'تم تنزيل الملف على جهازك ✅'
                            : 'File Saved to Device ✅',
                        body: file.title,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? 'تم حفظ الملف على الهاتف في:\n$savedPath'
                                : 'Saved to device:\n$savedPath',
                          ),
                          backgroundColor: accentGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_alt_rounded),
                    label: Text(
                      isArabic ? 'تنزيل للهاتف' : 'Save to Phone',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      downloadAndOpenSharedFile(context, file);
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(
                      isArabic ? 'تنزيل وفتح الملف' : 'Download & Open',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
