import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/device_file_helper.dart';

/// Unified Phone Gallery picker widget for attaching an Image OR Video directly
/// from the device gallery when creating a media post.
class MediaPickerStrip extends StatelessWidget {
  /// Persisted local path of the picked image or video (or `null` if none picked yet).
  final String? pickedMediaPath;

  /// Display name of the picked file.
  final String? pickedFileName;

  /// Whether the picked media is a video file.
  final bool isVideo;

  /// Callback invoked to open the device Gallery directly (photos & videos).
  final VoidCallback onPickFromGallery;

  /// Callback invoked to clear the currently picked media.
  final VoidCallback onClearMedia;

  /// Creates a [MediaPickerStrip].
  const MediaPickerStrip({
    super.key,
    required this.pickedMediaPath,
    required this.pickedFileName,
    required this.isVideo,
    required this.onPickFromGallery,
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

    if (hasPicked) {
      return Container(
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
                height: 130.h,
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
                  height: 155.h,
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
                            ? (isArabic ? 'فيديو من المعرض' : 'Gallery video')
                            : (isArabic ? 'صورة من المعرض' : 'Gallery image')),
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
                  onPressed: onPickFromGallery,
                  icon: Icon(Icons.swap_horiz_rounded, size: 16.sp),
                  label: Text(
                    isArabic ? 'تغيير' : 'Change',
                    style: TextStyle(fontSize: 11.5.sp),
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
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onPickFromGallery,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: primary.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.perm_media_rounded,
              size: 40.sp,
              color: primary,
            ),
            SizedBox(height: 8.h),
            Text(
              isArabic
                  ? 'اضغط لاختيار صورة أو فيديو من المعرض (Gallery) 📱'
                  : 'Tap to pick an image or video from your phone gallery 📱',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isArabic
                  ? 'يفتح معرض الصور والفيديوهات مباشرة لتختار صورة أو فيديو لرفعه'
                  : 'Opens your device gallery directly to pick either a photo or video',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
