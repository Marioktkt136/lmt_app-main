import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmt/core/models/lmt_models.dart';
import 'package:lmt/core/repositories/lmt_repository.dart';
import 'package:lmt/core/routes/routes.dart';
import 'package:lmt/core/services/background_sync_bridge.dart';
import 'package:lmt/core/services/shorebird_update_service.dart';
import 'package:lmt/core/utils/app_assets.dart';
import 'package:lmt/core/utils/app_preferences.dart';
import 'package:lmt/features/auth/services/biometric_auth_service.dart';
import 'package:lmt/features/auth/services/biometric_session_lock_controller.dart';
import 'package:lmt/features/auth/widgets/biometric_lock_overlay.dart';
import 'package:lmt/features/chatting_room/cubit/chat_cubit.dart';
import 'package:lmt/features/chatting_room/widgets/chat_group_tile.dart';
import 'package:lmt/features/chatting_room/widgets/chat_message_bubble.dart';
import 'package:lmt/features/chatting_room/widgets/group_conversation_room.dart';
import 'package:lmt/features/layout/cubit/layout_cubit.dart';
import 'package:lmt/features/splash/splash_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class _FakeBiometricAuthService extends BiometricAuthService {
  _FakeBiometricAuthService(this.nextStatus);

  BiometricStatus nextStatus;
  int callCount = 0;

  @override
  Future<BiometricResult> authenticate({
    required String localizedReason,
    String? userId,
    String? username,
  }) async {
    callCount++;
    return BiometricResult(nextStatus);
  }
}

class _TestLmtRepo extends LmtRepository {
  final StreamController<List<AppNotificationModel>> _notifController =
      StreamController<List<AppNotificationModel>>.broadcast();
  final StreamController<LmtRepositorySnapshot> _snapshotController =
      StreamController<LmtRepositorySnapshot>.broadcast();

  static const _admin = MemberModel(
    id: 'LMT-2026-001',
    username: 'admin',
    name: 'Admin User',
    role: UserRole.admin,
    avatarPath: AppAssets.appLogo,
    groups: ['grp_1'],
    departments: ['ديكور'],
    committees: ['اللجنة العامة'],
  );

  static const _memberTwo = MemberModel(
    id: 'LMT-2026-004',
    username: 'nono',
    name: 'Youstina Romany',
    role: UserRole.editor,
    avatarPath: AppAssets.appLogo,
    groups: ['grp_1'],
    departments: ['ديكور'],
    committees: ['اللجنة العامة'],
  );

  static final _group = ChatGroupModel(
    id: 'grp_1',
    name: 'الجروب العام',
    description: 'اختبار',
    memberIds: const ['LMT-2026-001', 'LMT-2026-004'],
    groupAdminIds: const ['LMT-2026-001'],
    adminId: 'LMT-2026-001',
    adminName: 'Admin User',
    createdAt: DateTime(2026, 11, 20),
  );

  void emitLiveSnapshot(LmtRepositorySnapshot snapshot) {
    if (!_snapshotController.isClosed) {
      _snapshotController.add(snapshot);
    }
  }

