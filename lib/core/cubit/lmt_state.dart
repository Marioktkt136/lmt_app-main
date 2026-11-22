import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/lmt_seed_data.dart';
import '../models/lmt_models.dart';
import '../repositories/lmt_repository.dart';
import '../services/local_notification_service.dart';

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
  });

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
    );
  }

  Map<String, dynamic> toJson() => {
        'currentUser': currentUser.toJson(),
        'members': members.map((e) => e.toJson()).toList(),
        'chatGroups': chatGroups.map((e) => e.toJson()).toList(),
        'chatMessages': chatMessages.map((e) => e.toJson()).toList(),
        'posts': posts.map((e) => e.toJson()).toList(),
        'sharedFiles': sharedFiles.map((e) => e.toJson()).toList(),
        'calendarEvents': calendarEvents.map((e) => e.toJson()).toList(),
        'notifications': notifications.map((e) => e.toJson()).toList(),
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
      ];
}

/// Abstract Base Cubit providing shared persistence and notification dispatch
/// to all modular Feature Cubits.
abstract class LmtBaseCubit extends Cubit<LmtState> {
  final LmtRepository repository;

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
    await repository.persistSnapshot(
      stateJson: state.toJson(),
      currentUserId: state.currentUser.id,
    );
  }

  /// Dispatches an in-app and OS-level notification with category-matched
  /// custom tone (`Calendar_Notifications` vs `Normal_Notifications`) and
  /// optional [targetMemberIds] audience scoping.
  void pushNotification({
    String? id,
    required String title,
    required String description,
    required NotificationCategory category,
    int? targetTabIndex,
    String? targetGroupId,
    String? targetEventId,
    String? targetRoute,
    List<String> targetMemberIds = const [],
    bool showOsBanner = true,
  }) {
    final resolvedId = id ?? 'notif_${DateTime.now().millisecondsSinceEpoch}';
    if (state.notifications.any((n) => n.id == resolvedId)) {
      return;
    }

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
    );

    if (showOsBanner && notif.isVisibleTo(state.currentUser.id)) {
      final tone = category == NotificationCategory.calendar
          ? LmtNotificationTone.calendar
          : LmtNotificationTone.normal;
      LocalNotificationService.showInstantNotification(
        idKey: notif.id,
        title: title,
        body: description,
        tone: tone,
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
