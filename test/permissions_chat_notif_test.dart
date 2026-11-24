import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmt/core/models/lmt_models.dart';
import 'package:lmt/core/repositories/lmt_repository.dart';
import 'package:lmt/core/services/local_notification_service.dart';
import 'package:lmt/core/utils/app_assets.dart';
import 'package:lmt/core/widgets/lmt_avatar.dart';
import 'package:lmt/features/calendar/cubit/calendar_cubit.dart';
import 'package:lmt/features/chatting_room/cubit/chat_cubit.dart';
import 'package:lmt/features/chatting_room/widgets/chat_message_bubble.dart';
import 'package:lmt/features/dashboard/cubit/shared_files_cubit.dart';
import 'package:lmt/features/home/cubit/posts_cubit.dart';
import 'package:lmt/features/members/cubit/members_cubit.dart';
import 'package:lmt/features/notification_screen/cubit/notifications_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryRepo implements LmtRepository {
  @override
  Future<LmtRepositorySnapshot> loadSnapshot() async {
    return LmtRepositorySnapshot(
      biometricEnabled: true,
      sloganOfYear: '#تغيروا_2026',
      verseOfYear: 'verse',
      currentUser: _admin,
      members: [_admin, _editor, _member],
      chatGroups: [_group],
      chatMessages: const [],
      posts: const [],
      sharedFiles: const [],
      calendarEvents: const [],
      notifications: const [],
    );
  }

  @override
  Future<void> persistSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {}

  @override
  Future<void> clearCachedState() async {}

  @override
  Future<void> setGroupTypingStatus({
    required String groupId,
    required MemberModel member,
    required bool isTyping,
  }) async {}

  @override
  Stream<List<TypingMemberStatus>> watchGroupTyping(String groupId) =>
      const Stream.empty();

  @override
  Stream<List<AppNotificationModel>> watchNotifications() =>
      const Stream.empty();

  @override
  Stream<LmtRepositorySnapshot> watchLiveSnapshots() => const Stream.empty();

  @override
  Future<void> recordKhelwaCheckIn({
    required String dateKey,
    required String memberId,
    required String memberName,
  }) async {}

  @override
  Future<void> resetKhelwaDay({required String dateKey}) async {}

  @override
  Future<void> persistLocalSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {}

  @override
  Future<void> sendChatMessageToCloud({
    required ChatMessageModel message,
    AppNotificationModel? notification,
  }) async {}

  @override
  Future<void> markMessagesSeenInCloud({
    required List<ChatMessageModel> updatedMessages,
    required SeenStatusModel viewerReceipt,
  }) async {}
}

const _admin = MemberModel(
  id: 'LMT-2026-001',
  username: 'admin',
  password: 'password123',
  name: 'Mario Naiem',
  role: UserRole.admin,
  groups: ['جروب عام'],
  avatarPath: AppAssets.accountIcon,
);

const _editor = MemberModel(
  id: 'LMT-2026-002',
  username: 'editor1',
  password: 'password123',
  name: 'Mina Adel',
  role: UserRole.editor,
  groups: ['جروب عام'],
  avatarPath: AppAssets.accountIcon,
);

const _member = MemberModel(
  id: 'LMT-2026-003',
  username: 'member1',
  password: 'password123',
  name: 'Marina Emad',
  role: UserRole.member,
  groups: ['جروب عام'],
  avatarPath: AppAssets.accountIcon,
);

final _group = ChatGroupModel(
  id: 'grp_test',
  name: 'جروب الاختبار',
  description: 'desc',
  imagePath: AppAssets.actIcon,
  memberIds: const ['LMT-2026-001', 'LMT-2026-002'], // _member is NOT in this group!
  adminId: 'LMT-2026-001',
  adminName: 'Mario Naiem',
  isPinned: false,
  createdAt: DateTime(2026, 11, 1),
);

