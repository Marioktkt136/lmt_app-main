import 'dart:io';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import 'file_size_formatter.dart';
import 'platform_file.dart';

/// A single selectable file row inside the fallback picker dialog.
///
/// Shows a thumbnail (images) or type icon, the name, type and size. Minimum
/// height is 56dp so it is an easy tap target.
class DeviceFileTile extends StatelessWidget {
  /// Creates a tile for [file]; [onTap] is called when it is chosen.
  const DeviceFileTile({super.key, required this.file, required this.onTap});

  /// File displayed by this tile.
  final PlatformFile file;

  /// Called when the user selects the file.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final ext = (file.extension ?? 'FILE').toUpperCase();
    final isImg = ['PNG', 'JPG', 'JPEG', 'WEBP'].contains(ext);

    return Semantics(
      button: true,
      label: file.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 56.h),
          padding: EdgeInsets.all(10.w),
          decoration: AppColors.cardDecoration(
            context,
            radius: 14.r,
            shadowIntensity: 0.5,
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: isImg && file.path != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.file(File(file.path!), fit: BoxFit.cover),
                      )
                    : Icon(
                        ext == 'PDF'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.insert_drive_file_rounded,
                        color: ext == 'PDF' ? AppColors.error : primary,
                        size: 26.sp,
                      ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$ext • ${FileSizeFormatter.format(file.size)}',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: AppColors.accentGreenOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_rounded, color: primary, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }
}
