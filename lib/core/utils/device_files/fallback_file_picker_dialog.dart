import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'device_file_tile.dart';
import 'file_type.dart';
import 'platform_file.dart';
import 'real_files_provisioner.dart';

/// Pure `dart:io` fallback file picker dialog, used when the native picker
/// plugin is unavailable (e.g. before a cold rebuild).
class FallbackFilePickerDialog {
  FallbackFilePickerDialog._();

  /// Scans/provisions device files and shows the dialog. Resolves to the
  /// chosen [PlatformFile] or null when dismissed.
  static Future<PlatformFile?> show(
    BuildContext context, {
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final files = await RealFilesProvisioner.scanAndProvision(
      type: type,
      allowedExtensions: allowedExtensions,
    );
    if (!context.mounted) return null;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isImage = type == FileType.image;

    return showDialog<PlatformFile>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceOf(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(isArabic: isArabic, isImage: isImage),
              const Divider(),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 340.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: files.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8.h),
                  itemBuilder: (_, i) => DeviceFileTile(
                    file: files[i],
                    onTap: () => Navigator.pop(ctx, files[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isArabic, required this.isImage});

  final bool isArabic;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final title = isImage
        ? (isArabic ? 'معرض صور الهاتف 📱' : 'Phone Image Gallery 📱')
        : (isArabic ? 'مدير ملفات الهاتف 📱' : 'Phone File Manager 📱');
    return Row(
      children: [
        Icon(
          isImage ? Icons.photo_library_rounded : Icons.folder_open_rounded,
          color: AppColors.primaryOf(context),
          size: 26.sp,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isArabic
                    ? 'اختر ملفاً حقيقياً من مساحة تخزين الموبايل'
                    : 'Select a real file from phone storage',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: isArabic ? 'إغلاق' : 'Close',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
