import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/colors.dart';

/// Global reusable search bar with instant clear button, elevated surface
/// styling, and optional trailing action widgets.
class LmtSearchBar extends StatefulWidget {
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
  State<LmtSearchBar> createState() => _LmtSearchBarState();
}

class _LmtSearchBarState extends State<LmtSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final nextHasText = value.isNotEmpty;
    if (_hasText != nextHasText) {
      setState(() => _hasText = nextHasText);
    }
    widget.onChanged(value);
  }

  void _handleClear() {
    _controller.clear();
    setState(() => _hasText = false);
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: AppColors.cardShadows(
                context,
                accent: primary,
                intensity: 0.45,
              ),
            ),
            child: TextField(
              controller: _controller,
              onChanged: _handleChanged,
              style: TextStyle(color: textPrimary, fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: primary,
                  size: 20.sp,
                ),
                suffixIcon: _hasText
                    ? IconButton(
                        tooltip: isArabic ? 'مسح البحث' : 'Clear search',
                        onPressed: _handleClear,
                        icon: Icon(
                          Icons.cancel_rounded,
                          color: textSecondary,
                          size: 18.sp,
                        ),
                      )
                    : null,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 11.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: BorderSide(
                    color: primary.withValues(alpha: 0.25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: BorderSide(
                    color: primary.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          ),
        ),
        ...widget.actions,
      ],
    );
  }
}
