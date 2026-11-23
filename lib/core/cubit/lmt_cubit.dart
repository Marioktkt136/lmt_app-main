import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/calendar/cubit/calendar_cubit.dart';
import '../../features/chatting_room/cubit/chat_cubit.dart';
import '../../features/dashboard/cubit/shared_files_cubit.dart';
import '../../features/home/cubit/posts_cubit.dart';
import '../../features/khelwa/cubit/khelwa_cubit.dart';
import '../../features/layout/cubit/layout_cubit.dart';
import '../../features/members/cubit/members_cubit.dart';
import '../../features/notification_screen/cubit/notifications_cubit.dart';
import '../../features/profile/cubit/profile_cubit.dart';
import '../data/lmt_seed_data.dart';
import '../models/lmt_models.dart';
import '../repositories/lmt_repository.dart';
import '../routes/app_router.dart';
import '../services/local_notification_service.dart';
import '../utils/app_assets.dart';

export 'lmt_state.dart';

/// Application Cubit composed of modular Feature Cubits (Clean Architecture + SOLID).
///
/// Each feature's business logic lives in its own dedicated module inside
/// `lib/features/<feature>/cubit/<feature>_cubit.dart`:
/// - [LayoutCubitMixin] (`lib/features/layout/cubit/layout_cubit.dart`)
/// - [AuthCubitMixin] (`lib/features/auth/cubit/auth_cubit.dart`)
/// - [ProfileCubitMixin] (`lib/features/profile/cubit/profile_cubit.dart`)
/// - [MembersCubitMixin] (`lib/features/members/cubit/members_cubit.dart`)
/// - [ChatCubitMixin] (`lib/features/chatting_room/cubit/chat_cubit.dart`)
/// - [PostsCubitMixin] (`lib/features/home/cubit/posts_cubit.dart`)
/// - [SharedFilesCubitMixin] (`lib/features/dashboard/cubit/shared_files_cubit.dart`)
/// - [CalendarCubitMixin] (`lib/features/calendar/cubit/calendar_cubit.dart`)
/// - [NotificationsCubitMixin] (`lib/features/notification_screen/cubit/notifications_cubit.dart`)
/// - [KhelwaCubitMixin] (`lib/features/khelwa/cubit/khelwa_cubit.dart`)
class LmtCubit extends LmtBaseCubit
    with
        LayoutCubitMixin,
        AuthCubitMixin,
        ProfileCubitMixin,
        MembersCubitMixin,
        ChatCubitMixin,
        PostsCubitMixin,
        SharedFilesCubitMixin,
        CalendarCubitMixin,
        NotificationsCubitMixin,
        KhelwaCubitMixin {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<AppNotificationModel>>? _notificationsSubscription;

  LmtCubit({LmtRepository? repository})
      : super(repository: repository ?? const LmtLocalRepositoryImpl()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final snapshot = await repository.loadSnapshot();

    // Ensure the dedicated Khelwa Group ('grp_khelwa') always exists and
    // includes all team members (so every member sees it in their Chats list).
    final groups = List<ChatGroupModel>.from(snapshot.chatGroups);
    final allMemberIds = <String>{
      ...snapshot.members.map((m) => m.id),
      snapshot.currentUser.id,
    }.toList();

    final khelwaIdx = groups.indexWhere((g) => g.id == 'grp_khelwa');
    if (khelwaIdx == -1) {
      final seedKhelwaGroup = LmtSeedData.initialGroups
          .where((g) => g.id == 'grp_khelwa')
          .firstOrNull;
      groups.insert(
        0,
        (seedKhelwaGroup ??
                ChatGroupModel(
                  id: 'grp_khelwa',
                  name: 'جروب الخلوة اليومية 🙏',
                  description:
                      'جروب مخصص لمتابعة الخلوة اليومية ونشر القائمة اليومية بأسماء من أخذوا الخلوة كل يوم',
                  imagePath: AppAssets.prayIcon,
                  memberIds: allMemberIds,
                  adminId: snapshot.members.first.id,
                  adminName: snapshot.members.first.name,
                  isPinned: true,
                  createdAt: DateTime.now(),
                ))
            .copyWith(memberIds: allMemberIds),
      );
    } else {
      final existing = groups[khelwaIdx];
      final mergedIds = <String>{...existing.memberIds, ...allMemberIds}.toList();
      if (mergedIds.length != existing.memberIds.length) {
        groups[khelwaIdx] = existing.copyWith(memberIds: mergedIds);
      }
    }

    emit(
      state.copyWith(
        isInitialized: true,
        biometricEnabled: snapshot.biometricEnabled,
        sloganOfYear: snapshot.sloganOfYear,
        verseOfYear: snapshot.verseOfYear,
        currentUser: snapshot.currentUser,
        members: snapshot.members,
        chatGroups: groups,
        chatMessages: snapshot.chatMessages,
        posts: snapshot.posts,
        sharedFiles: snapshot.sharedFiles,
        calendarEvents: snapshot.calendarEvents,
        notifications: snapshot.notifications,
      ),
    );

    knownNotificationIds.addAll(snapshot.notifications.map((n) => n.id));
    _startConnectivityListener();
    _startNotificationsListener();
    scheduleEndOfDayKhelwaSummaryTimer();
    await scheduleAllCalendarNotifications();
    await syncDueCalendarReminders();

    LocalNotificationService.onNotificationTapped = (payload) {
      syncDueCalendarReminders();
      handleNotificationPayload(payload);
      final nav = AppRouter.navigatorKey.currentState;
      if (nav != null && nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
      }
    };
    if (LocalNotificationService.pendingLaunchPayload != null) {
      handleNotificationPayload(LocalNotificationService.pendingLaunchPayload);
      LocalNotificationService.pendingLaunchPayload = null;
    }
  }

  void _startConnectivityListener() {
    try {
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final connected = results.any((r) => r != ConnectivityResult.none);
        emit(
          state.copyWith(
            isOnline: connected,
            lastSyncedAt: connected ? DateTime.now() : state.lastSyncedAt,
          ),
        );
      });
    } catch (_) {}
  }

  void _startNotificationsListener() {
    _notificationsSubscription?.cancel();
    try {
      _notificationsSubscription = repository.watchNotifications().listen(
        _onRemoteNotificationsSnapshot,
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _onRemoteNotificationsSnapshot(List<AppNotificationModel> remoteList) {
    if (isClosed || !state.isInitialized) return;
    if (state.isSyncing) {
      knownNotificationIds.addAll(remoteList.map((n) => n.id));
      return;
    }

    final currentUserId = state.currentUser.id;
    var hasNewIncomingAlert = false;

    for (final n in remoteList) {
      final isBrandNew = knownNotificationIds.add(n.id) &&
          !state.notifications.any((existing) => existing.id == n.id);
      if (isBrandNew && !n.isRead && n.isVisibleTo(currentUserId)) {
        hasNewIncomingAlert = true;
        LocalNotificationService.showInstantNotification(
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

    if (isSuppressingRemoteNotifSync && !hasNewIncomingAlert) {
      return;
    }

    if (hasNewIncomingAlert ||
        remoteList.length != state.notifications.length) {
      emit(state.copyWith(notifications: remoteList));
    }
    if (hasNewIncomingAlert && !state.isSyncing) {
      syncNow();
    }
  }

  @override
  Future<void> close() {
    cancelKhelwaTimer();
    cancelCalendarTimers();
    cancelTypingWatchers();
    _connectivitySubscription?.cancel();
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
