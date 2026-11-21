import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Video toggle plus horizontal asset picker used for media posts in the
/// create-post sheet. State is owned by the parent sheet.
class MediaPickerStrip extends StatelessWidget {
  /// Asset paths the user can attach.
  final List<String> assets;

  /// Currently selected asset path.
  final String selectedAsset;

  /// Whether the post is a video post.
  final bool isVideo;

  /// Called when an asset is picked.
  final ValueChanged<String> onAssetSelected;

  /// Called when the video switch toggles.
  final ValueChanged<bool> onVideoChanged;

  /// Creates a [MediaPickerStrip].
  const MediaPickerStrip({
    super.key,
    required this.assets,
    required this.selectedAsset,
    required this.isVideo,
    required this.onAssetSelected,
    required this.onVideoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary = AppColors.textPrimaryOf(context);
    final primary = AppColors.primaryOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            isArabic ? 'منشور فيديو' : 'Video Post',
            style: TextStyle(color: textPrimary, fontSize: 13.sp),
          ),
          value: isVideo,
          onChanged: onVideoChanged,
        ),
        Text(
          isArabic ? 'اختر الصورة أو المصغرة المرفقة:' : 'Select Attached Media:',
          style: AppTypography.labelLarge.copyWith(color: textPrimary),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 80.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: assets.length,
            separatorBuilder: (_, _) => SizedBox(width: 10.w),
            itemBuilder: (_, idx) {
              final img = assets[idx];
              final selected = selectedAsset == img;
              return Semantics(
                button: true,
                selected: selected,
                label: isArabic ? 'وسائط ${idx + 1}' : 'Media ${idx + 1}',
                child: GestureDetector(
                  onTap: () => onAssetSelected(img),
                  child: Container(
                    width: 80.w,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selected ? primary : AppColors.borderOf(context),
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: Image.asset(img, fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
