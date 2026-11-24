import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/lmt_seed_data.dart';
import '../models/lmt_models.dart';
import '../repositories/lmt_repository.dart';
import '../services/local_notification_service.dart';
import '../utils/app_preferences.dart';

/// Immutable Application State for L.M.T (Clean Architecture + Feature Cubits).
class LmtState extends Equatable {
  final bool isInitialized;
  final bool isOnline;
  final bool isSyncing;
  final DateTime lastSyncedAt;
  final bool biometricEnabled;
  final String sloganOfYear;
  final String verseOfYear;
  final int activeLayoutTab;
  final String? selectedChatGroupId;
  final String? selectedCalendarEventId;

  final MemberModel currentUser;
  final List<MemberModel> members;
  final List<ChatGroupModel> chatGroups;
  final List<ChatMessageModel> chatMessages;
  final List<PostModel> posts;
  final List<SharedFileModel> sharedFiles;
  final List<CalendarEventModel> calendarEvents;
  final List<AppNotificationModel> notifications;
  final List<KhelwaDayModel> khelwaDays;
  final Map<String, List<TypingMemberStatus>> typingByGroup;

  const LmtState({
    this.isInitialized = false,
    this.isOnline = true,
    this.isSyncing = false,
    required this.lastSyncedAt,
    this.biometricEnabled = true,
    this.sloganOfYear = LmtSeedData.defaultSlogan,
    this.verseOfYear = LmtSeedData.defaultVerseAr,
    this.activeLayoutTab = 0,
    this.selectedChatGroupId,
    this.selectedCalendarEventId,
    required this.currentUser,
    required this.members,
    required this.chatGroups,
    required this.chatMessages,
    required this.posts,
    required this.sharedFiles,
    required this.calendarEvents,
    required this.notifications,
    this.khelwaDays = const [],
    this.typingByGroup = const {},
  });

  /// Returns active members currently typing in [groupId], EXCLUDING
  /// [currentUser.id], and filtering out stale heartbeats older than 8 seconds.
  List<TypingMemberStatus> visibleTypingMembersForGroup(
    String groupId, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final entries = typingByGroup[groupId] ?? const [];
    return entries
        .where(
          (t) =>
              t.memberId != currentUser.id &&
              ref.difference(t.updatedAt).inSeconds.abs() <= 8,
        )
        .toList();
  }

  /// Returns only notifications intended for the currently logged-in user.
  List<AppNotificationModel> get visibleNotifications =>
      notifications.where((n) => n.isVisibleTo(currentUser.id)).toList();

  int get unreadNotificationsCount =>
      visibleNotifications.where((n) => !n.isRead).length;

