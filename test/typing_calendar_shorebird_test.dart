import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmt/core/models/lmt_models.dart';
import 'package:lmt/core/repositories/lmt_repository.dart';
import 'package:lmt/core/services/shorebird_update_service.dart';
import 'package:lmt/core/utils/app_assets.dart';
import 'package:lmt/core/widgets/lmt_avatar.dart';
import 'package:lmt/core/widgets/shorebird_welcome_dialog.dart';
import 'package:lmt/features/calendar/cubit/calendar_cubit.dart';
import 'package:lmt/features/calendar/views/calendar_screen.dart';
import 'package:lmt/features/calendar/views/full_months_calendar_page.dart';
import 'package:lmt/features/chatting_room/cubit/chat_cubit.dart';
import 'package:lmt/features/chatting_room/widgets/chat_typing_indicator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class _InMemoryTestRepo implements LmtRepository {
  @override
  Future<LmtRepositorySnapshot> loadSnapshot() async {
    return LmtRepositorySnapshot(
      biometricEnabled: true,
      sloganOfYear: '#تغيروا_2026',
      verseOfYear: 'verse',
      currentUser: _mario,
      members: [_mario, _mina, _marina],
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
}

const _mario = MemberModel(
  id: 'LMT-2026-001',
  username: 'admin',
  password: 'password123',
  name: 'Mario Naiem',
  role: UserRole.admin,
  groups: ['grp_1'],
  avatarPath: AppAssets.accountIcon,
);

const _mina = MemberModel(
  id: 'LMT-2026-002',
  username: 'mina',
  password: 'password123',
  name: 'Mina Adel',
  role: UserRole.editor,
  groups: ['grp_1'],
  avatarPath: AppAssets.accountIcon,
);

const _marina = MemberModel(
  id: 'LMT-2026-003',
  username: 'marina',
  password: 'password123',
  name: 'Marina Emad',
  role: UserRole.member,
  groups: ['grp_1'],
  avatarPath: AppAssets.accountIcon,
);

final _group = ChatGroupModel(
  id: 'grp_1',
  name: 'Team Chat',
  description: 'desc',
  imagePath: AppAssets.actIcon,
  memberIds: const ['LMT-2026-001', 'LMT-2026-002', 'LMT-2026-003'],
  adminId: 'LMT-2026-001',
  adminName: 'Mario Naiem',
  isPinned: false,
  createdAt: DateTime(2026, 11, 1),
);

class _FakeTestCubit extends LmtBaseCubit
    with ChatCubitMixin, CalendarCubitMixin
    implements LmtCubit {
  _FakeTestCubit() : super(repository: _InMemoryTestRepo()) {
    emit(
      state.copyWith(
        isInitialized: true,
        currentUser: _mario,
        members: [_mario, _mina, _marina],
        chatGroups: [_group],
      ),
    );
  }

  void switchUser(MemberModel user) {
    emit(state.copyWith(currentUser: user));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShorebirdUpdater implements ShorebirdUpdater {
  @override
  final bool isAvailable;
  Patch? currentPatch;
  Patch? nextPatch;
  UpdateStatus nextStatus;
  bool updateCalled = false;

  _FakeShorebirdUpdater({
    this.currentPatch,
    this.nextPatch,
    this.nextStatus = UpdateStatus.upToDate,
  }) : isAvailable = true;

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async => nextStatus;

  @override
  Future<Patch?> readCurrentPatch() async => currentPatch;

  @override
  Future<Patch?> readNextPatch() async => nextPatch;

  @override
  Future<void> update({UpdateTrack? track}) async {
    updateCalled = true;
    nextPatch ??= Patch(number: (currentPatch?.number ?? 0) + 1);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Multi-User Group Typing Indicator', () {
    test('hides self typing from writer and merges simultaneous remote typists cleanly', () async {
      final cubit = _FakeTestCubit();

      // Current user (_mario) types -> MUST NOT appear in visibleTypingMembersForGroup for _mario.
      await cubit.setTypingInGroup(groupId: 'grp_1', isTyping: true);
      expect(cubit.state.visibleTypingMembersForGroup('grp_1'), isEmpty);

      // Remote users (_mina and _marina) start typing simultaneously.
      cubit.switchUser(_mina);
      await cubit.setTypingInGroup(groupId: 'grp_1', isTyping: true);
      cubit.switchUser(_marina);
      await cubit.setTypingInGroup(groupId: 'grp_1', isTyping: true);

      // Switch back to _mario: sees BOTH _mina and _marina typing (never himself).
      cubit.switchUser(_mario);
      final visibleToMario = cubit.state.visibleTypingMembersForGroup('grp_1');
      expect(visibleToMario.map((t) => t.memberId), ['LMT-2026-002', 'LMT-2026-003']);

      // Stale heartbeats older than 8s auto-expire cleanly.
      final futureExpired = cubit.state.visibleTypingMembersForGroup(
        'grp_1',
        now: DateTime.now().add(const Duration(seconds: 12)),
      );
      expect(futureExpired, isEmpty);

      // _mina stops typing -> only _marina remains.
      cubit.switchUser(_mina);
      await cubit.setTypingInGroup(groupId: 'grp_1', isTyping: false);
      cubit.switchUser(_mario);
      final afterMinaStops = cubit.state.visibleTypingMembersForGroup('grp_1');
      expect(afterMinaStops.map((t) => t.memberId), ['LMT-2026-003']);

      await cubit.close();
    });

    testWidgets('ChatTypingIndicator renders multiple simultaneous typists & avatars', (tester) async {
      final now = DateTime.now();
      final typists = [
        TypingMemberStatus(
          groupId: 'grp_1',
          memberId: _mina.id,
          memberName: _mina.name,
          avatarPath: _mina.avatarPath,
          updatedAt: now,
        ),
        TypingMemberStatus(
          groupId: 'grp_1',
          memberId: _marina.id,
          memberName: _marina.name,
          avatarPath: _marina.avatarPath,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            locale: const Locale('en'),
            home: Scaffold(body: ChatTypingIndicator(typingMembers: typists)),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LmtAvatar), findsNWidgets(2));
      expect(find.text('Mina Adel and Marina Emad are typing'), findsOneWidget);
    });
  });

  group('Calendar Auto-Select Today & Idle Reset', () {
    testWidgets('FullMonthsCalendarPage defaults to today and resets back after idle timeout', (tester) async {
      final cubit = _FakeTestCubit();
      final now = DateTime.now();
      final todayLabel = now.day.toString().padLeft(2, '0');

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => BlocProvider<LmtCubit>.value(
            value: cubit,
            child: MaterialApp(
              locale: const Locale('en'),
              home: FullMonthsCalendarPage(
                initialFocusedMonth: DateTime(now.year, now.month, 1),
                idleResetDuration: const Duration(seconds: 2),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Defaults to today's day header cleanly.
      expect(find.textContaining(todayLabel), findsWidgets);

      // Tap Chevron Next Month to move away from current month/day.
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      // Wait longer than idleResetDuration without interaction -> snaps back to Today!
      await tester.pump(const Duration(seconds: 2, milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.textContaining(todayLabel), findsWidgets);

      await cubit.close();
    });

    testWidgets('CalendarScreen opens on today and resets from "All" filter after idle timeout', (tester) async {
      final cubit = _FakeTestCubit();

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => BlocProvider<LmtCubit>.value(
            value: cubit,
            child: const MaterialApp(
              locale: Locale('en'),
              home: Scaffold(
                body: CalendarScreen(
                  idleResetDuration: Duration(seconds: 2),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially Clear Filter button IS visible because Today is auto-selected.
      expect(find.byTooltip('Clear Filter'), findsOneWidget);

      // Tap "All" to switch to unfiltered mode -> Clear Filter disappears.
      await tester.tap(find.text('All\n🗓️'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Clear Filter'), findsNothing);

      // Leave Calendar idle with no interaction -> resets automatically back to Today!
      await tester.pump(const Duration(seconds: 2, milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Clear Filter'), findsOneWidget);

      await cubit.close();
    });
  });

  group('Shorebird OTA Updates & Welcome Dialog', () {
    test('triggers auto-download when outdated and shows version/date welcome once after patch activation', () async {
      // 1. Fresh install on base binary (no previous version stored yet).
      final baseUpdater = _FakeShorebirdUpdater(
        currentPatch: null,
        nextStatus: UpdateStatus.outdated,
      );
      final service = ShorebirdUpdateService(
        bridge: ShorebirdPlatformBridge(
          updaterFactory: () => baseUpdater,
          appVersionReader: () async => (version: '1.0.0', buildNumber: '1'),
        ),
      );

      final firstCheck = await service.checkAndSyncUpdates();
      expect(baseUpdater.updateCalled, isTrue);
      expect(firstCheck.status, UpdateStatus.restartRequired);
      expect(firstCheck.welcomeMessage, isNotNull);
      expect(firstCheck.welcomeMessage!.versionLabel, contains('Patch #1'));
      expect(firstCheck.welcomeMessage!.restartRequired, isTrue);

      // 2. Restart onto Patch #1 -> emits active welcome dialog with exact version & date.
      final patchedUpdater = _FakeShorebirdUpdater(
        currentPatch: const Patch(number: 1),
        nextPatch: const Patch(number: 1),
        nextStatus: UpdateStatus.upToDate,
      );
      final patchedService = ShorebirdUpdateService(
        bridge: ShorebirdPlatformBridge(
          updaterFactory: () => patchedUpdater,
          appVersionReader: () async => (version: '1.0.0', buildNumber: '1'),
        ),
      );

      final secondCheck = await patchedService.checkAndSyncUpdates();
      expect(secondCheck.welcomeMessage, isNotNull);
      expect(secondCheck.welcomeMessage!.restartRequired, isFalse);
      expect(secondCheck.welcomeMessage!.versionLabel, 'v1.0.0+1 (Patch #1)');

      // 3. Subsequent launch on same Patch #1 does NOT show duplicate welcome.
      final thirdCheck = await patchedService.checkAndSyncUpdates();
      expect(thirdCheck.welcomeMessage, isNull);
    });

    testWidgets('ShorebirdWelcomeDialog renders version number and update date', (tester) async {
      final msg = ShorebirdWelcomeMessage(
        versionLabel: 'v1.0.0+1 (Patch #2)',
        updatedAt: DateTime(2026, 11, 23, 14, 15),
        restartRequired: false,
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            locale: const Locale('en'),
            home: Scaffold(body: ShorebirdWelcomeDialog(message: msg)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to the New Update! 🎉'), findsOneWidget);
      expect(find.textContaining('v1.0.0+1 (Patch #2)'), findsOneWidget);
      expect(find.textContaining('23/11/2026'), findsOneWidget);
    });
  });
}
