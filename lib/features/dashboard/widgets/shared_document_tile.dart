import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays a compact, easy-to-scan shared document tile with preview,
/// direct download, and optional delete actions.
class SharedDocumentTile extends StatelessWidget {
  /// The shared document model to render.
  final SharedFileModel doc;

  /// Whether the current user has permission to delete shared files.
  final bool canManageFiles;

  /// Callback invoked when the tile is tapped for preview.
  final VoidCallback onTap;

  /// Callback invoked when the direct download button is tapped.
  final VoidCallback onDownload;

  /// Callback invoked when the delete button is tapped.
  final VoidCallback onDelete;

  /// Creates a [SharedDocumentTile].
  const SharedDocumentTile({
    super.key,
    required this.doc,
    required this.canManageFiles,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return LmtCard(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      borderRadius: 14.r,
      accentColor: primary,
      shadowIntensity: 0.5,
      onTap: onTap,
      child: Row(
        children: [
          // Compact Leading Icon / Thumbnail
          Container(
            width: 38.w,
            height: 38.w,
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: DeviceFileHelper.buildImage(
                doc.localFilePath != null &&
                        doc.category == SharedFileType.image
                    ? doc.localFilePath!
                    : doc.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.insert_drive_file_rounded,
                  color: primary,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Compact Title & Single-Line Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: accentGreen.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                        doc.fileExtension,
                        style: TextStyle(
                          fontSize: 8.8.sp,
                          fontWeight: FontWeight.bold,
                          color: accentGreen,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        '${doc.fileSize} • ${doc.uploadedBy}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),

          // Compact Download & Delete Actions
          InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: onDownload,
            child: Padding(
              padding: EdgeInsets.all(6.w),
              child: Icon(
                Icons.download_for_offline_rounded,
                color: accentGreen,
                size: 21.sp,
              ),
            ),
          ),
          if (canManageFiles)
            InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: onDelete,
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 18.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
