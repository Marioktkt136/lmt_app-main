import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/colors.dart';

/// Global reusable elevated card widget with unified shadows and Material ink support.
class LmtCard extends StatelessWidget {
  /// The inner widget content of the card.
  final Widget child;

  /// Optional internal padding of the card.
  final EdgeInsetsGeometry? padding;

  /// Optional external margin of the card.
  final EdgeInsetsGeometry? margin;

  /// Corner border radius of the card.
  final double? borderRadius;

  /// Optional accent tint color for the shadow and border.
  final Color? accentColor;

  /// Optional custom background fill color.
  final Color? fillColor;

  /// Whether the card is visually highlighted.
  final bool isHighlighted;

  /// Multiplier for the card shadow intensity.
  final double shadowIntensity;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional long-press callback.
  final VoidCallback? onLongPress;

  /// Creates an [LmtCard].
  const LmtCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.accentColor,
    this.fillColor,
    this.isHighlighted = false,
    this.shadowIntensity = 1.0,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 18.r;
    Widget content = Padding(
      padding: padding ?? EdgeInsets.all(14.w),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: AppColors.cardDecoration(
        context,
        radius: radius,
        accentColor: accentColor,
        fillColor: fillColor,
        isHighlighted: isHighlighted,
        shadowIntensity: shadowIntensity,
      ),
      child: Material(
        color: Colors.transparent,
        child: content,
      ),
    );
  }
}