class _FullTestCubit extends LmtBaseCubit
    with
        ChatCubitMixin,
        PostsCubitMixin,
        SharedFilesCubitMixin,
        CalendarCubitMixin,
        MembersCubitMixin,
        NotificationsCubitMixin {
  _FullTestCubit() : super(repository: _InMemoryRepo()) {
    emit(
      state.copyWith(
        isInitialized: true,
        currentUser: _admin,
        members: [_admin, _editor, _member],
        chatGroups: [_group],
      ),
    );
  }

  void switchActor(MemberModel actor) {
    emit(state.copyWith(currentUser: actor));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Chat Seen Receipts & Sender Avatar', () {
    test('new message starts with empty seenBy and only real group visitors are marked', () async {
      final cubit = _FullTestCubit();
      await cubit.sendChatMessage(
        groupId: 'grp_test',
        type: MessageType.text,
        content: 'Hello team!',
      );

      final msg = cubit.state.chatMessages.single;
      // Sender and unrelated app members must NOT be pre-marked as Seen.
      expect(msg.seenBy, isEmpty);

      // Sender entering the room must NOT add themselves to seenBy.
      await cubit.markGroupMessagesSeen('grp_test');
      expect(cubit.state.chatMessages.single.seenBy, isEmpty);

      // Non-group member cannot mark seen.
      cubit.switchActor(_member);
      await cubit.markGroupMessagesSeen('grp_test');
      expect(cubit.state.chatMessages.single.seenBy, isEmpty);

      // Group member (_editor) enters the group room -> added to seenBy.
      cubit.switchActor(_editor);
      await cubit.markGroupMessagesSeen('grp_test');
      final viewers = cubit.state.chatMessages.single.seenBy;
      expect(viewers, hasLength(1));
      expect(viewers.single.memberId, _editor.id);

      await cubit.close();
    });

    testWidgets('ChatMessageBubble shows sender CircularAvatar and hides Seen count from non-senders', (tester) async {
      final msg = ChatMessageModel(
        id: 'm1',
        groupId: 'grp_test',
        senderId: _admin.id,
        senderName: _admin.name,
        senderAvatar: _admin.avatarPath,
        senderRole: _admin.role,
        type: MessageType.text,
        content: 'Sample msg',
        seenBy: [
          SeenStatusModel(
            memberId: _admin.id, // legacy self entry should still be excluded
            memberName: _admin.name,
            avatarPath: _admin.avatarPath,
            timestamp: DateTime(2026, 11, 23, 13, 0),
          ),
          SeenStatusModel(
            memberId: _editor.id,
            memberName: _editor.name,
            avatarPath: _editor.avatarPath,
            timestamp: DateTime(2026, 11, 23, 13, 1),
          ),
        ],
        sentAt: DateTime(2026, 11, 23, 13, 0),
      );

      // Sender view (isMe: true) sees LmtAvatar and non-sender Seen count (1).
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            locale: const Locale('en'),
            home: Scaffold(
              body: ChatMessageBubble(
                msg: msg,
                isMe: true,
                isPlayingVoice: false,
                onShowActions: () {},
                onShowSeenBy: () {},
                onToggleReaction: (_) {},
                onToggleVoicePlay: () {},
                onReply: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LmtAvatar), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Receiver view (isMe: false) still sees sender avatar, but NOT Seen count.
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            locale: const Locale('en'),
            home: Scaffold(
              body: ChatMessageBubble(
                msg: msg,
                isMe: false,
                isPlayingVoice: false,
                onShowActions: () {},
                onShowSeenBy: () {},
                onToggleReaction: (_) {},
                onToggleVoicePlay: () {},
                onReply: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LmtAvatar), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
    });
  });

  group('Targeted Notifications, Tones & Delete/Clean All', () {
    test('chat, posts, files, events exclude actor and reactions/likes/comments target owner with custom tones', () async {
      final cubit = _FullTestCubit();

      // 1. Admin sends chat message -> only _editor sees it with chatMessage tone, Admin sees 0.
      await cubit.sendChatMessage(
        groupId: 'grp_test',
        type: MessageType.text,
        content: 'Rehearsal at 6pm',
      );
      expect(cubit.state.visibleNotifications, isEmpty);
      expect(cubit.state.notifications.single.tone, LmtNotificationTone.chatMessage.name);

      // Switch to _editor -> sees chat notification and reacts with ❤️.
      cubit.switchActor(_editor);
      expect(cubit.state.visibleNotifications, hasLength(1));

      final msgId = cubit.state.chatMessages.single.id;
      await cubit.toggleMessageReaction(messageId: msgId, emoji: '❤️');

      // _editor must NOT see notification for their own reaction.
      expect(cubit.state.visibleNotifications.where((n) => n.tone == LmtNotificationTone.messageReacts.name), isEmpty);

      // Admin sees ONLY the message reaction notification (including reactor name & emoji).
      cubit.switchActor(_admin);
      final reactNotifs = cubit.state.visibleNotifications
          .where((n) => n.tone == LmtNotificationTone.messageReacts.name)
          .toList();
      expect(reactNotifs, hasLength(1));
      expect(reactNotifs.single.description, contains(_editor.name));
      expect(reactNotifs.single.description, contains('❤️'));

      // 2. Admin creates a post -> excluded for Admin, visible to _editor and _member.
      await cubit.createPost(
        type: PostCategoryType.simple,
        content: 'Important announcement',
      );
      expect(
        cubit.state.visibleNotifications.where((n) => n.description == 'Important announcement'),
        isEmpty,
      );

      // 3. _editor likes and comments on Admin's post -> Admin gets postInteractions notifications; _member does NOT.
      final postId = cubit.state.posts.single.id;
      cubit.switchActor(_editor);
      await cubit.toggleLikePost(postId);
      await cubit.addPostComment(postId: postId, content: 'Great!');
      expect(
        cubit.state.visibleNotifications.where((n) => n.tone == LmtNotificationTone.postInteractions.name),
        isEmpty,
      );

      cubit.switchActor(_member);
      expect(
        cubit.state.visibleNotifications.where((n) => n.tone == LmtNotificationTone.postInteractions.name),
        isEmpty,
      );

      cubit.switchActor(_admin);
      final postInteractionNotifs = cubit.state.visibleNotifications
          .where((n) => n.tone == LmtNotificationTone.postInteractions.name)
          .toList();
      expect(postInteractionNotifs, hasLength(2));

      // 4. Shared file & calendar event creation exclude actor.
      await cubit.addSharedFile(
        title: 'Script v1',
        description: 'PDF script',
        category: SharedFileType.pdf,
        imagePath: AppAssets.reviewIcon,
        fileExtension: 'PDF',
        fileSize: '1 MB',
      );
      await cubit.addCalendarEvent(
        title: 'Meeting',
        description: 'Weekly meeting',
        eventDateTime: DateTime.now().add(const Duration(days: 3)),
      );
      expect(
        cubit.state.visibleNotifications.where((n) => n.category == NotificationCategory.files),
        isEmpty,
      );
      expect(
        cubit.state.visibleNotifications.where((n) => n.category == NotificationCategory.calendar),
        isEmpty,
      );

      // 5. Delete single notification & Clean All for current user without wiping other members' notifications.
      final firstNotifId = cubit.state.visibleNotifications.first.id;
      await cubit.deleteNotification(firstNotifId);
      expect(
        cubit.state.visibleNotifications.any((n) => n.id == firstNotifId),
        isFalse,
      );

      await cubit.clearAllNotifications();
      expect(cubit.state.visibleNotifications, isEmpty);

      // _editor still keeps their unread post/file/event notifications.
      cubit.switchActor(_editor);
      expect(cubit.state.visibleNotifications, isNotEmpty);

      await cubit.close();
    });
  });

  group('Strict Role Permissions (Admin / Editor / Member)', () {
    test('enforces Admin-only user creation and deletion across all 5 resource types', () async {
      final cubit = _FullTestCubit();

      // Admin seeds one of each resource.
      await cubit.createPost(type: PostCategoryType.simple, content: 'Post 1');
      await cubit.addSharedFile(
        title: 'Doc 1',
        description: 'Desc 1',
        category: SharedFileType.paperwork,
        imagePath: AppAssets.postIcon,
        fileExtension: 'DOCX',
        fileSize: '500 KB',
      );
      await cubit.addCalendarEvent(
        title: 'Event 1',
        description: 'Event desc',
        eventDateTime: DateTime.now().add(const Duration(days: 5)),
      );

      final postId = cubit.state.posts.single.id;
      final fileId = cubit.state.sharedFiles.single.id;
      final eventId = cubit.state.calendarEvents.single.id;

      // ---- MEMBER ROLE: can create new posts & interact, no structural edits/deletes ----
      cubit.switchActor(_member);
      expect(UserRole.member.canCreatePosts, isTrue);
      await cubit.createPost(type: PostCategoryType.simple, content: 'Member post');
      expect(cubit.state.posts, hasLength(2));
      expect(cubit.state.posts.first.creatorId, _member.id);
      await cubit.editPost(postId: postId, content: 'Member hacked');
      expect(
        cubit.state.posts.firstWhere((p) => p.id == postId).content,
        'Post 1',
      );
      await cubit.createChatGroup(
        name: 'Member group',
        description: '',
        imagePath: AppAssets.actIcon,
        memberIds: [_member.id],
      );
      expect(cubit.state.chatGroups, hasLength(1));
      await cubit.addSharedFile(
        title: 'Member file',
        description: '',
        category: SharedFileType.paperwork,
        imagePath: AppAssets.postIcon,
        fileExtension: 'PDF',
        fileSize: '1 MB',
      );
      expect(cubit.state.sharedFiles, hasLength(1));
      await cubit.addCalendarEvent(
        title: 'Member event',
        description: '',
        eventDateTime: DateTime.now().add(const Duration(days: 6)),
      );
      expect(cubit.state.calendarEvents, hasLength(1));
      final memAddErr = await cubit.addMember(
        name: 'X',
        username: 'userx',
        password: 'password123',
        role: UserRole.member,
        departments: const ['ديكور'],
        committees: const ['اللجنة الفنية'],
        groups: const [],
      );
      expect(memAddErr, isNotNull);
      expect(cubit.state.members, hasLength(3));

      // Member interactions work (like & comment).
      await cubit.toggleLikePost(postId);
      await cubit.addPostComment(postId: postId, content: 'Nice!');
      final interactedPost =
          cubit.state.posts.firstWhere((p) => p.id == postId);
      expect(interactedPost.likedByIds, contains(_member.id));
      expect(interactedPost.comments, hasLength(1));

      // ---- EDITOR ROLE: create/edit event/file/group/post, NO user creation, NO deletions ----
      cubit.switchActor(_editor);
      final editorAddUserErr = await cubit.addMember(
        name: 'Blocked User',
        username: 'blocked_user',
        password: 'password123',
        role: UserRole.member,
        departments: const ['ديكور'],
        committees: const ['اللجنة الفنية'],
        groups: const [],
      );
      expect(editorAddUserErr, isNotNull);
      expect(cubit.state.members, hasLength(3));

      // Editor CAN create & edit Group, Event, File, Post.
      await cubit.createChatGroup(
        name: 'Editor Group',
        description: 'Created by editor',
        imagePath: AppAssets.actIcon,
        memberIds: [_admin.id, _editor.id],
      );
      expect(cubit.state.chatGroups, hasLength(2));
      final editorGroupId = cubit.state.chatGroups.first.id;

      await cubit.editPost(postId: postId, content: 'Post 1 Edited');
      expect(
        cubit.state.posts.firstWhere((p) => p.id == postId).content,
        'Post 1 Edited',
      );

      await cubit.updateSharedFile(
        fileId: fileId,
        title: 'Doc 1 Edited',
        description: 'Updated desc',
      );
      expect(cubit.state.sharedFiles.single.title, 'Doc 1 Edited');

      await cubit.addCalendarEvent(
        title: 'Editor Event',
        description: 'Created by editor',
        eventDateTime: DateTime.now().add(const Duration(days: 7)),
      );
      expect(cubit.state.calendarEvents, hasLength(2));

      // Editor CANNOT delete ANY of the 5 entities (user, post, group, event, file).
      await cubit.deleteMember(_member.id);
      await cubit.deletePost(postId);
      await cubit.deleteChatGroup(editorGroupId);
      await cubit.deleteCalendarEvent(eventId);
      await cubit.deleteSharedFile(fileId);

      expect(cubit.state.members, hasLength(3));
      expect(cubit.state.posts, hasLength(2));
      expect(cubit.state.chatGroups, hasLength(2));
      expect(cubit.state.calendarEvents, hasLength(2));
      expect(cubit.state.sharedFiles, hasLength(1));

      // ---- ADMIN ROLE: can delete ALL 5 entities ----
      final memberPostId =
          cubit.state.posts.firstWhere((p) => p.creatorId == _member.id).id;
      cubit.switchActor(_admin);
      await cubit.deleteMember(_member.id);
      await cubit.deletePost(postId);
      await cubit.deletePost(memberPostId);
      await cubit.deleteChatGroup(editorGroupId);
      await cubit.deleteCalendarEvent(eventId);
      await cubit.deleteSharedFile(fileId);

      expect(cubit.state.members, hasLength(2));
      expect(cubit.state.posts, isEmpty);
      expect(cubit.state.chatGroups, hasLength(1));
      expect(cubit.state.calendarEvents, hasLength(1));
      expect(cubit.state.sharedFiles, isEmpty);

      await cubit.close();
    });
  });

  group('Calendar Reminder Permissions (Admin & Editor only)', () {
    test('Admin and Editor can toggle/adjust event reminders while Member is blocked', () async {
      final cubit = _FullTestCubit();
      await cubit.addCalendarEvent(
        title: 'Team Rehearsal',
        description: 'Stage prep',
        eventDateTime: DateTime.now().add(const Duration(days: 3)),
        reminderDateTime: DateTime.now().add(const Duration(days: 2)),
      );
      final eventId = cubit.state.calendarEvents.single.id;
      final originalReminderTime =
          cubit.state.calendarEvents.single.reminderDateTime!;
      expect(cubit.state.calendarEvents.single.isReminderActive, isTrue);

      // Member CANNOT toggle off or customize reminder time.
      cubit.switchActor(_member);
      await cubit.toggleEventReminder(eventId);
      expect(cubit.state.calendarEvents.single.isReminderActive, isTrue);
      final memberAttemptTime = DateTime.now().add(const Duration(hours: 1));
      await cubit.toggleEventReminder(
        eventId,
        customReminderTime: memberAttemptTime,
      );
      expect(
        cubit.state.calendarEvents.single.reminderDateTime,
        originalReminderTime,
      );

      // Editor CAN toggle and customize reminder time.
      cubit.switchActor(_editor);
      await cubit.toggleEventReminder(eventId);
      expect(cubit.state.calendarEvents.single.isReminderActive, isFalse);

      final customTime = DateTime.now().add(const Duration(days: 1));
      await cubit.toggleEventReminder(eventId, customReminderTime: customTime);
      expect(cubit.state.calendarEvents.single.isReminderActive, isTrue);
      expect(cubit.state.calendarEvents.single.reminderDateTime, customTime);

      // Admin CAN toggle reminder off.
      cubit.switchActor(_admin);
      await cubit.toggleEventReminder(eventId);
      expect(cubit.state.calendarEvents.single.isReminderActive, isFalse);

      await cubit.close();
    });
  });

  group('Multi-Admin Groups, Exit Leadership Transfer & Unread Counts', () {
    const editor2 = MemberModel(
      id: 'LMT-2026-004',
      username: 'editor2',
      password: 'password123',
      name: 'Other Editor',
      role: UserRole.editor,
      groups: ['جروب عام'],
      avatarPath: AppAssets.accountIcon,
    );
    const member2 = MemberModel(
      id: 'LMT-2026-005',
      username: 'member2',
      password: 'password123',
      name: 'Second Member',
      role: UserRole.member,
      groups: ['جروب عام'],
      avatarPath: AppAssets.accountIcon,
    );

    test('supports multiple group admins, step-down transfer, strict permissions, and scoped unread tracking', () async {
      final cubit = _FullTestCubit();
      cubit.emit(
        cubit.state.copyWith(
          members: [_admin, _editor, _member, editor2, member2],
        ),
      );

      // Creator (_editor) creates a new group with [_editor, _member, member2].
      cubit.switchActor(_editor);
      await cubit.createChatGroup(
        name: 'Team Choir',
        description: 'Initial desc',
        imagePath: AppAssets.actIcon,
        memberIds: [_editor.id, _member.id, member2.id],
      );
      final gid = cubit.state.chatGroups.firstWhere((g) => g.name == 'Team Choir').id;

      // Another non-group-admin Editor (editor2) CANNOT update this group.
      cubit.switchActor(editor2);
      await cubit.updateChatGroup(
        cubit.state.chatGroups
            .firstWhere((g) => g.id == gid)
            .copyWith(name: 'Unauthorized Edit'),
      );
      expect(
        cubit.state.chatGroups.firstWhere((g) => g.id == gid).name,
        'Team Choir',
      );

      // Global App Admin (_admin) CAN edit any group even without being creator.
      cubit.switchActor(_admin);
      await cubit.updateChatGroup(
        cubit.state.chatGroups
            .firstWhere((g) => g.id == gid)
            .copyWith(description: 'App Admin updated'),
      );
      expect(
        cubit.state.chatGroups.firstWhere((g) => g.id == gid).description,
        'App Admin updated',
      );

      // Regular _member CANNOT edit before promotion.
      cubit.switchActor(_member);
      await cubit.updateChatGroup(
        cubit.state.chatGroups
            .firstWhere((g) => g.id == gid)
            .copyWith(name: 'Member Hack'),
      );
      expect(
        cubit.state.chatGroups.firstWhere((g) => g.id == gid).name,
        'Team Choir',
      );

      // Creator promotes _member as Co-Admin ("معي") -> BOTH are group admins.
      cubit.switchActor(_editor);
      await cubit.setGroupMemberAdmin(
        groupId: gid,
        memberId: _member.id,
        isAdmin: true,
      );
      var group = cubit.state.chatGroups.firstWhere((g) => g.id == gid);
      expect(group.effectiveAdminIds, containsAll([_editor.id, _member.id]));

      // Promoted _member CAN now rename, change image, and add editor2!
      cubit.switchActor(_member);
      await cubit.updateChatGroup(
        group.copyWith(
          name: 'Choir Updated',
          imagePath: AppAssets.prayIcon,
          memberIds: [...group.memberIds, editor2.id],
        ),
      );
      group = cubit.state.chatGroups.firstWhere((g) => g.id == gid);
      expect(group.name, 'Choir Updated');
      expect(group.imagePath, AppAssets.prayIcon);
      expect(group.memberIds, contains(editor2.id));

      // _editor transfers full group ownership to _member and steps down ("بدالي").
      cubit.switchActor(_editor);
      await cubit.transferGroupOwnership(
        groupId: gid,
        newOwnerId: _member.id,
        stepDownSelf: true,
      );
      group = cubit.state.chatGroups.firstWhere((g) => g.id == gid);
      expect(group.adminId, _member.id);
      expect(group.isGroupAdminMember(_editor.id), isFalse);
      expect(group.canUserEditGroup(_editor), isFalse);
      expect(group.canUserEditGroup(_member), isTrue);

      // Scoped seen tracking keeps unread badge & stop anchor accurate.
      cubit.switchActor(_member);
      await cubit.sendChatMessage(groupId: gid, type: MessageType.text, content: 'M1');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await cubit.sendChatMessage(groupId: gid, type: MessageType.text, content: 'M2');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await cubit.sendChatMessage(groupId: gid, type: MessageType.text, content: 'M3');

      final msgs = cubit.state.messagesForGroup(gid);
      cubit.switchActor(_editor);
      expect(cubit.state.unreadMessagesCountForGroup(gid), 3);
      expect(cubit.state.firstUnreadMessageIdForGroup(gid), msgs.first.id);

      await cubit.markGroupMessagesSeen(gid, onlyMessageIds: {msgs[0].id});
      expect(cubit.state.unreadMessagesCountForGroup(gid), 2);
      expect(cubit.state.firstUnreadMessageIdForGroup(gid), msgs[1].id);

      await cubit.close();
    });

    test('leaveChatGroup transfers creator role prioritizing Co-Admin first, then earliest added member', () async {
      final cubit = _FullTestCubit();
      cubit.emit(
        cubit.state.copyWith(
          members: [_admin, _editor, _member, member2],
        ),
      );

      // Case 1: Co-Admin (member2) takes priority over earliest regular member (_member).
      cubit.switchActor(_editor);
      await cubit.createChatGroup(
        name: 'Priority Admin Test',
        description: 'd',
        imagePath: AppAssets.actIcon,
        memberIds: [_editor.id, _member.id, member2.id],
        groupAdminIds: [_editor.id, member2.id],
      );
      final gid1 = cubit.state.chatGroups
          .firstWhere((g) => g.name == 'Priority Admin Test')
          .id;

      await cubit.leaveChatGroup(gid1);
      final afterLeave1 = cubit.state.chatGroups.firstWhere((g) => g.id == gid1);
      expect(afterLeave1.memberIds, [_member.id, member2.id]);
      expect(afterLeave1.adminId, member2.id);
      expect(afterLeave1.adminName, member2.name);
      expect(afterLeave1.isGroupAdminMember(member2.id), isTrue);

      // Case 2: No other Co-Admin -> transfers to earliest added remaining member (_member).
      cubit.switchActor(_editor);
      await cubit.createChatGroup(
        name: 'Earliest Member Test',
        description: 'd',
        imagePath: AppAssets.actIcon,
        memberIds: [_editor.id, _member.id, member2.id],
      );
      final gid2 = cubit.state.chatGroups
          .firstWhere((g) => g.name == 'Earliest Member Test')
          .id;

      await cubit.leaveChatGroup(gid2);
      final afterLeave2 = cubit.state.chatGroups.firstWhere((g) => g.id == gid2);
      expect(afterLeave2.memberIds, [_member.id, member2.id]);
      expect(afterLeave2.adminId, _member.id);
      expect(afterLeave2.adminName, _member.name);
      expect(afterLeave2.isGroupAdminMember(_member.id), isTrue);

      await cubit.close();
    });
  });
}
