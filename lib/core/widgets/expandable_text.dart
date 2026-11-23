import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/colors.dart';

/// Displays text that automatically collapses when exceeding [collapseLength]
/// characters (default 200), showing a soft fade + "Read more" toggle that
/// expands smoothly to display the full text and offers "Show less".
class LmtExpandableText extends StatefulWidget {
  /// Full text content to display.
  final String text;

  /// Base text style applied to the text body.
  final TextStyle style;

  /// Character threshold beyond which text starts collapsed.
  final int collapseLength;

  /// Optional text alignment.
  final TextAlign? textAlign;

  /// Accent color for the toggle button.
  final Color? toggleColor;

  /// Creates an [LmtExpandableText].
  const LmtExpandableText({
    super.key,
    required this.text,
    required this.style,
    this.collapseLength = 200,
    this.textAlign,
    this.toggleColor,
  });

  @override
  State<LmtExpandableText> createState() => _LmtExpandableTextState();
}

class _LmtExpandableTextState extends State<LmtExpandableText> {
  bool _isExpanded = false;

  String _collapsedSlice(String value) {
    final trimmed = value.trimRight();
    if (trimmed.length <= widget.collapseLength) return trimmed;
    var cutIndex = widget.collapseLength;
    // Prefer breaking at the last whitespace within a 28-character window.
    final minSearch = (cutIndex - 28).clamp(0, cutIndex);
    for (var i = cutIndex; i >= minSearch; i--) {
      if (trimmed[i] == ' ' || trimmed[i] == '\n') {
        cutIndex = i;
        break;
      }
    }
    return '${trimmed.substring(0, cutIndex).trimRight()}...';
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.text.trim();
    if (trimmed.length <= widget.collapseLength) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
      );
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final accent = widget.toggleColor ?? AppColors.primaryOf(context);
    final displayText = _isExpanded ? widget.text : _collapsedSlice(trimmed);

    final textWidget = Text(
      displayText,
      style: widget.style,
      textAlign: widget.textAlign,
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.topStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isExpanded)
            textWidget
          else
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.72, 1.0],
                colors: [
                  Colors.white,
                  Colors.white,
                  Color(0x55FFFFFF),
                ],
              ).createShader(bounds),
              child: textWidget,
            ),
          SizedBox(height: 4.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded
                        ? (isArabic ? 'عرض أقل' : 'Show less')
                        : (isArabic ? 'قراءة المزيد' : 'Read more'),
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16.sp,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
