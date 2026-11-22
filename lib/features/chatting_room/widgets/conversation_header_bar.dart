import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../cubit/chat_cubit.dart';
import 'chat_group_form_sheet.dart';

/// Full-width mobile [AppBar] for [GroupConversationPage].
///
/// - Harmonizes status bar and AppBar colors across Light Mode (`AppColors.primary`)
///   and Dark Mode (`AppColors.surfaceDark`).
/// - Tapping the group avatar, name, or member info opens [showChatGroupFormSheet]
///   so the user can update the group directly.
class ConversationHeaderBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// The active chat group being displayed.
  final ChatGroupModel group;

  /// Current state used for opening the group update sheet.
  final LmtState state;

  /// Callback invoked when the back button is tapped.
  final VoidCallback onBack;

  /// Creates a [ConversationHeaderBar].
  const ConversationHeaderBar({
    super.key,
    required this.group,
    required this.state,
    required this.onBack,
  });

  @override
  Size get preferredSize => Size.fromHeight(62.h);

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);
    final appBarBg = isDark ? AppColors.surfaceDark : AppColors.primary;
    final fgColor = isDark ? AppColors.textPrimaryDark : Colors.white;
    final subColor = isDark
        ? AppColors.textSecondaryDark
        : Colors.white.withValues(alpha: 0.88);

    return AppBar(
      backgroundColor: appBarBg,
      foregroundColor: fgColor,
      elevation: isDark ? 0 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 62.h,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: appBarBg,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      shape: isDark
          ? Border(
              bottom: BorderSide(
                color: primary.withValues(alpha: 0.28),
                width: 1,
              ),
            )
          : null,
      leading: IconButton(
        tooltip: isArabic ? 'رجوع للمجموعات' : 'Back to groups',
        onPressed: onBack,
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 19.sp,
          color: fgColor,
        ),
      ),
      title: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => showChatGroupFormSheet(
          context,
          state,
          existingGroup: group,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
          child: Row(
            children: [
              LmtAvatar(
                imagePath: group.imagePath,
                radius: 20,
                showShadow: false,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: fgColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.edit_outlined,
                          size: 13.sp,
                          color: subColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '${group.memberIds.length} ${isArabic ? 'عضو' : 'members'} • ${isArabic ? 'المسؤول:' : 'Admin:'} ${group.adminName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: isArabic ? 'تثبيت المجموعة' : 'Pin Group',
          onPressed: () =>
              context.read<LmtCubit>().togglePinChatGroup(group.id),
          icon: Icon(
            group.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            color: group.isPinned
                ? (isDark ? primary : const Color(0xFFFFD54F))
                : subColor,
          ),
        ),
      ],
    );
  }
}