  /// Returns chat groups sorted with Pinned groups at the top, then by latest message.
  List<ChatGroupModel> get sortedChatGroups {
    final copy = List<ChatGroupModel>.from(chatGroups);
    copy.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final aLast = lastMessageForGroup(a.id)?.sentAt ?? a.createdAt;
      final bLast = lastMessageForGroup(b.id)?.sentAt ?? b.createdAt;
      return bLast.compareTo(aLast);
    });
    return copy;
  }

  List<ChatMessageModel> messagesForGroup(String groupId) {
    final list = chatMessages.where((m) => m.groupId == groupId).toList();
    list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return list;
  }

  ChatMessageModel? lastMessageForGroup(String groupId) {
    final list = messagesForGroup(groupId);
    return list.isEmpty ? null : list.last;
  }

  /// Counts incoming messages inside [groupId] not yet seen by [currentUser].
  int unreadMessagesCountForGroup(String groupId) {
    final uid = currentUser.id;
    final group = chatGroups.where((g) => g.id == groupId).firstOrNull;
    if (group == null || !group.memberIds.contains(uid)) return 0;
    var count = 0;
    for (final msg in chatMessages) {
      if (msg.groupId != groupId) continue;
      if (msg.senderId == uid) continue;
      if (!msg.seenBy.any((s) => s.memberId == uid)) {
        count++;
      }
    }
    return count;
  }

  /// Returns the ID of the oldest incoming message in [groupId] not yet seen by
  /// [currentUser], or `null` when all messages are already seen.
  String? firstUnreadMessageIdForGroup(String groupId) {
    final uid = currentUser.id;
    for (final msg in messagesForGroup(groupId)) {
      if (msg.senderId == uid) continue;
      if (!msg.seenBy.any((s) => s.memberId == uid)) {
        return msg.id;
      }
    }
    return null;
  }

  LmtState copyWith({
    bool? isInitialized,
    bool? isOnline,
    bool? isSyncing,
    DateTime? lastSyncedAt,
    bool? biometricEnabled,
    String? sloganOfYear,
    String? verseOfYear,
    int? activeLayoutTab,
    String? selectedChatGroupId,
    bool clearSelectedChatGroup = false,
    String? selectedCalendarEventId,
    bool clearSelectedCalendarEvent = false,
    MemberModel? currentUser,
    List<MemberModel>? members,
    List<ChatGroupModel>? chatGroups,
    List<ChatMessageModel>? chatMessages,
    List<PostModel>? posts,
    List<SharedFileModel>? sharedFiles,
    List<CalendarEventModel>? calendarEvents,
    List<AppNotificationModel>? notifications,
    List<KhelwaDayModel>? khelwaDays,
    Map<String, List<TypingMemberStatus>>? typingByGroup,
  }) {
    return LmtState(
      isInitialized: isInitialized ?? this.isInitialized,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      sloganOfYear: sloganOfYear ?? this.sloganOfYear,
      verseOfYear: verseOfYear ?? this.verseOfYear,
      activeLayoutTab: activeLayoutTab ?? this.activeLayoutTab,
      selectedChatGroupId: clearSelectedChatGroup
          ? null
          : (selectedChatGroupId ?? this.selectedChatGroupId),
      selectedCalendarEventId: clearSelectedCalendarEvent
          ? null
          : (selectedCalendarEventId ?? this.selectedCalendarEventId),
      currentUser: currentUser ?? this.currentUser,
      members: members ?? this.members,
      chatGroups: chatGroups ?? this.chatGroups,
      chatMessages: chatMessages ?? this.chatMessages,
      posts: posts ?? this.posts,
      sharedFiles: sharedFiles ?? this.sharedFiles,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      notifications: notifications ?? this.notifications,
      khelwaDays: khelwaDays ?? this.khelwaDays,
      typingByGroup: typingByGroup ?? this.typingByGroup,
    );
  }

  Map<String, dynamic> toJson() => {
        'sloganOfYear': sloganOfYear,
        'verseOfYear': verseOfYear,
        'currentUser': currentUser.toJson(),
        'members': members.map((e) => e.toJson()).toList(),
        'chatGroups': chatGroups.map((e) => e.toJson()).toList(),
        'chatMessages': chatMessages.map((e) => e.toJson()).toList(),
        'posts': posts.map((e) => e.toJson()).toList(),
        'sharedFiles': sharedFiles.map((e) => e.toJson()).toList(),
        'calendarEvents': calendarEvents.map((e) => e.toJson()).toList(),
        'notifications': notifications.map((e) => e.toJson()).toList(),
        'khelwaDays': khelwaDays.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        isInitialized,
        isOnline,
        isSyncing,
        lastSyncedAt,
        biometricEnabled,
        sloganOfYear,
        verseOfYear,
        activeLayoutTab,
        selectedChatGroupId,
        selectedCalendarEventId,
        currentUser,
        members,
        chatGroups,
        chatMessages,
        posts,
        sharedFiles,
        calendarEvents,
        notifications,
        khelwaDays,
        typingByGroup,
      ];
}

/// Abstract Base Cubit providing shared persistence and notification dispatch
/// to all modular Feature Cubits.
abstract class LmtBaseCubit extends Cubit<LmtState> {
  static int _notificationSeq = 0;
  final LmtRepository repository;
  final Set<String> knownNotificationIds = <String>{};
  DateTime? _suppressRemoteNotifUntil;

  /// Whether remote notification snapshot syncing is paused right after a
  /// local write to prevent stale delete/read bounces without spawning Timers.
  bool get isSuppressingRemoteNotifSync =>
      _suppressRemoteNotifUntil != null &&
      DateTime.now().isBefore(_suppressRemoteNotifUntil!);

  LmtBaseCubit({required this.repository})
      : super(
          LmtState(
            lastSyncedAt: DateTime.now(),
            currentUser: LmtSeedData.initialMembers.first,
            members: LmtSeedData.initialMembers,
            chatGroups: LmtSeedData.initialGroups,
            chatMessages: LmtSeedData.initialMessages,
            posts: LmtSeedData.initialPosts,
            sharedFiles: LmtSeedData.initialSharedFiles,
            calendarEvents: LmtSeedData.initialEvents,
            notifications: LmtSeedData.initialNotifications,
          ),
        );

