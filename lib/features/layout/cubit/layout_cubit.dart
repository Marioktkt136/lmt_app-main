import 'dart:convert';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/data/lmt_seed_data.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/utils/app_preferences.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Layout & Navigation feature module.
typedef LayoutCubit = LmtCubit;

/// Encapsulates Layout Navigation, Online/Offline Sync, Notification Deep-Links,
/// and Demo Data Reset logic.
mixin LayoutCubitMixin on LmtBaseCubit {
  /// Switches the active bottom navigation / drawer layout tab index (`0..4`),
  /// optionally selecting a chat group or calendar event to open.
  void setActiveLayoutTab(
    int index, {
    String? openGroupId,
    String? openEventId,
  }) {
    emit(
      state.copyWith(
        activeLayoutTab: index.clamp(0, 4),
        selectedChatGroupId: openGroupId,
        clearSelectedChatGroup: openGroupId == null,
        selectedCalendarEventId: openEventId,
        clearSelectedCalendarEvent: openEventId == null,
      ),
    );
  }

  /// Clears any pending selected calendar event after its details sheet opens.
  void clearSelectedCalendarEvent() {
    if (state.selectedCalendarEventId != null) {
      emit(state.copyWith(clearSelectedCalendarEvent: true));
    }
  }

  /// Handles tapping an OS notification payload and routes to the target
  /// tab, chat group, or calendar event.
  void handleNotificationPayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map<String, dynamic>) return;
      final notifId = decoded['notifId'] as String?;
      final tab = decoded['tab'] as int?;
      final groupId = decoded['groupId'] as String?;
      final eventId = decoded['eventId'] as String?;

      if (notifId != null) {
        final updatedNotifs = state.notifications
            .map((n) => n.id == notifId ? n.copyWith(isRead: true) : n)
            .toList();
        emit(state.copyWith(notifications: updatedNotifs));
      }

      if (eventId != null) {
        setActiveLayoutTab(tab ?? 3, openEventId: eventId);
      } else if (groupId != null) {
        setActiveLayoutTab(tab ?? 1, openGroupId: groupId);
      } else if (tab != null) {
        setActiveLayoutTab(tab);
      }
    } catch (_) {}
  }

  /// Triggers a manual sync: persists local updates to the cloud repository
  /// and fetches any updates created on other devices, playing the exact custom
  /// tone for any newly arrived unread notifications targeting the active user.
  Future<void> syncNow() async {
    final previousIds = state.notifications.map((n) => n.id).toSet();
    emit(state.copyWith(isSyncing: true));
    await persistState();
    final remote = await repository.loadSnapshot();
    final currentUserId = state.currentUser.id;

    for (final n in remote.notifications) {
      if (!previousIds.contains(n.id) &&
          !n.isRead &&
          n.isVisibleTo(currentUserId)) {
        await LocalNotificationService.showInstantNotification(
          idKey: n.id,
          title: n.title,
          body: n.description,
          tone: LmtNotificationTone.fromString(n.tone),
          payloadData: {
            'notifId': n.id,
            'tab': ?n.targetTabIndex,
            'groupId': ?n.targetGroupId,
            'eventId': ?n.targetEventId,
            'route': ?n.targetRoute,
          },
        );
      }
    }

    emit(
      state.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
        members: remote.members,
        chatGroups: remote.chatGroups,
        chatMessages: remote.chatMessages,
        posts: remote.posts,
        sharedFiles: remote.sharedFiles,
        calendarEvents: remote.calendarEvents,
        notifications: remote.notifications,
      ),
    );
  }

  /// Resets application state back to the default L.M.T seed data.
  Future<void> resetDemoData() async {
    await AppPreferences.clearCachedState();
    final defaultUser = LmtSeedData.initialMembers.first;
    emit(
      state.copyWith(
        currentUser: defaultUser,
        members: LmtSeedData.initialMembers,
        chatGroups: LmtSeedData.initialGroups,
        chatMessages: LmtSeedData.initialMessages,
        posts: LmtSeedData.initialPosts,
        sharedFiles: LmtSeedData.initialSharedFiles,
        calendarEvents: LmtSeedData.initialEvents,
        notifications: LmtSeedData.initialNotifications,
        sloganOfYear: LmtSeedData.defaultSlogan,
        verseOfYear: LmtSeedData.defaultVerseAr,
        lastSyncedAt: DateTime.now(),
        clearSelectedChatGroup: true,
      ),
    );
    await persistState();
  }
}
