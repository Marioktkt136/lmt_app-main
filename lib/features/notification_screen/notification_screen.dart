import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'cubit/notifications_cubit.dart';
import '../../core/models/lmt_models.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

/// Notifications and Reminders View
/// - Title
/// - Descriptions
/// - Date & Time
/// - On Press Navigation to view that notify
/// - Mark All as Read
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final primary = AppColors.primaryOf(context);
        final accentGreen = AppColors.accentGreenOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);
        final border = AppColors.borderOf(context);

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              isArabic
                  ? 'الإشعارات والتذكيرات (${state.unreadNotificationsCount})'
                  : 'Notifications & Reminders (${state.unreadNotificationsCount})',
              style: AppTypography.h5.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () {
                  context.read<LmtCubit>().markAllNotificationsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تم تحديد جميع الإشعارات كمقروءة ✅'
                            : 'All notifications marked as read ✅',
                      ),
                      backgroundColor: accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.done_all_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  isArabic ? 'قراءة الكل' : 'Mark All Read',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: state.notifications.isEmpty
              ? Center(
                  child: Text(
                    isArabic
                        ? 'لا توجد إشعارات حالياً'
                        : 'No notifications yet',
                    style: TextStyle(color: textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(14.w),
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = state.notifications[index];
                    final isUnread = !notif.isRead;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: AppColors.cardDecoration(
                        context,
                        radius: 18.r,
                        accentColor: isUnread ? primary : border,
                        isHighlighted: isUnread,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                        leading: CircleAvatar(
                          backgroundColor: isUnread
                              ? primary
                              : textSecondary.withValues(alpha: 0.2),
                          child: Icon(
                            _iconForCategory(notif.category),
                            color: isUnread ? Colors.white : textSecondary,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 13.5.sp,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 9.w,
                                height: 9.w,
                                decoration: BoxDecoration(
                                  color: accentGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5.h),
                            Text(
                              notif.description,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: textSecondary,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('EEE, dd/MM/yyyy • hh:mm a')
                                      .format(notif.dateTime),
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    color: primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      isArabic
                                          ? 'انتقل للقسم'
                                          : 'Open View',
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        color: accentGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 11.sp,
                                      color: accentGreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          final cubit = context.read<LmtCubit>();
                          cubit.markNotificationRead(notif.id);

                          if (notif.targetRoute != null) {
                            Navigator.pop(context);
                            AppRouter.navigateTo(context, notif.targetRoute!);
                            return;
                          }

                          if (notif.targetTabIndex != null) {
                            cubit.setActiveLayoutTab(
                              notif.targetTabIndex!,
                              openGroupId: notif.targetGroupId,
                            );
                          }
                          Navigator.pop(context);
                        },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  IconData _iconForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.chat:
        return Icons.forum_rounded;
      case NotificationCategory.calendar:
        return Icons.event_available_rounded;
      case NotificationCategory.files:
        return Icons.folder_shared_rounded;
      case NotificationCategory.posts:
        return Icons.campaign_rounded;
      case NotificationCategory.system:
        return Icons.notifications_active_rounded;
    }
  }
}
