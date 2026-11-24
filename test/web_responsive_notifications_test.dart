import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmt/core/models/lmt_models.dart';
import 'package:lmt/core/repositories/lmt_repository.dart';
import 'package:lmt/core/services/local_notification_service.dart';
import 'package:lmt/core/utils/app_assets.dart';
import 'package:lmt/core/utils/cloud_media_storage.dart';
import 'package:lmt/core/utils/device_file_helper.dart';
import 'package:lmt/features/calendar/cubit/calendar_cubit.dart';
import 'package:lmt/features/calendar/views/calendar_screen.dart';
import 'package:lmt/features/chatting_room/cubit/chat_cubit.dart';
import 'package:lmt/features/chatting_room/views/chatting_room.dart';
import 'package:lmt/features/chatting_room/widgets/chat_group_tile.dart';
import 'package:lmt/features/chatting_room/widgets/conversation_header_bar.dart';
import 'package:lmt/features/chatting_room/widgets/group_conversation_room.dart';
import 'package:lmt/features/layout/cubit/layout_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StreamableRepo implements LmtRepository {
  final StreamController<List<AppNotificationModel>> notifController =
      StreamController<List<AppNotificationModel>>.broadcast();
  final StreamController<LmtRepositorySnapshot> liveSnapshotController =
      StreamController<LmtRepositorySnapshot>.broadcast();

  @override
  Future<LmtRepositorySnapshot> loadSnapshot() async {
    return LmtRepositorySnapshot(
      biometricEnabled: true,
      sloganOfYear: '#تغيروا_2026',
      verseOfYear: 'verse',
      currentUser: _admin,
      members: const [_admin, _editor],
      chatGroups: [_group],
      chatMessages: [
        ChatMessageModel(
          id: 'msg_1',
          groupId: _group.id,
          senderId: _editor.id,
          senderName: _editor.name,
          senderRole: _editor.role,
          type: MessageType.text,
          content: 'أهلاً بكم على نسخة الويب الجديدة 🌐',
          sentAt: DateTime(2026, 11, 23, 12, 0),
          seenBy: const [],
        ),
      ],
      posts: const [],
      sharedFiles: const [],
      calendarEvents: [
        CalendarEventModel(
          id: 'evt_1',
          title: 'بروفة الفريق الكبرى',
          description: 'التدريب الأسبوعي في القاعة',
          eventDateTime: DateTime.now().add(const Duration(days: 3)),
          reminderDateTime: DateTime.now().add(const Duration(days: 2)),
          createdBy: _admin.name,
        ),
        CalendarEventModel(
          id: 'evt_2',
          title: 'اجتماع المتابعة',
          description: 'مناقشة خطة العرض القادم',
          eventDateTime: DateTime.now().add(const Duration(days: 5)),
          reminderDateTime: DateTime.now().add(const Duration(days: 4)),
          createdBy: _admin.name,
        ),
      ],
      notifications: const [],
    );
  }

  final List<Map<String, dynamic>> persistedSnapshots = [];

  @override
  Future<void> persistSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {
    persistedSnapshots.add(Map<String, dynamic>.from(stateJson));
  }

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
      notifController.stream;

  @override
  Stream<LmtRepositorySnapshot> watchLiveSnapshots() =>
      liveSnapshotController.stream;

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
  }) =>
      persistSnapshot(stateJson: stateJson, currentUserId: currentUserId);

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

  Future<void> dispose() async {
    await notifController.close();
    await liveSnapshotController.close();
  }
}

const _admin = MemberModel(
  id: 'LMT-2026-001',
  username: 'admin',
  password: 'password123',
  name: 'Mario Naiem',
  role: UserRole.admin,
  groups: ['grp_1'],
  avatarPath: AppAssets.accountIcon,
);

const _editor = MemberModel(
  id: 'LMT-2026-002',
  username: 'mina',
  password: 'password123',
  name: 'Mina Adel',
  role: UserRole.editor,
  groups: ['grp_1'],
  avatarPath: AppAssets.accountIcon,
);

