import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/lmt_seed_data.dart';
import '../models/lmt_models.dart';
import '../repositories/lmt_repository.dart';
import '../services/background_sync_bridge.dart';
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
      visibleNotifications.where((n) => !n.isReadFor(currentUser.id)).length;

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
  final Map<String, ChatMessageModel> pendingOutgoingMessages =
      <String, ChatMessageModel>{};
  final Map<String, PostModel> pendingOutgoingPosts = <String, PostModel>{};
  final Map<String, AppNotificationModel> pendingOutgoingNotifications =
      <String, AppNotificationModel>{};
  DateTime? _suppressRemoteNotifUntil;
  DateTime? _lastPendingChatRetryAt;
  DateTime? _lastPendingPostRetryAt;

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

  /// Merges [remoteMessages] with any unconfirmed [pendingOutgoingMessages]
  /// and preserves local `seenBy` (and `hasListened`) receipts belonging to
  /// [state.currentUser] so concurrent live snapshots or syncs never revert reads.
  ChatMessagesMergeResult mergeRemoteChatMessages(
    List<ChatMessageModel> remoteMessages,
  ) {
    final viewerId = state.currentUser.id;
    final remoteMsgIds = remoteMessages.map((m) => m.id).toSet();
    pendingOutgoingMessages.removeWhere((id, _) => remoteMsgIds.contains(id));
    pendingOutgoingNotifications.removeWhere(
      (id, _) => remoteMsgIds.contains(id),
    );
    final now = DateTime.now();
    pendingOutgoingMessages.removeWhere(
      (_, msg) => now.difference(msg.sentAt).inMinutes >= 5,
    );

    final localViewerReceiptByMsgId = <String, SeenStatusModel>{};
    for (final localMsg in state.chatMessages) {
      if (localMsg.senderId == viewerId) continue;
      final receipt =
          localMsg.seenBy.where((s) => s.memberId == viewerId).firstOrNull;
      if (receipt != null) {
        localViewerReceiptByMsgId[localMsg.id] = receipt;
      }
    }

    final unsyncedSeenMessages = <ChatMessageModel>[];
    final merged = <ChatMessageModel>[];
    for (final remoteMsg in remoteMessages) {
      final localReceipt = localViewerReceiptByMsgId[remoteMsg.id];
      if (localReceipt == null || remoteMsg.senderId == viewerId) {
        merged.add(remoteMsg);
        continue;
      }
      final remoteIdx =
          remoteMsg.seenBy.indexWhere((s) => s.memberId == viewerId);
      if (remoteIdx == -1) {
        final preserved = remoteMsg.copyWith(
          seenBy: [...remoteMsg.seenBy, localReceipt],
        );
        merged.add(preserved);
        unsyncedSeenMessages.add(preserved);
      } else if (localReceipt.hasListened &&
          !remoteMsg.seenBy[remoteIdx].hasListened) {
        final existing = remoteMsg.seenBy[remoteIdx];
        final upgradedSeen = List<SeenStatusModel>.from(remoteMsg.seenBy);
        upgradedSeen[remoteIdx] = SeenStatusModel(
          memberId: existing.memberId,
          memberName: existing.memberName,
          avatarPath: existing.avatarPath,
          timestamp: existing.timestamp,
          hasListened: true,
        );
        merged.add(remoteMsg.copyWith(seenBy: upgradedSeen));
      } else {
        merged.add(remoteMsg);
      }
    }

    var hasUnconfirmedPending = false;
    if (pendingOutgoingMessages.isNotEmpty) {
      for (final pending in pendingOutgoingMessages.values) {
        if (!remoteMsgIds.contains(pending.id)) {
          merged.add(pending);
          hasUnconfirmedPending = true;
        }
      }
      merged.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    }

    return ChatMessagesMergeResult(
      messages: merged,
      hasUnconfirmedPending: hasUnconfirmedPending,
      unsyncedSeenMessages: unsyncedSeenMessages,
    );
  }

  /// Merges [remotePosts] with any freshly created [pendingOutgoingPosts]
  /// still awaiting Firestore confirmation so new posts/polls never flicker away.
  List<PostModel> mergeRemotePosts(List<PostModel> remotePosts) {
    final remotePostIds = remotePosts.map((p) => p.id).toSet();
    pendingOutgoingPosts.removeWhere((id, _) => remotePostIds.contains(id));
    pendingOutgoingNotifications.removeWhere(
      (id, _) => remotePostIds.contains(id),
    );
    final now = DateTime.now();
    pendingOutgoingPosts.removeWhere(
      (_, post) => now.difference(post.publishTime).inMinutes >= 5,
    );

    if (pendingOutgoingPosts.isEmpty) {
      pendingOutgoingNotifications.removeWhere(
        (id, _) => !pendingOutgoingMessages.containsKey(id),
      );
      return remotePosts;
    }

    final merged = List<PostModel>.from(remotePosts);
    var added = false;
    for (final pending in pendingOutgoingPosts.values) {
      if (!remotePostIds.contains(pending.id)) {
        merged.add(pending);
        added = true;
      }
    }
    if (added) {
      merged.sort((a, b) => b.publishTime.compareTo(a.publishTime));
    }
    return merged;
  }

  /// Retries any unconfirmed outgoing posts still missing from cloud storage.
  void retryPendingPostWrites({bool force = false}) {
    if (!state.isOnline || pendingOutgoingPosts.isEmpty) return;
    final now = DateTime.now();
    final cooldownExpired = force ||
        _lastPendingPostRetryAt == null ||
        now.difference(_lastPendingPostRetryAt!).inSeconds >= 3;
    if (!cooldownExpired) return;
    _lastPendingPostRetryAt = now;

    for (final pending in pendingOutgoingPosts.values) {
      unawaited(
        repository.savePostToCloud(
          post: pending,
          notification: pendingOutgoingNotifications[pending.id],
        ),
      );
    }
  }

  /// Retries any unconfirmed outgoing chat messages or locally recorded seen
  /// receipts that have not yet appeared in the cloud snapshot.
  void retryPendingChatWrites(
    ChatMessagesMergeResult merged, {
    bool force = false,
  }) {
    if (!state.isOnline) return;
    if (!merged.hasUnconfirmedPending && merged.unsyncedSeenMessages.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final cooldownExpired = force ||
        _lastPendingChatRetryAt == null ||
        now.difference(_lastPendingChatRetryAt!).inSeconds >= 3;
    if (!cooldownExpired) return;
    _lastPendingChatRetryAt = now;

    for (final pending in pendingOutgoingMessages.values) {
      unawaited(
        repository.sendChatMessageToCloud(
          message: pending,
          notification: pendingOutgoingNotifications[pending.id],
        ),
      );
    }
    if (merged.unsyncedSeenMessages.isNotEmpty) {
      final v = state.currentUser;
      final receipt = merged.unsyncedSeenMessages.first.seenBy
              .where((s) => s.memberId == v.id)
              .firstOrNull ??
          SeenStatusModel(
            memberId: v.id,
            memberName: v.name,
            avatarPath: v.avatarPath,
            timestamp: now,
            hasListened: false,
          );
      unawaited(
        repository.markMessagesSeenInCloud(
          updatedMessages: merged.unsyncedSeenMessages,
          viewerReceipt: receipt,
        ),
      );
    }
  }

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
      if (n.isReadFor(userId) ||
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
      if (n.isReadFor(userId) || !n.isVisibleTo(userId)) continue;
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
      unawaited(BackgroundSyncBridge.recordAlertedIds(userId, newlyAlerted));
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
    unawaited(BackgroundSyncBridge.recordAlertedIds(userId, [resolvedId]));
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

/// Result of merging remote chat messages with local pending sends and reads.
class ChatMessagesMergeResult {
  /// Merged chronological list of chat messages for state emission.
  final List<ChatMessageModel> messages;

  /// Whether any locally sent outgoing message is still awaiting remote echo.
  final bool hasUnconfirmedPending;

  /// Messages whose local `seenBy` receipt for `currentUser` is absent remotely.
  final List<ChatMessageModel> unsyncedSeenMessages;

  const ChatMessagesMergeResult({
    required this.messages,
    required this.hasUnconfirmedPending,
    required this.unsyncedSeenMessages,
  });
}
