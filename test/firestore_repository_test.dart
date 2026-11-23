import 'package:flutter_test/flutter_test.dart';
import 'package:lmt/core/repositories/lmt_firestore_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'LmtFirestoreRepositoryImpl falls back cleanly to local cache when Firebase is not initialized',
    () async {
      final repo = LmtFirestoreRepositoryImpl();

      final initial = await repo.loadSnapshot();
      expect(initial.members, hasLength(1));
      expect(initial.members.single.id, 'LMT-2026-001');
      expect(initial.members.single.username, 'admin');
      expect(initial.chatGroups.map((g) => g.id), ['grp_khelwa']);
      expect(initial.posts, isEmpty);
      expect(initial.chatMessages, isEmpty);
      expect(initial.sharedFiles, isEmpty);
      expect(initial.calendarEvents, isEmpty);
      expect(initial.notifications, isEmpty);

      final updatedUser = initial.currentUser.copyWith(name: 'Updated Name');
      final updatedMembers = [
        updatedUser,
        ...initial.members.skip(1),
      ];

      await repo.persistSnapshot(
        stateJson: {
          'sloganOfYear': initial.sloganOfYear,
          'verseOfYear': initial.verseOfYear,
          'currentUser': updatedUser.toJson(),
          'members': updatedMembers.map((e) => e.toJson()).toList(),
          'chatGroups': initial.chatGroups.map((e) => e.toJson()).toList(),
          'chatMessages': initial.chatMessages.map((e) => e.toJson()).toList(),
          'posts': initial.posts.map((e) => e.toJson()).toList(),
          'sharedFiles': initial.sharedFiles.map((e) => e.toJson()).toList(),
          'calendarEvents':
              initial.calendarEvents.map((e) => e.toJson()).toList(),
          'notifications':
              initial.notifications.map((e) => e.toJson()).toList(),
        },
        currentUserId: updatedUser.id,
      );

      final reloaded = await repo.loadSnapshot();
      expect(reloaded.currentUser.name, 'Updated Name');
    },
  );
}