final _group = ChatGroupModel(
  id: 'grp_1',
  name: 'فريق الرسالة الاخيرة',
  description: 'جروب عام للفريق',
  imagePath: AppAssets.actIcon,
  memberIds: const ['LMT-2026-001', 'LMT-2026-002'],
  adminId: 'LMT-2026-001',
  adminName: 'Mario Naiem',
  isPinned: true,
  createdAt: DateTime(2026, 11, 1),
);

class _DesktopFakeCubit extends LmtBaseCubit
    with ChatCubitMixin, CalendarCubitMixin, LayoutCubitMixin
    implements LmtCubit {
  _DesktopFakeCubit() : super(repository: _StreamableRepo()) {
    emit(
      state.copyWith(
        isInitialized: true,
        currentUser: _admin,
        members: const [_admin, _editor],
        chatGroups: [_group],
        chatMessages: [
          ChatMessageModel(
            id: 'msg_1',
            groupId: _group.id,
            senderId: _editor.id,
            senderName: _editor.name,
            senderRole: _editor.role,
            type: MessageType.text,
            content: 'أهلاً بكم على نسخة الويب 🌐',
            sentAt: DateTime(2026, 11, 23, 12, 0),
            seenBy: const [],
          ),
        ],
        calendarEvents: [
          CalendarEventModel(
            id: 'evt_1',
            title: 'بروفة الفريق 1',
            description: 'وصف البروفة الأولى',
            eventDateTime: DateTime.now(),
            reminderDateTime: DateTime.now().add(const Duration(hours: 2)),
            createdBy: _admin.name,
          ),
          CalendarEventModel(
            id: 'evt_2',
            title: 'بروفة الفريق 2',
            description: 'وصف البروفة الثانية',
            eventDateTime: DateTime.now(),
            reminderDateTime: DateTime.now().add(const Duration(hours: 3)),
            createdBy: _admin.name,
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Web Notifications, Audio Assets & Remote Stream Sync', () {
    test('all 5 LmtNotificationTone webAssetPath files exist on disk', () {
      for (final tone in LmtNotificationTone.values) {
        expect(File(tone.webAssetPath).existsSync(), isTrue,
            reason: 'Missing bundled MP3 tone asset: ${tone.webAssetPath}');
      }
    });

    test('showInstantNotification emits foregroundStream with custom tone', () async {
      final events = <ForegroundNotificationEvent>[];
      final sub = LocalNotificationService.foregroundStream.listen(events.add);

      await LocalNotificationService.showInstantNotification(
        idKey: 'web_test_1',
        title: 'رسالة جديدة',
        body: 'مينا كتب رسالة في الجروب',
        tone: LmtNotificationTone.chatMessage,
        payloadData: const {'tab': 1, 'groupId': 'grp_1'},
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.tone, LmtNotificationTone.chatMessage);
      expect(events.first.payload, contains('"groupId":"grp_1"'));
      await sub.cancel();
    });

    test('LmtCubit remote watchNotifications dispatches new targeted Web alert and ignores excluded sender', () async {
      final repo = _StreamableRepo();
      final cubit = LmtCubit(repository: repo);
      while (!cubit.state.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      final events = <ForegroundNotificationEvent>[];
      final sub = LocalNotificationService.foregroundStream.listen(events.add);

      // Emit targeted remote reaction notification + self-excluded chat message
      final targeted = AppNotificationModel(
        id: 'notif_remote_react',
        title: 'تفاعل جديد ❤️',
        description: 'Mina Adel تفاعل بـ ❤️ على رسالتك',
        dateTime: DateTime.now(),
        category: NotificationCategory.chat,
        tone: LmtNotificationTone.messageReacts.name,
        targetMemberIds: const ['LMT-2026-001'],
        targetTabIndex: 1,
        targetGroupId: 'grp_1',
      );
      final excluded = AppNotificationModel(
        id: 'notif_excluded_self',
        title: 'رسالة منك',
        description: 'لا تظهر لك',
        dateTime: DateTime.now(),
        category: NotificationCategory.chat,
        tone: LmtNotificationTone.chatMessage.name,
        excludedMemberIds: const ['LMT-2026-001'],
      );
      repo.notifController.add([targeted, excluded]);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(events, hasLength(1));
      expect(events.first.idKey, 'notif_remote_react');
      expect(events.first.tone, LmtNotificationTone.messageReacts);

      await sub.cancel();
      await cubit.close();
      await repo.dispose();
    });

    test('DeviceFileHelper resolves data URI, https URL, and bundled asset cleanly', () {
      final base64Png = base64Encode(const [137, 80, 78, 71, 13, 10, 26, 10]);
      final memProvider =
          DeviceFileHelper.imageProviderFor('data:image/png;base64,$base64Png');
      final netProvider =
          DeviceFileHelper.imageProviderFor('https://example.com/photo.png');
      final assetProvider =
          DeviceFileHelper.imageProviderFor(AppAssets.accountIcon);

      expect(memProvider, isA<MemoryImage>());
      expect(netProvider, isA<NetworkImage>());
      expect(assetProvider, isA<AssetImage>());
    });
  });

  group('Desktop/Web Adaptive Layout (1280x800)', () {
    testWidgets('ChattingRoom renders Master-Detail Split View side-by-side on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cubit = _DesktopFakeCubit();
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: Size(1280 / 1.16, 800 / 1.0),
          minTextAdapt: true,
          builder: (_, _) => BlocProvider<LmtCubit>.value(
            value: cubit,
            child: const MaterialApp(
              locale: Locale('ar'),
              home: Scaffold(body: ChattingRoom()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both the Groups List pane AND the active Group Conversation message show side-by-side.
      expect(find.text('فريق الرسالة الاخيرة'), findsWidgets);
      expect(find.text('أهلاً بكم على نسخة الويب 🌐'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('CalendarScreen renders 2-column event grid on wide screens without overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cubit = _DesktopFakeCubit();
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: Size(1280 / 1.16, 800 / 1.0),
          minTextAdapt: true,
          builder: (_, _) => BlocProvider<LmtCubit>.value(
            value: cubit,
            child: const MaterialApp(
              locale: Locale('ar'),
              home: Scaffold(body: CalendarScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('بروفة الفريق 1'), findsOneWidget);
      expect(find.text('بروفة الفريق 2'), findsOneWidget);
      await cubit.close();
    });
  });

  group('Real-Time Auto-Sync & Cloud Media', () {
    test(
        'LmtCubit live snapshot stream auto-syncs chat, posts, files, calendar, avatars & notifications',
        () async {
      final repo = _StreamableRepo();
      final cubit = LmtCubit(repository: repo);
      while (!cubit.state.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      final events = <ForegroundNotificationEvent>[];
      final sub = LocalNotificationService.foregroundStream.listen(events.add);

      const newAvatarUri =
          'cloud://blob/blob_avatar_mina?name=mina.png&mime=image%2Fpng&chunks=1';
      final updatedEditor = _editor.copyWith(avatarPath: newAvatarUri);
      final updatedPost = PostModel(
        id: 'post_live_1',
        creatorId: _admin.id,
        creatorName: _admin.name,
        publishTime: DateTime(2026, 11, 23, 14, 0),
        type: PostCategoryType.simple,
        content: 'تحديث بوست جديد لايف',
        likedByIds: [_editor.id],
        comments: [
          PostCommentModel(
            id: 'c_live_1',
            authorId: _editor.id,
            authorName: _editor.name,
            authorAvatar: newAvatarUri,
            content: 'تعليق لحظي',
            createdAt: DateTime(2026, 11, 23, 14, 5),
          ),
        ],
      );
      final updatedFile = SharedFileModel(
        id: 'file_live_1',
        title: 'ملف الفريق الحقيقي',
        description: 'مستند مرفوع على السحابة',
        category: SharedFileType.pdf,
        fileExtension: 'PDF',
        fileSize: '120 KB',
        localFilePath:
            'cloud://blob/blob_doc_1?name=team_plan.pdf&mime=application%2Fpdf&chunks=1',
        uploadedBy: _editor.name,
        uploadedAt: DateTime(2026, 11, 23, 14, 10),
      );
      final updatedEvent = CalendarEventModel(
        id: 'evt_live_1',
        title: 'اجتماع متزامن تلقائياً',
        description: 'تحديث لحظي للتقويم',
        eventDateTime: DateTime.now().add(const Duration(days: 2)),
        reminderDateTime: DateTime.now().add(const Duration(days: 1)),
        createdBy: _editor.name,
      );
      final liveMessage = ChatMessageModel(
        id: 'msg_live_2',
        groupId: _group.id,
        senderId: _editor.id,
        senderName: _editor.name,
        senderAvatar: newAvatarUri,
        senderRole: _editor.role,
        type: MessageType.text,
        content: 'رسالة متزامنة تلقائياً بدون زرار Sync',
        sentAt: DateTime(2026, 11, 23, 14, 15),
        seenBy: const [],
      );
      final liveNotification = AppNotificationModel(
        id: 'notif_live_file',
        title: 'ملف جديد متزامن 📄',
        description: 'Mina Adel رفع ملف الفريق الحقيقي',
        dateTime: DateTime.now(),
        category: NotificationCategory.files,
        tone: LmtNotificationTone.normal.name,
        excludedMemberIds: const ['LMT-2026-002'],
      );

      repo.liveSnapshotController.add(
        LmtRepositorySnapshot(
          biometricEnabled: true,
          sloganOfYear: '#تغيروا_2026',
          verseOfYear: 'verse',
          currentUser: _admin,
          members: [_admin, updatedEditor],
          chatGroups: [_group],
          chatMessages: [liveMessage],
          posts: [updatedPost],
          sharedFiles: [updatedFile],
          calendarEvents: [updatedEvent],
          notifications: [liveNotification],
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.lastSyncedAt, isNotNull);
      expect(
        cubit.state.chatMessages.any((m) => m.id == 'msg_live_2'),
        isTrue,
      );
      expect(cubit.state.posts.single.likedByIds, contains(_editor.id));
      expect(cubit.state.posts.single.comments.single.content, 'تعليق لحظي');
      expect(
        cubit.state.sharedFiles.single.localFilePath,
        startsWith('cloud://blob/'),
      );
      expect(
        cubit.state.calendarEvents.single.title,
        'اجتماع متزامن تلقائياً',
      );
      expect(
        cubit.state.members.firstWhere((m) => m.id == _editor.id).avatarPath,
        newAvatarUri,
      );
      expect(
        events.any((e) => e.idKey == 'notif_live_file'),
        isTrue,
      );

      await sub.cancel();
      await cubit.close();
      await repo.dispose();
    });

    test('updateProfileAvatar dispatches avatar-change notification for other members',
        () async {
      final repo = _StreamableRepo();
      final cubit = LmtCubit(repository: repo);
      while (!cubit.state.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      const uploadedAvatarUri =
          'cloud://blob/blob_admin_1?name=mario.png&mime=image%2Fpng&chunks=1';
      await cubit.updateProfileAvatar(uploadedAvatarUri);

      expect(cubit.state.currentUser.avatarPath, uploadedAvatarUri);
      expect(
        cubit.state.notifications.any(
          (n) =>
              n.title.contains('الصورة الشخصية') &&
              n.excludedMemberIds.contains(_admin.id),
        ),
        isTrue,
      );

      await cubit.close();
      await repo.dispose();
    });

    test('CloudMediaStorage and DeviceFileHelper handle cloud://blob URIs cleanly',
        () {
      const cloudPdf =
          'cloud://blob/blob_pdf_1?name=rehearsal_script.pdf&mime=application%2Fpdf&chunks=2';
      const cloudImage =
          'cloud://blob/blob_img_1?name=stage_photo.png&mime=image%2Fpng&chunks=1';
      const cloudVideo =
          'cloud://blob/blob_vid_1?name=promo.mp4&mime=video%2Fmp4&chunks=3';

      expect(CloudMediaStorage.isCloudUri(cloudPdf), isTrue);
      expect(
        CloudMediaStorage.displayFileName(cloudPdf),
        'rehearsal_script.pdf',
      );
      expect(
        DeviceFileHelper.displayFileName(cloudPdf),
        'rehearsal_script.pdf',
      );
      expect(DeviceFileHelper.isVideoPath(cloudVideo), isTrue);
      expect(
        DeviceFileHelper.imageProviderFor(cloudImage),
        isA<CloudBlobImageProvider>(),
      );
    });

    test('alertUnseenNotificationsForCurrentUser persists per-user alerts and ignores stale history',
        () async {
      final repo = _StreamableRepo();
      final cubit = LmtCubit(repository: repo);
      while (!cubit.state.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      final events = <ForegroundNotificationEvent>[];
      final sub = LocalNotificationService.foregroundStream.listen(events.add);

      final freshUnread = AppNotificationModel(
        id: 'notif_fresh_1',
        title: 'رسالة جديدة',
        description: 'مينا أرسل رسالة جديدة',
        dateTime: DateTime.now(),
        category: NotificationCategory.chat,
        tone: LmtNotificationTone.chatMessage.name,
      );
      final staleUnread = AppNotificationModel(
        id: 'notif_stale_old',
        title: 'قديم',
        description: 'أكثر من 24 ساعة',
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        category: NotificationCategory.posts,
      );
      final alreadyRead = AppNotificationModel(
        id: 'notif_read_1',
        title: 'مقروء',
        description: 'تمت قراءته',
        dateTime: DateTime.now(),
        category: NotificationCategory.posts,
        isRead: true,
      );

      final firedFirst = cubit.alertUnseenNotificationsForCurrentUser([
        freshUnread,
        staleUnread,
        alreadyRead,
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(firedFirst, isTrue);
      expect(events, hasLength(1));
      expect(events.single.idKey, 'notif_fresh_1');

      // Re-evaluating same list for same user does NOT double-fire.
      final firedSecond = cubit.alertUnseenNotificationsForCurrentUser([
        freshUnread,
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(firedSecond, isFalse);
      expect(events, hasLength(1));

      // Verify Android keep.xml & iOS PWA L.M.T apple-touch-icon exist on disk.
      expect(
        File('android/app/src/main/res/raw/keep.xml').existsSync(),
        isTrue,
      );
      expect(
        File('web/icons/apple-touch-icon.png').existsSync(),
        isTrue,
      );
      expect(
        File('web/index.html').readAsStringSync(),
        contains('apple-touch-icon.png?v=3'),
      );
      expect(UserRole.member.canCreatePosts, isTrue);

      await sub.cancel();
      await cubit.close();
      await repo.dispose();
    });

    test('createPost(poll) preserves poll post and options cleanly across live snapshot emissions', () async {
      final repo = _StreamableRepo();
      final cubit = LmtCubit(repository: repo);
      while (!cubit.state.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      await cubit.createPost(
        type: PostCategoryType.poll,
        content: 'أفضل موعد للبروفة القادمة؟',
        pollOptionsText: const ['الجمعة مساءً', 'السبت عصراً', 'الأحد مساءً'],
      );

      expect(cubit.state.posts, hasLength(1));
      final createdPoll = cubit.state.posts.single;
      expect(createdPoll.type, PostCategoryType.poll);
      expect(createdPoll.pollOptions, hasLength(3));
      expect(
        createdPoll.pollOptions.map((o) => o.text),
        ['الجمعة مساءً', 'السبت عصراً', 'الأحد مساءً'],
      );
      expect(repo.persistedSnapshots, isNotEmpty);
      final persistedPosts =
          repo.persistedSnapshots.last['posts'] as List<dynamic>;
      expect(persistedPosts, hasLength(1));

      // Verify a subsequent synced live snapshot carrying the persisted post preserves it intact.
      repo.liveSnapshotController.add(
        LmtRepositorySnapshot(
          biometricEnabled: true,
          sloganOfYear: cubit.state.sloganOfYear,
          verseOfYear: cubit.state.verseOfYear,
          currentUser: cubit.state.currentUser,
          members: cubit.state.members,
          chatGroups: cubit.state.chatGroups,
          chatMessages: cubit.state.chatMessages,
          posts: cubit.state.posts,
          sharedFiles: cubit.state.sharedFiles,
          calendarEvents: cubit.state.calendarEvents,
          notifications: cubit.state.notifications,
          khelwaDays: cubit.state.khelwaDays,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cubit.state.posts, hasLength(1));
      expect(cubit.state.posts.single.type, PostCategoryType.poll);

      await cubit.close();
      await repo.dispose();
    });

    testWidgets('ChatGroupTile & ConversationHeaderBar hide creator/admin name and render WhatsApp unread badge', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final grp = ChatGroupModel(
        id: 'grp_ui_test',
        name: 'فريق العرض',
        description: 'مجموعة العمل',
        imagePath: AppAssets.actIcon,
        memberIds: const ['LMT-2026-001', 'LMT-2026-002'],
        groupAdminIds: const ['LMT-2026-001'],
        adminId: 'LMT-2026-001',
        adminName: 'SecretCreatorName',
        isPinned: true,
        createdAt: DateTime(2026, 11, 20),
      );
      final lastMsg = ChatMessageModel(
        id: 'msg_ui_1',
        groupId: 'grp_ui_test',
        senderId: 'LMT-2026-002',
        senderName: 'Mina Adel',
        senderRole: UserRole.editor,
        type: MessageType.text,
        content: 'ميعادنا الساعة 7',
        sentAt: DateTime.now(),
        seenBy: const [],
      );
      final cubit = _DesktopFakeCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => BlocProvider<LmtCubit>.value(
            value: cubit,
            child: MaterialApp(
              locale: const Locale('en'),
              home: Scaffold(
                appBar: ConversationHeaderBar(
                  group: grp,
                  state: cubit.state,
                  onBack: () {},
                ),
                body: ChatGroupTile(
                  group: grp,
                  lastMessage: lastMsg,
                  unreadCount: 4,
                  currentUserId: _admin.id,
                  canEditGroups: true,
                  canDeleteGroups: true,
                  onTap: () {},
                  onTogglePin: () {},
                  onEdit: () {},
                  onLeave: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فريق العرض'), findsNWidgets(2));
      expect(find.text('2 members'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      // Admin/Creator name & old verbose metadata row MUST NOT appear anywhere.
      expect(find.textContaining('SecretCreatorName'), findsNothing);
      expect(find.textContaining('Admin:'), findsNothing);
      expect(find.textContaining('مسؤول'), findsNothing);
    });

    testWidgets('GroupConversationRoom stops at first unread banner and shows scroll-to-bottom FAB', (tester) async {
      tester.view.physicalSize = const Size(375, 520);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cubit = _DesktopFakeCubit();
      addTearDown(cubit.close);

      final base = DateTime(2026, 11, 24, 0, 0);
      final manyMessages = <ChatMessageModel>[];
      for (var i = 0; i < 24; i++) {
        final isUnread = i >= 10;
        manyMessages.add(
          ChatMessageModel(
            id: 'm_$i',
            groupId: _group.id,
            senderId: _editor.id,
            senderName: _editor.name,
            senderRole: _editor.role,
            type: MessageType.text,
            content: 'Message number $i for testing scrolling height comfortably',
            sentAt: base.add(Duration(minutes: i)),
            seenBy: isUnread
                ? const []
                : [
                    SeenStatusModel(
                      memberId: _admin.id,
                      memberName: _admin.name,
                      avatarPath: _admin.avatarPath,
                      timestamp: base.add(Duration(minutes: i)),
                    ),
                  ],
          ),
        );
      }

      cubit.emit(cubit.state.copyWith(chatMessages: manyMessages));

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 520),
          minTextAdapt: true,
          builder: (_, _) => BlocProvider<LmtCubit>.value(
            value: cubit,
            child: MaterialApp(
              locale: const Locale('en'),
              home: Scaffold(
                body: GroupConversationRoom(
                  group: _group,
                  onBack: () {},
                  showInlineHeader: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unread stop banner (14 unread messages) is shown cleanly at initial stop.
      expect(find.text('14 unread messages'), findsOneWidget);
      // Since viewport jumped up past the bottom threshold, the floating button is visible.
      expect(
        find.byIcon(Icons.keyboard_double_arrow_down_rounded),
        findsOneWidget,
      );

      // Tapping the floating button scrolls cleanly back down to the bottom and hides it.
      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_down_rounded));
      await tester.pumpAndSettle();
      expect(
        find.byIcon(Icons.keyboard_double_arrow_down_rounded),
        findsNothing,
      );
    });
  });
}
