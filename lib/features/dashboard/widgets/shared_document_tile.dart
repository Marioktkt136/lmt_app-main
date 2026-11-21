import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays an individual shared document tile with download and delete actions.
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return LmtCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.zero,
      borderRadius: 18.r,
      accentColor: primary,
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 6.h,
        ),
        leading: Container(
          width: 48.w,
          height: 48.w,
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: DeviceFileHelper.buildImage(
              doc.localFilePath != null &&
                      doc.category == SharedFileType.image
                  ? doc.localFilePath!
                  : doc.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.insert_drive_file_rounded,
                color: primary,
              ),
            ),
          ),
        ),
        title: Text(
          doc.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
            color: textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 3.h),
            Text(
              doc.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: accentGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    doc.fileExtension,
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.bold,
                      color: accentGreen,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '${doc.fileSize} • ${doc.uploadedBy} • ${DateFormat('dd/MM/yyyy').format(doc.uploadedAt)}',
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isArabic
                  ? 'تنزيل وفتح الملف الحقيقي'
                  : 'Download & Open Real File',
              onPressed: onDownload,
              icon: Icon(
                Icons.download_for_offline_rounded,
                color: accentGreen,
                size: 24.sp,
              ),
            ),
            if (canManageFiles)
              IconButton(
                tooltip: isArabic ? 'حذف' : 'Delete',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
