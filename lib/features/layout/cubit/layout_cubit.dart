import 'dart:convert';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/data/lmt_seed_data.dart';
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

  /// Triggers a manual state sync and persists the snapshot to local storage.
  Future<void> syncNow() async {
    emit(state.copyWith(isSyncing: true));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await persistState();
    emit(
      state.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
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
