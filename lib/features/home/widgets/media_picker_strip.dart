import 'dart:typed_data';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/device_file_helper.dart';

/// Preview item representing a single selected photo or video in [MediaPickerStrip].
class MediaPickerItem {
  /// Local path, data URI, or uploaded cloud URI used to render a preview.
  final String previewPath;

  /// In-memory bytes for instant image preview (especially on Web).
  final Uint8List? previewBytes;

  /// Original display file name.
  final String? fileName;

  /// Whether this media item is a video.
  final bool isVideo;

  /// Whether this item is currently uploading to cloud storage.
  final bool isUploading;

  /// Error message if uploading this item failed.
  final String? errorMessage;

  const MediaPickerItem({
    required this.previewPath,
    this.previewBytes,
    this.fileName,
    this.isVideo = false,
    this.isUploading = false,
    this.errorMessage,
  });
}

/// Multi-media picker and horizontal preview strip for photo/video posts.
class MediaPickerStrip extends StatelessWidget {
  /// Currently selected media items (photos and/or videos).
  final List<MediaPickerItem> items;

  /// Triggered to pick one or more additional photos/videos from gallery.
  final VoidCallback onPickMore;

  /// Triggered to remove a single item by index.
  final ValueChanged<int> onRemoveAt;

  /// Triggered to clear all selected media items.
  final VoidCallback onClearAll;

  /// Whether Arabic UI copy should be shown.
  final bool isArabic;

  const MediaPickerStrip({
    super.key,
    required this.items,
    required this.onPickMore,
    required this.onRemoveAt,
    required this.onClearAll,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final isUploadingAny = items.any((e) => e.isUploading);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: AppColors.cardDecoration(
        context,
        radius: 14.r,
      ),
      child: items.isEmpty
          ? _buildEmptyPicker(
              context: context,
              primary: primary,
              accentGreen: accentGreen,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.perm_media_rounded,
                            size: 14.r,
                            color: primary,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            isArabic
                                ? '${items.length} ملفات مختارة'
                                : '${items.length} selected',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUploadingAny) ...[
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 14.r,
                        height: 14.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        isArabic ? 'جاري الرفع...' : 'Uploading...',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onPickMore,
                      icon: Icon(Icons.add_rounded, size: 17.r, color: primary),
                      label: Text(
                        isArabic ? 'إضافة' : 'Add',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    IconButton(
                      onPressed: onClearAll,
                      tooltip: isArabic ? 'مسح الكل' : 'Clear all',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18.r,
                        color: AppColors.error,
                      ),
                      padding: EdgeInsets.all(4.r),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  height: 148.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) => SizedBox(width: 10.w),
                    itemBuilder: (ctx, index) {
                      if (index == items.length) {
                        return _buildAddMoreTile(
                          primary: primary,
                          textSecondary: textSecondary,
                        );
                      }
                      final item = items[index];
                      return _buildPreviewTile(
                        context: ctx,
                        index: index,
                        item: item,
                        primary: primary,
                        accentGreen: accentGreen,
                        textPrimary: textPrimary,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyPicker({
    required BuildContext context,
    required Color primary,
    required Color accentGreen,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onPickMore,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: primary.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(11.r),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.perm_media_rounded,
                size: 26.r,
                color: primary,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              isArabic ? 'إضافة صور أو فيديوهات' : 'Add Photos or Videos',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isArabic
                  ? 'يمكنك اختيار أكثر من صورة وفيديو معاً في نفس المنشور'
                  : 'Select multiple photos and videos together in one post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMoreTile({
    required Color primary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onPickMore,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 96.w,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: primary.withValues(alpha: 0.28),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 28.r, color: primary),
            SizedBox(height: 6.h),
            Text(
              isArabic ? 'إضافة المزيد' : 'Add more',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTile({
    required BuildContext context,
    required int index,
    required MediaPickerItem item,
    required Color primary,
    required Color accentGreen,
    required Color textPrimary,
  }) {
    final name = DeviceFileHelper.displayFileName(
      item.fileName ?? item.previewPath,
      fallback: item.isVideo ? 'Video' : 'Photo',
    );
    return Container(
      width: 136.w,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: item.errorMessage != null
              ? AppColors.error
              : AppColors.borderOf(context),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.isVideo)
              Container(
                color: primary.withValues(alpha: 0.1),
                padding: EdgeInsets.all(10.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      size: 38.r,
                      color: primary,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            else if (item.previewBytes != null)
              Image.memory(
                item.previewBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              DeviceFileHelper.buildImage(
                item.previewPath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            // Index + media type chip
            Positioned(
              top: 6.h,
              left: 6.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  item.isVideo
                      ? '${index + 1} • ${isArabic ? 'فيديو' : 'Video'}'
                      : '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Remove individual item button
            Positioned(
              top: 5.h,
              right: 5.w,
              child: InkWell(
                onTap: () => onRemoveAt(index),
                customBorder: const CircleBorder(),
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14.r,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Upload / status indicator
            Positioned(
              bottom: 6.h,
              right: 6.w,
              child: item.isUploading
                  ? Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 13.r,
                        height: 13.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : item.errorMessage != null
                      ? Tooltip(
                          message: item.errorMessage!,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 14.r,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.all(3.r),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 15.r,
                            color: accentGreen,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
