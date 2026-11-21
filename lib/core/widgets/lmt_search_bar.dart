import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/colors.dart';

/// Global reusable search bar with an optional trailing action button.
class LmtSearchBar extends StatelessWidget {
  /// The placeholder hint text inside the search field.
  final String hintText;

  /// Callback invoked whenever the search query changes.
  final ValueChanged<String> onChanged;

  /// Optional trailing action widgets (e.g., filter chip or add button).
  final List<Widget> actions;

  /// Creates an [LmtSearchBar].
  const LmtSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            style: TextStyle(color: textPrimary, fontSize: 13.sp),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
            ),
          ),
        ),
        ...actions,
      ],
    );
  }
}
