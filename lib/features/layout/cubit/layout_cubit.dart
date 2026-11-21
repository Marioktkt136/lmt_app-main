import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/data/lmt_seed_data.dart';
import '../../../core/utils/app_preferences.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Layout & Navigation feature module.
typedef LayoutCubit = LmtCubit;

/// Encapsulates Layout Navigation, Online/Offline Sync, and Demo Data Reset logic.
mixin LayoutCubitMixin on LmtBaseCubit {
  /// Switches the active bottom navigation / drawer layout tab index (`0..4`).
  void setActiveLayoutTab(int index, {String? openGroupId}) {
    emit(
      state.copyWith(
        activeLayoutTab: index.clamp(0, 4),
        selectedChatGroupId: openGroupId,
        clearSelectedChatGroup: openGroupId == null,
      ),
    );
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