  /// Persists the current state snapshot to the underlying [LmtRepository].
  Future<void> persistState() async {
    _suppressRemoteNotifUntil = DateTime.now().add(const Duration(seconds: 1));
    try {
      await repository.persistSnapshot(
        stateJson: state.toJson(),
        currentUserId: state.currentUser.id,
      );
    } finally {
      _suppressRemoteNotifUntil =
          DateTime.now().add(const Duration(milliseconds: 800));
    }
  }

  /// Hydrates previously alerted notification IDs for [userId] from disk and
  /// suppresses ancient (>24h) or already-read history so real unread alerts
  /// never re-trigger across restarts or user switches.
  Future<void> seedKnownNotificationsForUser(
    String userId,
    List<AppNotificationModel> notifications, {
    bool markRecentUnreadAsKnown = false,
  }) async {
    final persisted = await AppPreferences.getAlertedNotificationIds(userId);
    for (final id in persisted) {
      knownNotificationIds.add('$userId::$id');
    }
    final now = DateTime.now();
    for (final n in notifications) {
      final isOld = now.difference(n.dateTime).abs() > const Duration(hours: 24);
      if (n.isRead ||
          !n.isVisibleTo(userId) ||
          isOld ||
          markRecentUnreadAsKnown) {
        knownNotificationIds.add('$userId::${n.id}');
      }
    }
  }

  /// Dispatches OS/Web notifications & custom tones for every unread
  /// notification visible to `state.currentUser` that has not yet been alerted
  /// on this device for this user. Returns `true` if at least one fired.
  bool alertUnseenNotificationsForCurrentUser(
    List<AppNotificationModel> notifications,
  ) {
    final userId = state.currentUser.id;
    final now = DateTime.now();
    final newlyAlerted = <String>[];

    for (final n in notifications) {
      if (n.isRead || !n.isVisibleTo(userId)) continue;
      if (now.difference(n.dateTime).abs() > const Duration(hours: 24)) {
        continue;
      }
      final key = '$userId::${n.id}';
      if (!knownNotificationIds.add(key)) continue;

      newlyAlerted.add(n.id);
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

    if (newlyAlerted.isNotEmpty) {
      unawaited(AppPreferences.addAlertedNotificationIds(userId, newlyAlerted));
      return true;
    }
    return false;
  }

  /// Dispatches an in-app and OS-level notification with category-matched or
  /// explicit custom [tone] (`Chat_Message_Tone`, `Post_Interactions`,
  /// `Message_Reacts`, `Calendar_Notifications`, `Normal_Notifications`) and
  /// optional [targetMemberIds] / [excludedMemberIds] audience scoping.
  void pushNotification({
    String? id,
    required String title,
    required String description,
    required NotificationCategory category,
    LmtNotificationTone? tone,
    int? targetTabIndex,
    String? targetGroupId,
    String? targetEventId,
    String? targetRoute,
    List<String> targetMemberIds = const [],
    List<String> excludedMemberIds = const [],
    bool showOsBanner = true,
  }) {
    final resolvedId = id ??
        'notif_${DateTime.now().microsecondsSinceEpoch}_${++_notificationSeq}';
    final userId = state.currentUser.id;
    knownNotificationIds.add('$userId::$resolvedId');
    unawaited(AppPreferences.addAlertedNotificationIds(userId, [resolvedId]));
    if (state.notifications.any((n) => n.id == resolvedId)) {
      return;
    }

    final resolvedTone = tone ??
        (category == NotificationCategory.calendar
            ? LmtNotificationTone.calendar
            : (category == NotificationCategory.chat
                ? LmtNotificationTone.chatMessage
                : LmtNotificationTone.normal));

    final notif = AppNotificationModel(
      id: resolvedId,
      title: title,
      description: description,
      dateTime: DateTime.now(),
      category: category,
      isRead: false,
      targetTabIndex: targetTabIndex,
      targetGroupId: targetGroupId,
      targetEventId: targetEventId,
      targetRoute: targetRoute,
      targetMemberIds: targetMemberIds,
      excludedMemberIds: excludedMemberIds,
      tone: resolvedTone.name,
    );

    if (showOsBanner && notif.isVisibleTo(state.currentUser.id)) {
      LocalNotificationService.showInstantNotification(
        idKey: notif.id,
        title: title,
        body: description,
        tone: resolvedTone,
        payloadData: {
          'notifId': notif.id,
          'tab': ?targetTabIndex,
          'groupId': ?targetGroupId,
          'eventId': ?targetEventId,
          'route': ?targetRoute,
        },
      );
    }

    emit(state.copyWith(notifications: [notif, ...state.notifications]));
  }
}
