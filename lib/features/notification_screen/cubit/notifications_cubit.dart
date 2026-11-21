import '../../../core/cubit/lmt_cubit.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Notifications & Reminders feature module.
typedef NotificationsCubit = LmtCubit;

/// Encapsulates In-App Notification read-status management.
mixin NotificationsCubitMixin on LmtBaseCubit {
  /// Marks a single notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));
    await persistState();
  }

  /// Marks all notifications in the feed as read.
  Future<void> markAllNotificationsRead() async {
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updated));
    await persistState();
  }
}
