import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmt/core/models/lmt_models.dart';
import 'package:lmt/core/repositories/lmt_repository.dart';
import 'package:lmt/core/utils/app_assets.dart';
import 'package:lmt/core/utils/app_preferences.dart';
import 'package:lmt/core/widgets/adaptive_layout.dart';
import 'package:lmt/core/widgets/expandable_text.dart';
import 'package:lmt/features/chatting_room/cubit/chat_cubit.dart';
import 'package:lmt/features/home/widgets/poll_options_editor.dart';
import 'package:lmt/features/home/widgets/timeline_post_card.dart';
import 'package:lmt/features/khelwa/data/khelwa_repository.dart';
import 'package:lmt/features/profile/cubit/profile_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryLmtRepo implements LmtRepository {
  @override
  Future<LmtRepositorySnapshot> loadSnapshot() async {
    return LmtRepositorySnapshot(
      biometricEnabled: true,
      sloganOfYear: '#تغيروا_2026',
      verseOfYear: 'verse',
      currentUser: _user1,
      members: [_user1, _user2],
      chatGroups: const [],
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

const _user1 = MemberModel(
  id: 'LMT-001',
  name: 'Mario Naiem',
  username: 'mario',
  password: 'password',
  role: UserRole.admin,
  groups: ['جروب الخلوة اليومية 🙏'],
  departments: ['إخراج'],
  committees: ['اللجنة الفنية'],
  avatarPath: AppAssets.accountIcon,
);

const _user2 = MemberModel(
  id: 'LMT-012',
  name: 'Samy Farouk',
  username: 'samy',
  password: 'password',
  role: UserRole.editor,
  groups: ['جروب الخلوة اليومية 🙏'],
  departments: ['تمثيل'],
  committees: ['اللجنة الفنية'],
  avatarPath: AppAssets.accountIcon,
);

class _TestFeatureCubit extends LmtBaseCubit
    with ProfileCubitMixin, ChatCubitMixin {
  _TestFeatureCubit({List<ChatMessageModel> initialMessages = const []})
      : super(repository: _InMemoryLmtRepo()) {
    emit(
      state.copyWith(
        currentUser: _user1,
        members: [_user1, _user2],
        chatMessages: initialMessages,
      ),
    );
  }
}

Widget _wrapWithApp(
  Widget child, {
  Size size = const Size(375, 812),
  LmtCubit? cubit,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) {
      return MaterialApp(
        locale: const Locale('en'),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: cubit != null
              ? BlocProvider<LmtCubit>.value(value: cubit, child: Scaffold(body: child))
              : Scaffold(body: child),
        ),
      );
    },
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KhelwaRepository per-user check-in isolation', () {
    test('recording Khelwa for one user does NOT auto-record another user on load', () async {
      const repo = KhelwaRepository();

      // Legacy fallback key set from another user on this device.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        KhelwaRepository.khelwaKeyPrefix,
        DateTime.now().toIso8601String(),
      );

      // User 1 records Khelwa explicitly today.
      final afterUser1 = await repo.record(
        userId: _user1.id,
        userName: _user1.name,
      );
      expect(afterUser1.daysDifference, 0);
      expect(afterUser1.todayAttendees, [_user1.name]);

      // User 2 opens Khelwa screen WITHOUT pressing the button.
      final user2Loaded = await repo.load(
        userId: _user2.id,
        userName: _user2.name,
      );
      expect(user2Loaded.daysDifference, greaterThan(0));
      expect(user2Loaded.todayAttendees.contains(_user2.name), isFalse);

      // User 1 reloading still sees today's recorded state.
      final user1Reloaded = await repo.load(
        userId: _user1.id,
        userName: _user1.name,
      );
      expect(user1Reloaded.daysDifference, 0);
      expect(user1Reloaded.todayAttendees.contains(_user1.name), isTrue);
    });
  });

  group('Chat edit time limit & Profile avatar updates', () {
    test('allows editing within 15 minutes and blocks editing after 15 minutes', () async {
      final now = DateTime.now();
      final recentMsg = ChatMessageModel(
        id: 'm_recent',
        groupId: 'g1',
        senderId: _user1.id,
        senderName: _user1.name,
        content: 'Recent message',
        sentAt: now.subtract(const Duration(minutes: 5)),
      );
      final oldMsg = ChatMessageModel(
        id: 'm_old',
        groupId: 'g1',
        senderId: _user1.id,
        senderName: _user1.name,
        content: 'Old message',
        sentAt: now.subtract(const Duration(minutes: 16)),
      );

      final cubit = _TestFeatureCubit(initialMessages: [recentMsg, oldMsg]);

      expect(cubit.canEditMessageNow(recentMsg), isTrue);
      expect(cubit.canEditMessageNow(oldMsg), isFalse);

      final recentOk = await cubit.editChatMessage(
        messageId: 'm_recent',
        newContent: 'Updated recent',
      );
      final oldRejected = await cubit.editChatMessage(
        messageId: 'm_old',
        newContent: 'Attempt after expiry',
      );

      expect(recentOk, isTrue);
      expect(oldRejected, isFalse);
      expect(cubit.state.chatMessages.first.content, 'Updated recent');
      expect(cubit.state.chatMessages.first.isEdited, isTrue);
      expect(cubit.state.chatMessages.last.content, 'Old message');

      await cubit.close();
    });

    test('any user role can update their profile avatar and it propagates', () async {
      final cubit = _TestFeatureCubit(
        initialMessages: [
          ChatMessageModel(
            id: 'm1',
            groupId: 'g1',
            senderId: _user2.id,
            senderName: _user2.name,
            content: 'Hello',
            sentAt: DateTime.now(),
          ),
        ],
      );
      // Switch active user to Editor (_user2)
      cubit.emit(cubit.state.copyWith(currentUser: _user2));

      await cubit.updateProfileAvatar('/tmp/custom_samy_avatar.jpg');

      expect(cubit.state.currentUser.avatarPath, '/tmp/custom_samy_avatar.jpg');
      expect(
        cubit.state.members.firstWhere((m) => m.id == _user2.id).avatarPath,
        '/tmp/custom_samy_avatar.jpg',
      );
      expect(
        cubit.state.chatMessages.first.senderAvatar,
        '/tmp/custom_samy_avatar.jpg',
      );
      await cubit.close();
    });
  });

  group('Biometric preference flag persistence', () {
    test('saves and reads biometric enabled and rememberMe flags cleanly', () async {
      await AppPreferences.setBiometricEnabled(false);
      await AppPreferences.setRememberMe(true);
      expect(await AppPreferences.isBiometricEnabled(), isFalse);
      expect(await AppPreferences.isRememberMeEnabled(), isTrue);

      await AppPreferences.setBiometricEnabled(true);
      expect(await AppPreferences.isBiometricEnabled(), isTrue);
    });
  });

  group('Widget tests: ExpandableText, PollOptionsEditor, Poll Fade & AdaptiveLayout', () {
    testWidgets('LmtExpandableText collapses text > 200 chars and toggles on tap', (tester) async {
      final longText = List.filled(45, 'LMT rehearsal update').join(' ');
      expect(longText.length, greaterThan(200));

      await tester.pumpWidget(
        _wrapWithApp(
          LmtExpandableText(
            text: longText,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);
      expect(find.text('Show less'), findsNothing);

      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('PollOptionsEditor allows adding >3 dynamic options via + button', (tester) async {
      final ctrls = [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: PollOptionsEditor(
                  controllers: ctrls,
                  onAddOption: () => setState(() => ctrls.add(TextEditingController())),
                  onRemoveOption: (idx) => setState(() => ctrls.removeAt(idx)),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Poll Options (3):'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Poll Options (4):'), findsOneWidget);
      await tester.tap(find.text('+ Add another option'));
      await tester.pumpAndSettle();

      expect(find.text('Poll Options (5):'), findsOneWidget);
      for (final c in ctrls) {
        c.dispose();
      }
    });

    testWidgets('TimelinePostCard fades extra poll options and expands on More tap', (tester) async {
      final longPollPost = PostModel(
        id: 'p_poll',
        creatorId: _user1.id,
        creatorName: _user1.name,
        creatorAvatar: AppAssets.accountIcon,
        publishTime: DateTime.now(),
        type: PostCategoryType.poll,
        content: List.filled(40, 'Poll description word').join(' '),
        pollOptions: const [
          PollOptionModel(id: 'o1', text: 'Option Alpha'),
          PollOptionModel(id: 'o2', text: 'Option Beta'),
          PollOptionModel(id: 'o3', text: 'Option Gamma'),
          PollOptionModel(id: 'o4', text: 'Option Delta'),
          PollOptionModel(id: 'o5', text: 'Option Epsilon'),
        ],
      );

      final cubit = LmtCubit(repository: _InMemoryLmtRepo());
      addTearDown(cubit.close);

      await tester.pumpWidget(
        _wrapWithApp(
          SingleChildScrollView(
            child: TimelinePostCard(
              post: longPollPost,
              currentUser: _user1,
              onShowComments: () {},
            ),
          ),
          cubit: cubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);
      expect(find.text('More options (+2)'), findsOneWidget);
      expect(find.text('Option Epsilon'), findsNothing);

      await tester.ensureVisible(find.text('More options (+2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More options (+2)'));
      await tester.pumpAndSettle();

      expect(find.text('Option Epsilon'), findsOneWidget);
      expect(find.text('Show less options'), findsOneWidget);
    });

    testWidgets('AdaptiveContentBox constrains wide screens cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrapWithApp(
          SizedBox(
            width: 1024,
            height: 768,
            child: AdaptiveContentBox(
              maxWidth: 680,
              child: const SizedBox(
                key: Key('inner_box'),
                width: double.infinity,
                height: 100,
              ),
            ),
          ),
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();

      final renderedWidth = tester.getSize(find.byKey(const Key('inner_box'))).width;
      expect(renderedWidth, 680);
    });
  });
}
