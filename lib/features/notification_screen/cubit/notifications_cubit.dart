import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Notifications & Reminders feature module.
typedef NotificationsCubit = LmtCubit;

/// Encapsulates In-App Notification read-status and per-user deletion logic.
mixin NotificationsCubitMixin on LmtBaseCubit {
  AppNotificationModel? _dismissForCurrentUser(
    AppNotificationModel notif,
    String userId,
  ) {
    final updatedTargets = notif.targetMemberIds.isEmpty
        ? const <String>[]
        : notif.targetMemberIds.where((id) => id != userId).toList();

    // If this was scoped to explicit targets and none remain, remove globally.
    if (notif.targetMemberIds.isNotEmpty && updatedTargets.isEmpty) {
      return null;
    }

    final updatedExcluded = <String>{
      ...notif.excludedMemberIds,
      userId,
    }.toList();

    // If every registered member has now dismissed/excluded it, prune it.
    if (state.members.isNotEmpty &&
        state.members.every((m) => updatedExcluded.contains(m.id))) {
      return null;
    }

    return notif.copyWith(
      targetMemberIds: updatedTargets,
      excludedMemberIds: updatedExcluded,
    );
  }

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

  /// Marks all visible notifications in the feed as read.
  Future<void> markAllNotificationsRead() async {
    final currentId = state.currentUser.id;
    final updated = state.notifications.map((n) {
      if (n.isVisibleTo(currentId)) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));
    await persistState();
  }

  /// Deletes/dismisses a single notification for the active user.
  Future<void> deleteNotification(String notificationId) async {
    final currentId = state.currentUser.id;
    final updated = <AppNotificationModel>[];
    var changed = false;

    for (final n in state.notifications) {
      if (n.id != notificationId) {
        updated.add(n);
        continue;
      }
      changed = true;
      final remaining = _dismissForCurrentUser(n, currentId);
      if (remaining != null) {
        updated.add(remaining);
      }
    }

    if (!changed) return;
    emit(state.copyWith(notifications: updated));
    await persistState();
  }

  /// Cleans/removes all notifications currently visible to the active user.
  Future<void> clearAllNotifications() async {
    final currentId = state.currentUser.id;
    final updated = <AppNotificationModel>[];
    var changed = false;

    for (final n in state.notifications) {
      if (!n.isVisibleTo(currentId)) {
        updated.add(n);
        continue;
      }
      changed = true;
      final remaining = _dismissForCurrentUser(n, currentId);
      if (remaining != null) {
        updated.add(remaining);
      }
    }

    if (!changed) return;
    emit(state.copyWith(notifications: updated));
    await persistState();
  }
}
