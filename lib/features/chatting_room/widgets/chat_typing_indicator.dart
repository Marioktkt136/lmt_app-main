import 'dart:math' as math;

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_avatar.dart';

/// Animated WhatsApp-style typing indicator bubble supporting one or multiple
/// simultaneous group members typing at the same time (never shown for self).
class ChatTypingIndicator extends StatefulWidget {
  /// Active remote members currently typing in this group.
  final List<TypingMemberStatus> typingMembers;

  /// Creates a [ChatTypingIndicator].
  const ChatTypingIndicator({
    super.key,
    required this.typingMembers,
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

  String _typingLabel(bool isArabic, List<TypingMemberStatus> members) {
    if (members.length == 1) {
      final first = members.first.memberName;
      return isArabic ? '$first يكتب الآن' : '$first is typing';
    }
    if (members.length == 2) {
      final first = members[0].memberName;
      final second = members[1].memberName;
      return isArabic
          ? '$first و $second يكتبان الآن'
          : '$first and $second are typing';
    }
    final remaining = members.length - 2;
    final first = members[0].memberName;
    final second = members[1].memberName;
    return isArabic
        ? '$first، $second و $remaining آخرون يكتبون الآن'
        : '$first, $second and $remaining others are typing';
  }

  Widget _buildAvatarStack(BuildContext context, List<TypingMemberStatus> members) {
    final visible = members.take(3).toList();
    final radius = 11.r;
    final diameter = radius * 2;
    const overlapOffset = 14.0;
    final stackWidth = diameter + (visible.length - 1) * overlapOffset;

    return SizedBox(
      width: stackWidth,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * overlapOffset,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cardSurfaceOf(context),
                    width: 1.5,
                  ),
                ),
                child: LmtAvatar(
                  imagePath: visible[i].avatarPath,
                  radius: 10,
                  showShadow: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingMembers.isEmpty) return const SizedBox.shrink();

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * 0.85).clamp(0.0, 520.0),
        ),
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
            _buildAvatarStack(context, widget.typingMembers),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                _typingLabel(isArabic, widget.typingMembers),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final phase =
                        (_controller.value * 2 * math.pi) - (index * 0.85);
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
