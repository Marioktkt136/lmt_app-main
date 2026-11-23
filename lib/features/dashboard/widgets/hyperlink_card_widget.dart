import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays a compact, easy-to-use horizontal quick-link card with an icon,
/// title, link type badge, edit (Admin & Editor), and delete (Admin only) actions.
class HyperlinkCardWidget extends StatelessWidget {
  /// The shared file/card model to render.
  final SharedFileModel file;

  /// Whether the current user can edit card metadata (Admin & Editor).
  final bool canEdit;

  /// Whether the current user has permission to delete cards (Admin only).
  final bool canDelete;

  /// Callback invoked when the card is tapped.
  final VoidCallback onTap;

  /// Callback invoked when the edit icon is tapped.
  final VoidCallback onEdit;

  /// Callback invoked when the delete icon is tapped.
  final VoidCallback onDelete;

  /// Creates a [HyperlinkCardWidget].
  const HyperlinkCardWidget({
    super.key,
    required this.file,
    required this.canEdit,
    required this.canDelete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return LmtCard(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      borderRadius: 14.r,
      accentColor: primary,
      shadowIntensity: 0.55,
      onTap: onTap,
      child: Row(
        children: [
          // Compact Icon Box
          Container(
            width: 38.w,
            height: 38.w,
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: DeviceFileHelper.buildImage(
              file.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.link_rounded,
                size: 20.sp,
                color: primary,
              ),
            ),
          ),
          SizedBox(width: 8.w),

          // Title & Compact Link Badge
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        file.fileExtension,
                        style: TextStyle(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        file.fileSize,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit, Delete or Open indicator
          if (canEdit)
            InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: onEdit,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Icon(
                  Icons.edit_outlined,
                  size: 15.sp,
                  color: primary,
                ),
              ),
            ),
          if (canDelete)
            InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: onDelete,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Icon(
                  Icons.close_rounded,
                  size: 15.sp,
                  color: AppColors.error,
                ),
              ),
            )
          else if (!canEdit)
            Icon(
              Icons.open_in_new_rounded,
              size: 14.sp,
              color: primary,
            ),
        ],
      ),
    );
  }
}
