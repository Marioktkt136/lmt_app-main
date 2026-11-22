import 'dart:math' as math;

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_avatar.dart';

/// Animated WhatsApp-style typing indicator bubble with 3 bouncing wave dots.
class ChatTypingIndicator extends StatefulWidget {
  /// Name of the member currently typing.
  final String typingUserName;

  /// Avatar path of the member currently typing.
  final String? avatarPath;

  /// Creates a [ChatTypingIndicator].
  const ChatTypingIndicator({
    super.key,
    required this.typingUserName,
    this.avatarPath,
  });

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h, left: 4.w, right: 4.w, top: 2.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceOf(context),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: primary.withValues(alpha: 0.28),
          ),
          boxShadow: AppColors.cardShadows(
            context,
            accent: primary,
            intensity: 0.45,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.avatarPath != null) ...[
              LmtAvatar(
                imagePath: widget.avatarPath!,
                radius: 11,
                showShadow: false,
              ),
              SizedBox(width: 7.w),
            ],
            Text(
              isArabic
                  ? '${widget.typingUserName} يكتب الآن'
                  : '${widget.typingUserName} is typing',
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final phase = (_controller.value * 2 * math.pi) -
                        (index * 0.85);
                    final offsetY = math.sin(phase) * -3.5;
                    final opacity =
                        (0.45 + 0.55 * ((math.sin(phase) + 1) / 2))
                            .clamp(0.3, 1.0);

                    return Transform.translate(
                      offset: Offset(0, offsetY),
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: accentGreen.withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
