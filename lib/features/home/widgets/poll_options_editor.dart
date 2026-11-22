import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Editor for the three poll option text fields of the create-post sheet.
///
/// The third option is optional. Controllers are owned by the parent sheet.
class PollOptionsEditor extends StatelessWidget {
  /// Controllers for options 1, 2 and 3 (in that order).
  final List<TextEditingController> controllers;

  /// Creates a [PollOptionsEditor].
  const PollOptionsEditor({super.key, required this.controllers}) : assert(controllers.length == 3);

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final labels = [
      isArabic ? 'الخيار الأول' : 'Option 1',
      isArabic ? 'الخيار الثاني' : 'Option 2',
      isArabic ? 'الخيار الثالث (اختياري)' : 'Option 3 (Optional)',
    ];
    const icons = [Icons.looks_one_outlined, Icons.looks_two_outlined, Icons.looks_3_outlined];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'خيارات التصويت:' : 'Poll Options:',
          style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryOf(context)),
        ),
        SizedBox(height: 8.h),
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(height: 8.h),
          TextField(
            controller: controllers[i],
            textInputAction: i == 2 ? TextInputAction.done : TextInputAction.next,
            decoration: InputDecoration(labelText: labels[i], prefixIcon: Icon(icons[i])),
          ),
        ],
      ],
    );
  }
}
