import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays an interactive card with an image and an external or internal link.
class HyperlinkCardWidget extends StatelessWidget {
  /// The shared file/card model to render.
  final SharedFileModel file;

  /// Whether the current user has permission to delete cards.
  final bool canDelete;

  /// Callback invoked when the card is tapped.
  final VoidCallback onTap;

  /// Callback invoked when the delete icon is tapped.
  final VoidCallback onDelete;

  /// Creates a [HyperlinkCardWidget].
  const HyperlinkCardWidget({
    super.key,
    required this.file,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return LmtCard(
      padding: EdgeInsets.all(10.w),
      borderRadius: 18.r,
      accentColor: primary,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  file.fileExtension,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
              if (canDelete)
                InkWell(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.sp,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: DeviceFileHelper.buildImage(
                file.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.link_rounded,
                  size: 36.sp,
                  color: primary,
                ),
              ),
            ),
          ),
          Text(
            file.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
