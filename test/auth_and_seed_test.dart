import 'package:flutter_test/flutter_test.dart';
import 'package:lmt/core/data/lmt_seed_data.dart';
import 'package:lmt/core/models/lmt_models.dart';
import 'package:lmt/core/repositories/lmt_repository.dart';
import 'package:lmt/core/utils/app_preferences.dart';
import 'package:lmt/features/auth/cubit/auth_cubit.dart';
import 'package:lmt/features/members/cubit/members_cubit.dart';
import 'package:lmt/features/profile/cubit/profile_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthCubit extends LmtBaseCubit
    with AuthCubitMixin, ProfileCubitMixin, MembersCubitMixin {
  _TestAuthCubit({LmtRepository? repository})
      : super(repository: repository ?? const LmtLocalRepositoryImpl());

  Future<void> hydrate() async {
    final snap = await repository.loadSnapshot();
    emit(
      state.copyWith(
        isInitialized: true,
        biometricEnabled: snap.biometricEnabled,
        sloganOfYear: snap.sloganOfYear,
        verseOfYear: snap.verseOfYear,
        currentUser: snap.currentUser,
        members: snap.members,
        chatGroups: snap.chatGroups,
        chatMessages: snap.chatMessages,
        posts: snap.posts,
        sharedFiles: snap.sharedFiles,
        calendarEvents: snap.calendarEvents,
        notifications: snap.notifications,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Clean Seed Data', () {
    test(
      'contains only single bootstrap admin, single khelwa group, and empty content lists',
      () {
        expect(LmtSeedData.initialMembers, hasLength(1));
        final admin = LmtSeedData.initialMembers.single;
        expect(admin.id, 'LMT-2026-001');
        expect(admin.username, 'admin');
        expect(admin.password, 'password123');
        expect(admin.role, UserRole.admin);
        expect(admin.verifyPassword('password123'), isTrue);

        expect(LmtSeedData.initialGroups, hasLength(1));
        expect(LmtSeedData.initialGroups.single.id, 'grp_khelwa');
        expect(LmtSeedData.initialGroups.single.memberIds, ['LMT-2026-001']);

        expect(LmtSeedData.initialMessages, isEmpty);
        expect(LmtSeedData.initialPosts, isEmpty);
        expect(LmtSeedData.initialSharedFiles, isEmpty);
        expect(LmtSeedData.initialEvents, isEmpty);
        expect(LmtSeedData.initialNotifications, isEmpty);
        expect(LmtSeedData.defaultVerseAr.contains('/n'), isFalse);
        expect(LmtSeedData.defaultVerseAr.contains('\n'), isTrue);
      },
    );
  });

  group('MemberModel Credential Verification', () {
    test('verifies matching password and rejects empty or wrong defaults', () {
      final emptyMember = MemberModel.fromJson(const {'id': 'LMT-2026-099'});
      expect(emptyMember.username, isEmpty);
      expect(emptyMember.password, isEmpty);
      expect(emptyMember.verifyPassword('12345678'), isFalse);
      expect(emptyMember.verifyPassword(''), isFalse);

      final seededMember = MemberModel.fromJson(const {
        'id': 'LMT-2026-002',
        'username': 'mina',
        'password': 'SecretPass!2026',
        'name': 'Mina',
      });
      expect(seededMember.verifyPassword('SecretPass!2026'), isTrue);
      expect(seededMember.verifyPassword('WrongPassword'), isFalse);
    });
  });

  group('Strict Auth, Biometrics, Profile Password & Member Account CRUD', () {
    test(
      'rejects unknown usernames and wrong passwords, accepts valid bootstrap admin',
      () async {
        final cubit = _TestAuthCubit();
        await cubit.hydrate();

        await expectLater(
          () => cubit.login(username: 'editor', password: 'password123'),
          throwsA(isA<AuthException>()),
        );
        await expectLater(
          () => cubit.login(
            username: 'random_stranger',
            password: 'password123',
          ),
          throwsA(isA<AuthException>()),
        );
        await expectLater(
          () => cubit.login(username: 'admin', password: 'wrong_password'),
          throwsA(isA<AuthException>()),
        );
        expect(await AppPreferences.isLoggedIn(), isFalse);

        final loggedInAdmin =
            await cubit.login(username: 'ADMIN', password: 'password123');
        expect(loggedInAdmin.id, 'LMT-2026-001');
        expect(loggedInAdmin.password, 'password123');
        expect(await AppPreferences.isLoggedIn(), isTrue);

        await cubit.close();
      },
    );

    test('updatePassword validates current password before updating password', () async {
      final cubit = _TestAuthCubit();
      await cubit.hydrate();
      await cubit.login(username: 'admin', password: 'password123');

      final rejected = await cubit.updatePassword(
        currentPassword: 'wrong_current_password',
        newPassword: 'newStrongPassword',
      );
      expect(rejected, isFalse);

      final updated = await cubit.updatePassword(
        currentPassword: 'password123',
        newPassword: 'newStrongPassword',
      );
      expect(updated, isTrue);
      expect(cubit.state.currentUser.password, 'newStrongPassword');

      await cubit.logout();
      await expectLater(
        () => cubit.login(username: 'admin', password: 'password123'),
        throwsA(isA<AuthException>()),
      );
      final signedInNew = await cubit.login(
        username: 'admin',
        password: 'newStrongPassword',
      );
      expect(signedInNew.id, 'LMT-2026-001');

      await cubit.close();
    });

    test(
      'addMember stores readable password, rejects duplicates, prevents ID collision, and syncs deletion',
      () async {
        final cubit = _TestAuthCubit();
        await cubit.hydrate();
        await cubit.login(username: 'admin', password: 'password123');

        final dupErr = await cubit.addMember(
          name: 'Another Admin',
          username: 'Admin',
          password: 'memberPass1',
          role: UserRole.member,
          departments: const ['ديكور'],
          committees: const ['اللجنة الفنية'],
          groups: const [],
        );
        expect(dupErr, isNotNull);

        final addErr1 = await cubit.addMember(
          name: 'Mina Adel',
          username: 'mina_adel',
          password: 'minaPass2026',
          role: UserRole.editor,
          departments: const ['ديكور'],
          committees: const ['اللجنة الفنية'],
          groups: const [],
        );
        expect(addErr1, isNull);
        final mina =
            cubit.state.members.firstWhere((m) => m.username == 'mina_adel');
        expect(mina.id, 'LMT-2026-002');
        expect(mina.password, 'minaPass2026');
        expect(
          cubit.state.chatGroups.single.memberIds.contains(mina.id),
          isTrue,
        );

        // Login as newly created user on a separate Cubit instance sharing persistence.
        final device2Cubit = _TestAuthCubit();
        await device2Cubit.hydrate();
        final loggedMina = await device2Cubit.login(
          username: 'mina_adel',
          password: 'minaPass2026',
        );
        expect(loggedMina.id, 'LMT-2026-002');

        // Delete mina on Admin cubit, verify group cleanup.
        await cubit.deleteMember(mina.id);
        expect(
          cubit.state.members.any((m) => m.id == 'LMT-2026-002'),
          isFalse,
        );
        expect(
          cubit.state.chatGroups.single.memberIds.contains('LMT-2026-002'),
          isFalse,
        );

        // Deleted user cannot unlock via biometrics after remote reload.
        await AppPreferences.saveLogin(
          username: mina.username,
          userId: mina.id,
        );
        await device2Cubit.hydrate();
        await expectLater(
          () => device2Cubit.loginWithBiometrics(),
          throwsA(isA<AuthException>()),
        );
        expect(await AppPreferences.isLoggedIn(), isFalse);
        await cubit.login(username: 'admin', password: 'password123');

        // Next after [001] -> 002; adding a 3rd gives 003; deleting 002 then adding produces 004.
        await cubit.addMember(
          name: 'Marina Emad',
          username: 'marina',
          password: 'marinaPass2026',
          role: UserRole.member,
          departments: const ['ميك اب'],
          committees: const ['اللجنة الروحية'],
          groups: const [],
        );
        final marina =
            cubit.state.members.firstWhere((m) => m.username == 'marina');
        expect(marina.id, 'LMT-2026-002');

        await cubit.addMember(
          name: 'Karim Youssef',
          username: 'karim',
          password: 'karimPass2026',
          role: UserRole.member,
          departments: const ['إضاءة'],
          committees: const ['اللجنة الإدارية'],
          groups: const [],
        );
        final karim =
            cubit.state.members.firstWhere((m) => m.username == 'karim');
        expect(karim.id, 'LMT-2026-003');

        await cubit.deleteMember(marina.id);
        await cubit.addMember(
          name: 'Shady George',
          username: 'shady',
          password: 'shadyPass2026',
          role: UserRole.member,
          departments: const ['إضاءة'],
          committees: const ['اللجنة العامة'],
          groups: const [],
        );
        final shady =
            cubit.state.members.firstWhere((m) => m.username == 'shady');
        expect(shady.id, 'LMT-2026-004');

        // Admin password reset stores readable new password and invalidates old one.
        final resetErr = await cubit.resetMemberPassword(
          memberId: shady.id,
          newPassword: 'shadyReset999',
        );
        expect(resetErr, isNull);
        await cubit.logout();
        await expectLater(
          () => cubit.login(username: 'shady', password: 'shadyPass2026'),
          throwsA(isA<AuthException>()),
        );
        final loggedShady = await cubit.login(
          username: 'shady',
          password: 'shadyReset999',
        );
        expect(loggedShady.id, shady.id);
        expect(loggedShady.password, 'shadyReset999');

        // Biometrics succeed when logged in as valid member and enabled in prefs.
        final bioShady = await cubit.loginWithBiometrics();
        expect(bioShady.id, shady.id);

        await cubit.close();
        await device2Cubit.close();
      },
    );
  });
}
