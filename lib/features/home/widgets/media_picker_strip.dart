import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/device_file_helper.dart';

/// Gallery picker widget for attaching a real Image or Video from the user's
/// phone storage when creating a media post.
class MediaPickerStrip extends StatelessWidget {
  /// Persisted local path of the picked image or video (or `null` if none picked yet).
  final String? pickedMediaPath;

  /// Display name of the picked file.
  final String? pickedFileName;

  /// Whether the picked media is a video file.
  final bool isVideo;

  /// Callback invoked when the user taps "Pick Image from Gallery".
  final VoidCallback onPickImageFromGallery;

  /// Callback invoked when the user taps "Pick Video from Gallery".
  final VoidCallback onPickVideoFromGallery;

  /// Callback invoked to clear the currently picked media.
  final VoidCallback onClearMedia;

  /// Creates a [MediaPickerStrip].
  const MediaPickerStrip({
    super.key,
    required this.pickedMediaPath,
    required this.pickedFileName,
    required this.isVideo,
    required this.onPickImageFromGallery,
    required this.onPickVideoFromGallery,
    required this.onClearMedia,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final hasPicked = pickedMediaPath != null && pickedMediaPath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gallery Action Buttons (Pick Image OR Pick Video from Phone Gallery)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary, width: 1.4),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: onPickImageFromGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(
                  isArabic ? 'رفع صورة من المعرض 📷' : 'Pick Image 📷',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  side: const BorderSide(
                    color: Color(0xFFF59E0B),
                    width: 1.4,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: onPickVideoFromGallery,
                icon: const Icon(Icons.video_library_rounded),
                label: Text(
                  isArabic ? 'رفع فيديو من المعرض 🎬' : 'Pick Video 🎬',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Preview Box or Empty Prompt
        if (hasPicked)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: AppColors.cardDecoration(
              context,
              radius: 16.r,
              accentColor: accentGreen,
              isHighlighted: true,
            ),
            child: Column(
              children: [
                if (isVideo)
                  Container(
                    height: 120.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 46.sp,
                        ),
                        SizedBox(height: 6.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Text(
                            pickedFileName ?? 'Video.mp4',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      height: 150.h,
                      width: double.infinity,
                      child: DeviceFileHelper.buildImage(
                        pickedMediaPath!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: accentGreen,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        pickedFileName ??
                            (isVideo
                                ? (isArabic ? 'فيديو مرفوع' : 'Uploaded video')
                                : (isArabic ? 'صورة مرفوعة' : 'Uploaded image')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onClearMedia,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 16.sp,
                      ),
                      label: Text(
                        isArabic ? 'إزالة' : 'Remove',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: onPickImageFromGallery,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.perm_media_rounded,
                    size: 36.sp,
                    color: primary,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isArabic
                        ? 'اضغط لاختيار صورة أو فيديو من معرض هاتفك 📱'
                        : 'Tap to pick an image or video from your phone gallery 📱',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    isArabic
                        ? 'يفتح الاستوديو / المعرض لرفع الصور والفيديوهات مباشرة'
                        : 'Opens your device gallery to upload photos or videos directly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
