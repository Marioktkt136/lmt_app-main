import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/colors.dart';

/// Floating pill bottom navigation bar for switching between the 5 main
/// feature tabs (`Posts`, `Chats`, `Files`, `Calendar`, `Members`).
class BottomNavBar extends StatelessWidget {
  /// Currently active tab index (`0..4`).
  final int selectedIndex;

  /// Callback invoked when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Creates a [BottomNavBar].
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);

    final items = [
      (
        icon: Icons.dynamic_feed_rounded,
        label: isArabic ? 'المنشورات' : 'Posts',
      ),
      (icon: Icons.forum_rounded, label: isArabic ? 'المحادثات' : 'Chats'),
      (
        icon: Icons.folder_copy_rounded,
        label: isArabic ? 'الملفات' : 'Files',
      ),
      (
        icon: Icons.calendar_month_rounded,
        label: isArabic ? 'التقويم' : 'Calendar',
      ),
      (
        icon: Icons.people_alt_rounded,
        label: isArabic ? 'الأعضاء' : 'Members',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      child: Container(
        constraints: BoxConstraints(minHeight: 56.h, maxHeight: 68.h),
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: AppColors.borderOf(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = selectedIndex == index;

            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: item.label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : const [],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: isSelected ? 21.sp : 19.sp,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondaryOf(context),
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.8.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
