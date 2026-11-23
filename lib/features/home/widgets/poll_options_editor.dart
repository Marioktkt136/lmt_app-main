import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Dynamic editor for poll option text fields inside [CreatePostSheet].
///
/// Supports adding unlimited options via the `+` button and removing extra
/// options while keeping at least two choices. Controllers are owned by the parent.
class PollOptionsEditor extends StatelessWidget {
  /// Controllers for each poll option in display order.
  final List<TextEditingController> controllers;

  /// Callback invoked when the user taps the `+` button to add a new option.
  final VoidCallback onAddOption;

  /// Callback invoked when the user deletes the option at `index`.
  final ValueChanged<int> onRemoveOption;

  /// Creates a [PollOptionsEditor].
  const PollOptionsEditor({
    super.key,
    required this.controllers,
    required this.onAddOption,
    required this.onRemoveOption,
  }) : assert(controllers.length >= 2);

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic
                  ? 'خيارات التصويت (${controllers.length}):'
                  : 'Poll Options (${controllers.length}):',
              style: AppTypography.labelLarge.copyWith(color: textPrimary),
            ),
            IconButton.filledTonal(
              tooltip: isArabic ? 'إضافة خيار جديد' : 'Add poll option',
              onPressed: onAddOption,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        for (var i = 0; i < controllers.length; i++) ...[
          if (i > 0) SizedBox(height: 8.h),
          TextField(
            controller: controllers[i],
            textInputAction: i == controllers.length - 1
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: InputDecoration(
              labelText: isArabic
                  ? 'الخيار ${i + 1}${i >= 2 ? ' (اختياري)' : ''}'
                  : 'Option ${i + 1}${i >= 2 ? ' (Optional)' : ''}',
              prefixIcon: Padding(
                padding: EdgeInsets.all(10.w),
                child: Container(
                  width: 22.w,
                  height: 22.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
              ),
              suffixIcon: controllers.length > 2 && i >= 2
                  ? IconButton(
                      tooltip: isArabic ? 'حذف الخيار' : 'Remove option',
                      onPressed: () => onRemoveOption(i),
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: AppColors.error,
                      ),
                    )
                  : null,
            ),
          ),
        ],
        SizedBox(height: 8.h),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: onAddOption,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              isArabic ? '+ إضافة خيار آخر' : '+ Add another option',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
