import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'cubit/notifications_cubit.dart';
import '../../core/models/lmt_models.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/adaptive_layout.dart';

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
        final visibleNotifications = state.visibleNotifications;

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
              IconButton(
                tooltip: isArabic ? 'تجربة الإشعار والصوت' : 'Test Sound & Alert',
                onPressed: () async {
                  final granted = await LocalNotificationService.testToneAndAlert(
                    tone: LmtNotificationTone.chatMessage,
                    title: isArabic
                        ? 'تجربة إشعار L.M.T 🔔'
                        : 'L.M.T Test Alert 🔔',
                    body: isArabic
                        ? 'إذا سمعت النغمة ورأيت الإشعار فالتنبيهات تعمل بنجاح ✅'
                        : 'If you hear the chime and see this alert, notifications work ✅',
                  );
                  if (!granted && context.mounted) {
                    showDialog<void>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: Text(
                          isArabic ? 'تنبيه الإشعارات' : 'Notification Alert',
                        ),
                        content: Text(
                          isArabic
                              ? 'تم تشغيل الصوت — يرجى السماح بالإشعارات من إعدادات الجهاز/المتصفح.'
                              : 'Sound played — please allow notifications in device/browser settings.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text(isArabic ? 'حسناً' : 'OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                ),
              ),
              if (visibleNotifications.isNotEmpty) ...[
                IconButton(
                  tooltip: isArabic ? 'قراءة الكل' : 'Mark All Read',
                  onPressed: () {
                    context.read<LmtCubit>().markAllNotificationsRead();
                  },
                  icon: const Icon(
                    Icons.done_all_rounded,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          isArabic ? 'مسح كل الإشعارات؟' : 'Clean All Notifications?',
                        ),
                        content: Text(
                          isArabic
                              ? 'سيتم حذف جميع الإشعارات الظاهرة في هذه الصفحة.'
                              : 'All notifications visible on this page will be cleared.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(isArabic ? 'مسح الكل' : 'Clean All'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await context.read<LmtCubit>().clearAllNotifications();
                    }
                  },
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    isArabic ? 'مسح الكل' : 'Clean All',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              _OsNotificationsBanner(isArabic: isArabic),
              Expanded(
                child: visibleNotifications.isEmpty
                    ? Center(
                        child: Text(
                          isArabic
                              ? 'لا توجد إشعارات حالياً'
                              : 'No notifications yet',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : AdaptiveContentBox(
                        maxWidth: 820,
                        child: ListView.builder(
                          padding: EdgeInsets.all(14.w),
                          physics: const BouncingScrollPhysics(),
                          itemCount: visibleNotifications.length,
                  itemBuilder: (context, index) {
                    final notif = visibleNotifications[index];
                    final isUnread = !notif.isRead;

                    return Dismissible(
                      key: ValueKey(notif.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        alignment: AlignmentDirectional.centerEnd,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) =>
                          context.read<LmtCubit>().deleteNotification(notif.id),
                      child: Container(
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
                                  margin: EdgeInsetsDirectional.only(end: 4.w),
                                  decoration: BoxDecoration(
                                    color: accentGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                tooltip: isArabic ? 'حذف الإشعار' : 'Delete',
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18.sp,
                                  color: AppColors.error,
                                ),
                                onPressed: () => context
                                    .read<LmtCubit>()
                                    .deleteNotification(notif.id),
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
                                openEventId: notif.targetEventId,
                              );
                            }
                            Navigator.pop(context);
                          },
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                ),
              ),
            ],
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

class _OsNotificationsBanner extends StatefulWidget {
  final bool isArabic;

  const _OsNotificationsBanner({required this.isArabic});

  @override
  State<_OsNotificationsBanner> createState() => _OsNotificationsBannerState();
}

class _OsNotificationsBannerState extends State<_OsNotificationsBanner> {
  bool _isGranted = true;
  bool _isWebDenied = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (kIsWeb) {
      if (!LocalNotificationService.isWebNotificationsSupported) {
        if (mounted) setState(() => _isGranted = true);
        return;
      }
      final status = LocalNotificationService.webPermissionStatus;
      if (mounted) {
        setState(() {
          _isGranted = status == 'granted';
          _isWebDenied = status == 'denied';
        });
      }
      return;
    }
    final enabled = await LocalNotificationService.areOsNotificationsEnabled();
    if (mounted) {
      setState(() => _isGranted = enabled);
    }
  }

  Future<void> _enable() async {
    final granted = await LocalNotificationService.testToneAndAlert(
      tone: LmtNotificationTone.normal,
      title: widget.isArabic
          ? 'تم تفعيل الإشعارات بنجاح 🔔'
          : 'Notifications Enabled 🔔',
      body: widget.isArabic
          ? 'ستصلك الآن تنبيهات الرسائل والمنشورات والفعاليات بالأصوات المخصصة.'
          : 'You will now receive real-time alerts with custom chimes.',
    );
    await _checkStatus();
    if (!granted && mounted && !kIsWeb) {
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(
            widget.isArabic ? 'تفعيل الإشعارات' : 'Enable Notifications',
          ),
          content: Text(
            widget.isArabic
                ? 'يرجى تفعيل إذن الإشعارات للتطبيق من إعدادات الهاتف -> التطبيقات -> L.M.T App.'
                : 'Please enable app notifications in Phone Settings -> Apps -> L.M.T App.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(widget.isArabic ? 'حسناً' : 'OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGranted) return const SizedBox.shrink();
    final primary = AppColors.primaryOf(context);
    final denied = kIsWeb && _isWebDenied;

    return AdaptiveContentBox(
      maxWidth: 820,
      child: Container(
        margin: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 2.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: primary.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(
              denied
                  ? Icons.notifications_off_rounded
                  : Icons.notifications_active_rounded,
              color: primary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                denied
                    ? (widget.isArabic
                        ? 'إشعارات المتصفح محظورة حالياً — اسمح بالإشعارات من إعدادات الموقع/المتصفح.'
                        : 'Browser notifications are blocked — allow them from site settings.')
                    : (widget.isArabic
                        ? 'إشعارات النظام غير مفعلة — اضغط "تفعيل الآن" لاستلام التنبيهات والأصوات المخصصة.'
                        : 'System notifications are off — tap Enable to receive real-time alerts & chimes.'),
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            if (!denied) ...[
              SizedBox(width: 10.w),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                ),
                onPressed: _enable,
                child: Text(
                  widget.isArabic ? 'تفعيل الآن' : 'Enable',
                  style: TextStyle(fontSize: 11.5.sp),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