  @override
  Future<LmtRepositorySnapshot> loadSnapshot() async {
    return LmtRepositorySnapshot(
      biometricEnabled: true,
      sloganOfYear: '#تغيروا_2026',
      verseOfYear: 'verse',
      currentUser: _admin,
      members: const [_admin, _memberTwo],
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
  Stream<List<AppNotificationModel>> watchNotifications() =>
      _notifController.stream;

  @override
  Stream<LmtRepositorySnapshot> watchLiveSnapshots() =>
      _snapshotController.stream;

  void dispose() {
    _notifController.close();
    _snapshotController.close();
  }
}

class _FakeChatSeenCubit extends LmtBaseCubit
    with ChatCubitMixin, LayoutCubitMixin
    implements LmtCubit {
  _FakeChatSeenCubit({required super.repository}) {
    emit(
      state.copyWith(
        isInitialized: true,
        currentUser: _TestLmtRepo._admin,
        members: const [_TestLmtRepo._admin, _TestLmtRepo._memberTwo],
        chatGroups: [_TestLmtRepo._group],
        chatMessages: const [],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bgChannel = MethodChannel('com.example.lmt/background_sync');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    BiometricSessionLockController.instance.resetToLoggedOut();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bgChannel, null);
  });

  group('Persistent Session & Biometric Lock', () {
    test(
      'keeps authenticated user locked on cold open and pause/hidden only when biometrics enabled',
      () async {
        final ctrl = BiometricSessionLockController.instance;

        // Disabled -> stays unlocked across cold open and background/resume.
        ctrl.enterAuthenticatedSession(biometricEnabled: false);
        expect(ctrl.isLocked.value, isFalse);
        ctrl.handleAppLifecycleState(AppLifecycleState.paused);
        expect(ctrl.isLocked.value, isFalse);

        // Enabled -> starts locked on open and requires verification.
        ctrl.enterAuthenticatedSession(biometricEnabled: true);
        expect(ctrl.isLocked.value, isTrue);

        // Failed / cancelled attempt leaves lock intact.
        final cancelAuth = _FakeBiometricAuthService(BiometricStatus.cancelled);
        final cancelRes = await ctrl.attemptUnlock(
          userId: 'LMT-2026-001',
          username: 'admin',
          localizedReason: 'Unlock',
          service: cancelAuth,
        );
        expect(cancelRes, BiometricStatus.cancelled);
        expect(cancelAuth.callCount, 1);
        expect(ctrl.isLocked.value, isTrue);

        // Successful unlock dismisses lock and activates brief cooldown.
        final successAuth = _FakeBiometricAuthService(BiometricStatus.success);
        final okRes = await ctrl.attemptUnlock(
          userId: 'LMT-2026-001',
          username: 'admin',
          localizedReason: 'Unlock',
          service: successAuth,
        );
        expect(okRes, BiometricStatus.success);
        expect(ctrl.isLocked.value, isFalse);

        // Cooldown protects against immediate OS biometric sheet dismiss pause.
        ctrl.handleAppLifecycleState(AppLifecycleState.paused);
        expect(ctrl.isLocked.value, isFalse);

        // Wait past 650ms cooldown -> suppressNextResumeLock bypasses one picker pause.
        await Future<void>.delayed(const Duration(milliseconds: 700));
        ctrl.suppressNextResumeLock();
        ctrl.handleAppLifecycleState(AppLifecycleState.paused);
        expect(ctrl.isLocked.value, isFalse);

        // Inactive (notification shade / alert) does NOT spuriously lock.
        ctrl.handleAppLifecycleState(AppLifecycleState.inactive);
        expect(ctrl.isLocked.value, isFalse);

        // Subsequent real background / screen lock re-engages biometric lock.
        ctrl.handleAppLifecycleState(AppLifecycleState.paused);
        expect(ctrl.isLocked.value, isTrue);

        // Resume requests auto-prompt while locked.
        expect(ctrl.handleAppLifecycleState(AppLifecycleState.resumed), isTrue);

        // Explicit logout clears lock shield completely.
        ctrl.resetToLoggedOut();
        expect(ctrl.isLocked.value, isFalse);
        expect(ctrl.isInAuthenticatedShell, isFalse);
      },
    );

    testWidgets(
      'SplashScreen keeps saved user logged into home and locks only when biometrics enabled',
      (tester) async {
        await AppPreferences.saveLogin(
          username: 'admin',
          userId: 'LMT-2026-001',
        );
        await AppPreferences.setBiometricEnabled(true);

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (_, _) => MaterialApp(
              routes: {
                Routes.home: (_) => const Scaffold(body: Text('HOME_ROUTE')),
                Routes.login: (_) => const Scaffold(body: Text('LOGIN_ROUTE')),
              },
              home: const SplashScreen(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('HOME_ROUTE'), findsOneWidget);
        expect(find.text('LOGIN_ROUTE'), findsNothing);
        expect(BiometricSessionLockController.instance.isLocked.value, isTrue);

        // When biometrics disabled, navigates to HOME_ROUTE unlocked cleanly.
        BiometricSessionLockController.instance.resetToLoggedOut();
        await AppPreferences.setBiometricEnabled(false);

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (_, _) => MaterialApp(
              routes: {
                Routes.home: (_) => const Scaffold(body: Text('HOME_ROUTE')),
                Routes.login: (_) => const Scaffold(body: Text('LOGIN_ROUTE')),
              },
              home: const SplashScreen(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('HOME_ROUTE'), findsOneWidget);
        expect(BiometricSessionLockController.instance.isLocked.value, isFalse);
      },
    );

    testWidgets(
      'BiometricLockOverlay auto-prompts, unlocks cleanly on retry, and uses zero SnackBars',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = _TestLmtRepo();
        final cubit = LmtCubit(repository: repo);
        addTearDown(() async {
          await cubit.close();
          repo.dispose();
        });
        await tester.pump();

        BiometricSessionLockController.instance.enterAuthenticatedSession(
          biometricEnabled: true,
        );
        final fakeBio = _FakeBiometricAuthService(BiometricStatus.cancelled);

        await tester.pumpWidget(
          BlocProvider<LmtCubit>.value(
            value: cubit,
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              minTextAdapt: true,
              builder: (_, _) => MaterialApp(
                locale: const Locale('en'),
                home: Scaffold(
                  body: BiometricLockOverlay(biometricService: fakeBio),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(fakeBio.callCount, 1);
        expect(BiometricSessionLockController.instance.isLocked.value, isTrue);
        expect(find.text('Unlock with Biometrics / Face ID'), findsOneWidget);
        expect(find.text('Sign Out / Switch Account'), findsOneWidget);
        expect(
          find.text('Please verify your Biometrics or Face ID to continue.'),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);

        // Retry tap succeeds and unlocks session cleanly.
        fakeBio.nextStatus = BiometricStatus.success;
        await tester.ensureVisible(find.text('Unlock with Biometrics / Face ID'));
        await tester.tap(find.text('Unlock with Biometrics / Face ID'));
        await tester.pumpAndSettle();
        expect(fakeBio.callCount, 2);
        expect(BiometricSessionLockController.instance.isLocked.value, isFalse);
      },
    );
  });

  group('Background Notifications Deduplication & Hygiene', () {
    test(
      'reconcileBackgroundNotifications marks native lock-screen alerted IDs so Dart never double-alerts',
      () async {
        final repo = _TestLmtRepo();
        final cubit = LmtCubit(repository: repo);
        addTearDown(() async {
          await cubit.close();
          repo.dispose();
        });

        while (!cubit.state.isInitialized) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }

        // Mock native channel returning an ID alerted while phone screen was locked.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(bgChannel, (call) async {
          if (call.method == 'consumeNativeAlertedIds') {
            return <String>['notif_bg_locked_1'];
          }
          return null;
        });

        await cubit.reconcileBackgroundNotifications(userId: 'LMT-2026-001');

        final saved = await AppPreferences.getAlertedNotificationIds(
          'LMT-2026-001',
        );
        expect(saved.contains('notif_bg_locked_1'), isTrue);
        expect(
          cubit.knownNotificationIds.contains('LMT-2026-001::notif_bg_locked_1'),
          isTrue,
        );

        // Already natively-alerted notification does NOT double-alert in Dart.
        final alreadyAlerted = cubit.alertUnseenNotificationsForCurrentUser([
          AppNotificationModel(
            id: 'notif_bg_locked_1',
            title: 'رسالة جديدة',
            description: 'وصلتك وأنت خارج التطبيق',
            dateTime: DateTime.now(),
            category: NotificationCategory.chat,
            tone: 'chatMessage',
          ),
        ]);
        expect(alreadyAlerted, isFalse);

        // Fresh unseen notification alerts once and is then deduplicated.
        final freshNotif = AppNotificationModel(
          id: 'notif_bg_new_2',
          title: 'تذكير بروفة',
          description: 'تبدأ البروفة بعد قليل',
          dateTime: DateTime.now(),
          category: NotificationCategory.calendar,
          tone: 'calendar',
        );
        expect(
          cubit.alertUnseenNotificationsForCurrentUser([freshNotif]),
          isTrue,
        );
        expect(
          cubit.alertUnseenNotificationsForCurrentUser([freshNotif]),
          isFalse,
        );

        // BackgroundSyncBridge consumes launch payloads safely.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(bgChannel, (call) async {
          if (call.method == 'consumeLaunchPayload') {
            return '{"notifId":"notif_bg_locked_1","tab":1}';
          }
          return null;
        });
        expect(
          await BackgroundSyncBridge.consumeLaunchPayload(),
          '{"notifId":"notif_bg_locked_1","tab":1}',
        );
      },
    );

    test('codebase contains zero SnackBar or showSnackBar usages in lib/', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);
      final violations = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          if (content.contains('SnackBar(') ||
              content.contains('showSnackBar(')) {
            violations.add(entity.path);
          }
        }
      }
      expect(violations, isEmpty);
    });
  });

  group('Chat Outgoing Message Protection & Seen Controls', () {
    test(
      'sendChatMessage clamps long reply previews and preserves pending message across remote snapshot races',
      () async {
        final repo = _TestLmtRepo();
        final cubit = LmtCubit(repository: repo);
        addTearDown(() async {
          await cubit.close();
          repo.dispose();
        });

        while (!cubit.state.isInitialized) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }

        final longReplyTarget = ChatMessageModel(
          id: 'msg_long_origin',
          groupId: 'grp_1',
          senderId: _TestLmtRepo._memberTwo.id,
          senderName: _TestLmtRepo._memberTwo.name,
          senderRole: UserRole.editor,
          type: MessageType.text,
          content: List.filled(1400, 'أ').join(),
          sentAt: DateTime.now().subtract(const Duration(minutes: 2)),
        );

        await cubit.sendChatMessage(
          groupId: 'grp_1',
          type: MessageType.text,
          content: 'وصلتني الرسالة',
          replyTo: longReplyTarget,
        );

        final sent = cubit.state.chatMessages.single;
        expect(sent.replyToPreview, isNotNull);
        expect(sent.replyToPreview!.length, 1000);
        expect(cubit.pendingOutgoingMessages.containsKey(sent.id), isTrue);

        // Concurrent remote snapshot from another user BEFORE Firestore echoes
        // `sent` must NOT erase `sent` from the sender's chatMessages list.
        final remoteOtherMsg = ChatMessageModel(
          id: 'msg_from_other',
          groupId: 'grp_1',
          senderId: _TestLmtRepo._memberTwo.id,
          senderName: _TestLmtRepo._memberTwo.name,
          senderRole: UserRole.editor,
          type: MessageType.text,
          content: 'رسالة من عضو تاني',
          sentAt: DateTime.now().subtract(const Duration(seconds: 5)),
        );
        repo.emitLiveSnapshot(
          LmtRepositorySnapshot(
            biometricEnabled: true,
            sloganOfYear: cubit.state.sloganOfYear,
            verseOfYear: cubit.state.verseOfYear,
            currentUser: cubit.state.currentUser,
            members: cubit.state.members,
            chatGroups: cubit.state.chatGroups,
            chatMessages: [remoteOtherMsg],
            posts: const [],
            sharedFiles: const [],
            calendarEvents: const [],
            notifications: const [],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(
          cubit.state.chatMessages.map((m) => m.id),
          containsAll([remoteOtherMsg.id, sent.id]),
        );

        // Once the server snapshot echoes `sent`, pending entry is cleared cleanly.
        repo.emitLiveSnapshot(
          LmtRepositorySnapshot(
            biometricEnabled: true,
            sloganOfYear: cubit.state.sloganOfYear,
            verseOfYear: cubit.state.verseOfYear,
            currentUser: cubit.state.currentUser,
            members: cubit.state.members,
            chatGroups: cubit.state.chatGroups,
            chatMessages: [remoteOtherMsg, sent],
            posts: const [],
            sharedFiles: const [],
            calendarEvents: const [],
            notifications: const [],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(cubit.pendingOutgoingMessages.containsKey(sent.id), isFalse);
      },
    );

    testWidgets(
      'GroupConversationRoom does NOT auto-mark Seen while biometric lock is active or autoMarkSeen is false',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = _TestLmtRepo();
        final cubit = _FakeChatSeenCubit(repository: repo);
        addTearDown(() async {
          await cubit.close();
          repo.dispose();
        });

        final incoming = ChatMessageModel(
          id: 'msg_unseen_1',
          groupId: 'grp_1',
          senderId: _TestLmtRepo._memberTwo.id,
          senderName: _TestLmtRepo._memberTwo.name,
          senderRole: UserRole.editor,
          type: MessageType.text,
          content: 'هل وصلك؟',
          sentAt: DateTime.now(),
        );
        cubit.emit(cubit.state.copyWith(chatMessages: [incoming]));

        // Locked behind Biometric shield -> never marks incoming seen.
        BiometricSessionLockController.instance.enterAuthenticatedSession(
          biometricEnabled: true,
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (_, _) => BlocProvider<LmtCubit>.value(
              value: cubit,
              child: MaterialApp(
                locale: const Locale('ar'),
                home: Scaffold(
                  body: GroupConversationRoom(
                    group: _TestLmtRepo._group,
                    onBack: () {},
                    autoMarkSeen: false,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(cubit.state.unreadMessagesCountForGroup('grp_1'), 1);

        // Unlock & enable autoMarkSeen -> marks visible incoming message Seen cleanly.
        BiometricSessionLockController.instance.resetToLoggedOut();
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (_, _) => BlocProvider<LmtCubit>.value(
              value: cubit,
              child: MaterialApp(
                locale: const Locale('ar'),
                home: Scaffold(
                  body: GroupConversationRoom(
                    group: _TestLmtRepo._group,
                    onBack: () {},
                    autoMarkSeen: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(cubit.state.unreadMessagesCountForGroup('grp_1'), 0);
        expect(
          cubit.state.chatMessages.single.seenBy
              .any((s) => s.memberId == _TestLmtRepo._admin.id),
          isTrue,
        );
      },
    );

    testWidgets(
      'ChatMessageBubble & ChatGroupTile display single tick when unseen and double tick only when another member saw',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final unseenSent = ChatMessageModel(
          id: 'msg_tick_0',
          groupId: 'grp_1',
          senderId: _TestLmtRepo._admin.id,
          senderName: _TestLmtRepo._admin.name,
          senderRole: UserRole.admin,
          type: MessageType.text,
          content: 'رسالة لم تُقرأ بعد',
          sentAt: DateTime.now(),
          seenBy: const [],
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (_, _) => MaterialApp(
              locale: const Locale('ar'),
              home: Scaffold(
                body: Column(
                  children: [
                    ChatGroupTile(
                      group: _TestLmtRepo._group,
                      lastMessage: unseenSent,
                      unreadCount: 0,
                      currentUserId: _TestLmtRepo._admin.id,
                      canEditGroups: true,
                      canDeleteGroups: true,
                      onTap: () {},
                      onTogglePin: () {},
                      onEdit: () {},
                      onLeave: () {},
                      onDelete: () {},
                    ),
                    ChatMessageBubble(
                      msg: unseenSent,
                      isMe: true,
                      isPlayingVoice: false,
                      onShowActions: () {},
                      onShowSeenBy: () {},
                      onToggleReaction: (_) {},
                      onToggleVoicePlay: () {},
                      onReply: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
        expect(find.byIcon(Icons.done_all_rounded), findsNothing);

        final seenByOther = unseenSent.copyWith(
          seenBy: [
            SeenStatusModel(
              memberId: _TestLmtRepo._memberTwo.id,
              memberName: _TestLmtRepo._memberTwo.name,
              timestamp: DateTime.now(),
            ),
          ],
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (_, _) => MaterialApp(
              locale: const Locale('ar'),
              home: Scaffold(
                body: Column(
                  children: [
                    ChatGroupTile(
                      group: _TestLmtRepo._group,
                      lastMessage: seenByOther,
                      unreadCount: 0,
                      currentUserId: _TestLmtRepo._admin.id,
                      canEditGroups: true,
                      canDeleteGroups: true,
                      onTap: () {},
                      onTogglePin: () {},
                      onEdit: () {},
                      onLeave: () {},
                      onDelete: () {},
                    ),
                    ChatMessageBubble(
                      msg: seenByOther,
                      isMe: true,
                      isPlayingVoice: false,
                      onShowActions: () {},
                      onShowSeenBy: () {},
                      onToggleReaction: (_) {},
                      onToggleVoicePlay: () {},
                      onReply: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.done_all_rounded), findsNWidgets(2));
        expect(find.byIcon(Icons.check_rounded), findsNothing);
      },
    );
  });

  group(
    'Sync Order, Targeted Cloud Writes, Dispose Seen Flush & Single-Shot Shorebird Dialog',
    () {
      test(
        'ShorebirdUpdateService shows pending & active popups at most once and deduplicates concurrent checks',
        () async {
          final updater = _SpyShorebirdUpdater(
            nextStatus: UpdateStatus.outdated,
          );
          final service = ShorebirdUpdateService(
            bridge: ShorebirdPlatformBridge(
              updaterFactory: () => updater,
              appVersionReader: () async =>
                  (version: '1.0.2', buildNumber: '3'),
            ),
          );

          // 1. Outdated -> downloads Patch #1 -> emits restartRequired popup once.
          final first = await service.checkAndSyncUpdates();
          expect(first.welcomeMessage, isNotNull);
          expect(first.welcomeMessage!.restartRequired, isTrue);
          expect(first.welcomeMessage!.versionLabel, 'v1.0.2+3 (Patch #1)');

          // 2. Repeated resumes/relaunches while still awaiting restart stay silent.
          updater.nextStatus = UpdateStatus.restartRequired;
          final second = await service.checkAndSyncUpdates();
          expect(second.welcomeMessage, isNull);

          final freshBeforeRestart = ShorebirdUpdateService(
            bridge: ShorebirdPlatformBridge(
              updaterFactory: () => updater,
              appVersionReader: () async =>
                  (version: '1.0.2', buildNumber: '3'),
            ),
          );
          final third = await freshBeforeRestart.checkAndSyncUpdates();
          expect(third.welcomeMessage, isNull);

          // 3. Process restarts onto Patch #1 -> concurrent calls share single result & show active popup once.
          final activeUpdater = _SpyShorebirdUpdater(
            currentPatch: const Patch(number: 1),
            nextStatus: UpdateStatus.upToDate,
          );
          final restarted = ShorebirdUpdateService(
            bridge: ShorebirdPlatformBridge(
              updaterFactory: () => activeUpdater,
              appVersionReader: () async =>
                  (version: '1.0.2', buildNumber: '3'),
            ),
          );
          final concurrent = await Future.wait([
            restarted.checkAndSyncUpdates(),
            restarted.checkAndSyncUpdates(),
          ]);
          expect(concurrent[0].welcomeMessage, isNotNull);
          expect(concurrent[0].welcomeMessage!.restartRequired, isFalse);
          expect(identical(concurrent[0], concurrent[1]), isTrue);

          final afterDismiss = await restarted.checkAndSyncUpdates();
          expect(afterDismiss.welcomeMessage, isNull);
        },
      );

      test(
        'sendChatMessage writes atomically to cloud + local cache without full persistSnapshot overwrite',
        () async {
          final repo = _SpyChatSyncRepo();
          addTearDown(repo.dispose);
          final cubit = _FakeChatSeenCubit(repository: repo);
          addTearDown(cubit.close);

          await cubit.sendChatMessage(
            groupId: _TestLmtRepo._group.id,
            type: MessageType.text,
            content: 'رسالة اختبار جديدة',
          );

          expect(repo.persistSnapshotCalls, 0);
          expect(repo.persistLocalSnapshotCalls, 1);
          expect(repo.sentCloudWrites.length, 1);
          expect(
            repo.sentCloudWrites.single.message.content,
            'رسالة اختبار جديدة',
          );
          expect(repo.sentCloudWrites.single.notification, isNotNull);
        },
      );

      test(
        'LayoutCubit.syncNow skips pre-sync persistSnapshot and preserves pending messages & local seen receipts',
        () async {
          final repo = _SpyChatSyncRepo();
          addTearDown(repo.dispose);
          final cubit = _FakeChatSeenCubit(repository: repo);
          addTearDown(cubit.close);

          final baseTime = DateTime.now();
          final unseenRemoteMsg = ChatMessageModel(
            id: 'msg_remote_1',
            groupId: _TestLmtRepo._group.id,
            senderId: _TestLmtRepo._memberTwo.id,
            senderName: _TestLmtRepo._memberTwo.name,
            senderRole: _TestLmtRepo._memberTwo.role,
            type: MessageType.text,
            content: 'رسالة وصلت من عضو آخر',
            sentAt: baseTime.subtract(const Duration(seconds: 30)),
            seenBy: const [],
          );
          final locallySeenMsg = unseenRemoteMsg.copyWith(
            seenBy: [
              SeenStatusModel(
                memberId: _TestLmtRepo._admin.id,
                memberName: _TestLmtRepo._admin.name,
                avatarPath: _TestLmtRepo._admin.avatarPath,
                timestamp: baseTime.subtract(const Duration(seconds: 20)),
              ),
            ],
          );
          final pendingMsg = ChatMessageModel(
            id: 'msg_pending_local',
            groupId: _TestLmtRepo._group.id,
            senderId: _TestLmtRepo._admin.id,
            senderName: _TestLmtRepo._admin.name,
            senderRole: _TestLmtRepo._admin.role,
            type: MessageType.text,
            content: 'رسالة لم تصل السيرفر بعد',
            sentAt: baseTime.subtract(const Duration(seconds: 10)),
          );

          cubit.pendingOutgoingMessages[pendingMsg.id] = pendingMsg;
          cubit.emit(cubit.state.copyWith(chatMessages: [locallySeenMsg]));
          repo.remoteMessagesOverride = [unseenRemoteMsg];

          await cubit.syncNow();
          await Future<void>.delayed(Duration.zero);

          expect(repo.persistSnapshotCalls, 0);
          expect(
            cubit.state.chatMessages.any((m) => m.id == pendingMsg.id),
            isTrue,
          );
          expect(cubit.state.unreadMessagesCountForGroup('grp_1'), 0);
          expect(repo.sentCloudWrites.length, 1);
          expect(repo.sentCloudWrites.single.message.id, pendingMsg.id);
          expect(repo.seenCloudWrites.length, 1);
          expect(repo.seenCloudWrites.single.updatedMessages.single.id,
              unseenRemoteMsg.id);
        },
      );

      testWidgets(
        'GroupConversationRoom dispose unconditionally flushes seen receipts even without an active throttle timer',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final repo = _SpyChatSyncRepo();
          addTearDown(repo.dispose);
          final cubit = _FakeChatSeenCubit(repository: repo);
          addTearDown(cubit.close);

          final unreadMsg = ChatMessageModel(
            id: 'msg_dispose_1',
            groupId: _TestLmtRepo._group.id,
            senderId: _TestLmtRepo._memberTwo.id,
            senderName: _TestLmtRepo._memberTwo.name,
            senderRole: _TestLmtRepo._memberTwo.role,
            type: MessageType.text,
            content: 'رسالة جديدة عند الخروج السريع',
            sentAt: DateTime(2026, 11, 24, 15, 5),
            seenBy: const [],
          );
          cubit.emit(cubit.state.copyWith(chatMessages: [unreadMsg]));

          await tester.pumpWidget(
            BlocProvider<LmtCubit>.value(
              value: cubit,
              child: ScreenUtilInit(
                designSize: const Size(390, 844),
                minTextAdapt: true,
                builder: (_, _) => MaterialApp(
                  locale: const Locale('ar'),
                  home: Scaffold(
                    body: GroupConversationRoom(
                      group: _TestLmtRepo._group,
                      showInlineHeader: true,
                      autoMarkSeen: true,
                      onBack: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          // Immediately pop/unmount the room before post-frame timers run.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          expect(cubit.state.unreadMessagesCountForGroup('grp_1'), 0);
          expect(repo.persistLocalSnapshotCalls, greaterThanOrEqualTo(1));
          expect(repo.seenCloudWrites, isNotEmpty);
        },
      );
    },
  );
}

class _SpyShorebirdUpdater implements ShorebirdUpdater {
  @override
  final bool isAvailable = true;
  Patch? currentPatch;
  Patch? nextPatch;
  UpdateStatus nextStatus;

  _SpyShorebirdUpdater({
    this.currentPatch,
    this.nextStatus = UpdateStatus.upToDate,
  });

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async => nextStatus;

  @override
  Future<Patch?> readCurrentPatch() async => currentPatch;

  @override
  Future<Patch?> readNextPatch() async => nextPatch;

  @override
  Future<void> update({UpdateTrack? track}) async {
    nextPatch ??= Patch(number: (currentPatch?.number ?? 0) + 1);
  }
}

class _SpyChatSyncRepo extends _TestLmtRepo {
  int persistSnapshotCalls = 0;
  int persistLocalSnapshotCalls = 0;
  List<ChatMessageModel> remoteMessagesOverride = const [];
  final List<({ChatMessageModel message, AppNotificationModel? notification})>
      sentCloudWrites = [];
  final List<({List<ChatMessageModel> updatedMessages, SeenStatusModel viewerReceipt})>
      seenCloudWrites = [];

  @override
  Future<LmtRepositorySnapshot> loadSnapshot() async {
    final base = await super.loadSnapshot();
    return LmtRepositorySnapshot(
      biometricEnabled: base.biometricEnabled,
      sloganOfYear: base.sloganOfYear,
      verseOfYear: base.verseOfYear,
      currentUser: base.currentUser,
      members: base.members,
      chatGroups: base.chatGroups,
      chatMessages: remoteMessagesOverride,
      posts: base.posts,
      sharedFiles: base.sharedFiles,
      calendarEvents: base.calendarEvents,
      notifications: base.notifications,
      khelwaDays: base.khelwaDays,
    );
  }

  @override
  Future<void> persistSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {
    persistSnapshotCalls++;
  }

  @override
  Future<void> persistLocalSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {
    persistLocalSnapshotCalls++;
  }

  @override
  Future<void> sendChatMessageToCloud({
    required ChatMessageModel message,
    AppNotificationModel? notification,
  }) async {
    sentCloudWrites.add((message: message, notification: notification));
  }

  @override
  Future<void> markMessagesSeenInCloud({
    required List<ChatMessageModel> updatedMessages,
    required SeenStatusModel viewerReceipt,
  }) async {
    seenCloudWrites.add(
      (updatedMessages: updatedMessages, viewerReceipt: viewerReceipt),
    );
  }
}
