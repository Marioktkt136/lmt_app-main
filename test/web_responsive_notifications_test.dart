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
import 'package:lmt/core/utils/device_file_helper.dart';
import 'package:lmt/features/calendar/cubit/calendar_cubit.dart';
import 'package:lmt/features/calendar/views/calendar_screen.dart';
import 'package:lmt/features/chatting_room/cubit/chat_cubit.dart';
import 'package:lmt/features/chatting_room/views/chatting_room.dart';
import 'package:lmt/features/layout/cubit/layout_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StreamableRepo implements LmtRepository {
  final StreamController<List<AppNotificationModel>> notifController =
      StreamController<List<AppNotificationModel>>.broadcast();

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
      notifController.stream;

  Future<void> dispose() => notifController.close();
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
}
