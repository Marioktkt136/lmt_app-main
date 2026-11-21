import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';
import '../cubit/chat_cubit.dart';

/// Displays the top group header bar inside [GroupConversationRoom] with
/// back navigation, group avatar, member count, admin badge, and pin toggle.
class ConversationHeaderBar extends StatelessWidget {
  /// The active chat group being displayed.
  final ChatGroupModel group;

  /// Callback invoked when the back button is tapped.
  final VoidCallback onBack;

  /// Creates a [ConversationHeaderBar].
  const ConversationHeaderBar({
    super.key,
    required this.group,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return LmtCard(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      borderRadius: 18.r,
      accentColor: primary,
      isHighlighted: true,
      child: Row(
        children: [
          IconButton(
            tooltip: isArabic ? 'رجوع للمجموعات' : 'Back to groups',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
            ),
          ),
          LmtAvatar(
            imagePath: group.imagePath,
            radius: 20,
            showShadow: false,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h6.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${group.memberIds.length} ${isArabic ? 'عضو' : 'members'} • ${isArabic ? 'المسؤول:' : 'Admin:'} ${group.adminName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isArabic ? 'تثبيت المجموعة' : 'Pin Group',
            onPressed: () =>
                context.read<LmtCubit>().togglePinChatGroup(group.id),
            icon: Icon(
              group.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: group.isPinned ? primary : textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
