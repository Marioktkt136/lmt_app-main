import 'dart:convert';

import '../data/lmt_seed_data.dart';
import '../models/lmt_models.dart';
import '../utils/app_preferences.dart';

/// Immutable data snapshot returned by [LmtRepository.loadSnapshot].
class LmtRepositorySnapshot {
  /// Whether biometric authentication is enabled.
  final bool biometricEnabled;

  /// The active slogan of the year.
  final String sloganOfYear;

  /// The active verse of the year.
  final String verseOfYear;

  /// The currently authenticated team member.
  final MemberModel currentUser;

  /// All registered team members.
  final List<MemberModel> members;

  /// All chatting groups.
  final List<ChatGroupModel> chatGroups;

  /// All chat messages across groups.
  final List<ChatMessageModel> chatMessages;

  /// All timeline posts.
  final List<PostModel> posts;

  /// All shared files, documents, and hyperlink cards.
  final List<SharedFileModel> sharedFiles;

  /// All scheduled calendar events.
  final List<CalendarEventModel> calendarEvents;

  /// All application notifications.
  final List<AppNotificationModel> notifications;

  /// Daily Khelwa check-in lists keyed by date (`yyyy-MM-dd`).
  final List<KhelwaDayModel> khelwaDays;

  /// Creates an [LmtRepositorySnapshot].
  const LmtRepositorySnapshot({
    required this.biometricEnabled,
    required this.sloganOfYear,
    required this.verseOfYear,
    required this.currentUser,
    required this.members,
    required this.chatGroups,
    required this.chatMessages,
    required this.posts,
    required this.sharedFiles,
    required this.calendarEvents,
    required this.notifications,
    this.khelwaDays = const [],
  });
}

/// Abstract repository contract for L.M.T data access and persistence.
///
/// Adheres to the Dependency Inversion Principle (SOLID) by decoupling
/// presentation state management from underlying storage mechanisms.
abstract class LmtRepository {
  /// Loads the persisted or initial seed snapshot of application data.
  Future<LmtRepositorySnapshot> loadSnapshot();

  /// Persists the serialized application state and active user ID.
  Future<void> persistSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  });

  /// Clears all cached state data and restores factory seed defaults.
  Future<void> clearCachedState();

  /// Publishes or clears the live typing indicator status for [member] in [groupId].
  Future<void> setGroupTypingStatus({
    required String groupId,
    required MemberModel member,
    required bool isTyping,
  }) async {}

  /// Streams active typing members inside [groupId].
  Stream<List<TypingMemberStatus>> watchGroupTyping(String groupId) =>
      const Stream.empty();

  /// Streams real-time notifications for multi-device Web & Mobile sync.
  Stream<List<AppNotificationModel>> watchNotifications() =>
      const Stream.empty();

  /// Streams live merged repository snapshots whenever any remote cloud
  /// collection updates, enabling real-time multi-device Auto-Sync.
  Stream<LmtRepositorySnapshot> watchLiveSnapshots() => const Stream.empty();

  /// Atomically records [memberId] / [memberName] in today's remote Khelwa day
  /// document (`khelwa_days/{dateKey}`) without overwriting concurrent check-ins.
  Future<void> recordKhelwaCheckIn({
    required String dateKey,
    required String memberId,
    required String memberName,
  }) async {}

  /// Clears all check-ins for [dateKey] across the database (Admin only).
  Future<void> resetKhelwaDay({required String dateKey}) async {}
}

/// Concrete local-first implementation of [LmtRepository].
class LmtLocalRepositoryImpl implements LmtRepository {
  /// Creates an [LmtLocalRepositoryImpl].
  const LmtLocalRepositoryImpl();

  @override
  Future<LmtRepositorySnapshot> loadSnapshot() async {
    final biometric = await AppPreferences.isBiometricEnabled();
    final savedSlogan = await AppPreferences.getSloganOfYear();
    final savedVerse = await AppPreferences.getVerseOfYear();
    final savedUserId = await AppPreferences.getCurrentUserId();
    final cachedJson = await AppPreferences.getCachedStateJson();

    List<MemberModel> members = LmtSeedData.initialMembers;
    List<ChatGroupModel> chatGroups = LmtSeedData.initialGroups;
    List<ChatMessageModel> chatMessages = LmtSeedData.initialMessages;
    List<PostModel> posts = LmtSeedData.initialPosts;
    List<SharedFileModel> sharedFiles = LmtSeedData.initialSharedFiles;
    List<CalendarEventModel> calendarEvents = LmtSeedData.initialEvents;
    List<AppNotificationModel> notifications = LmtSeedData.initialNotifications;
    List<KhelwaDayModel> khelwaDays = const [];
    MemberModel currentUser = members.first;

    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        if (decoded['members'] is List &&
            (decoded['members'] as List).isNotEmpty) {
          members = (decoded['members'] as List)
              .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['chatGroups'] is List &&
            (decoded['chatGroups'] as List).isNotEmpty) {
          chatGroups = (decoded['chatGroups'] as List)
              .map((e) => ChatGroupModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['chatMessages'] is List) {
          chatMessages = (decoded['chatMessages'] as List)
              .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['posts'] is List) {
          posts = (decoded['posts'] as List)
              .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['sharedFiles'] is List) {
          sharedFiles = (decoded['sharedFiles'] as List)
              .map((e) => SharedFileModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['calendarEvents'] is List) {
          calendarEvents = (decoded['calendarEvents'] as List)
              .map((e) =>
                  CalendarEventModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['notifications'] is List) {
          notifications = (decoded['notifications'] as List)
              .map((e) =>
                  AppNotificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['khelwaDays'] is List) {
          khelwaDays = (decoded['khelwaDays'] as List)
              .map((e) => KhelwaDayModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['currentUser'] is Map<String, dynamic>) {
          currentUser = MemberModel.fromJson(
            decoded['currentUser'] as Map<String, dynamic>,
          );
        }
      } catch (_) {
        // Fallback to seed data when schema evolves.
      }
    }

    final isLoggedIn = await AppPreferences.isLoggedIn();
    if (savedUserId != null && savedUserId.isNotEmpty) {
      final found = members.where((m) => m.id == savedUserId).toList();
      if (found.isNotEmpty) {
        currentUser = found.first;
      } else if (isLoggedIn) {
        await AppPreferences.clearLogin();
      }
    }

    return LmtRepositorySnapshot(
      biometricEnabled: biometric,
      sloganOfYear: savedSlogan ?? LmtSeedData.defaultSlogan,
      verseOfYear: savedVerse ?? LmtSeedData.defaultVerseAr,
      currentUser: currentUser,
      members: members,
      chatGroups: chatGroups,
      chatMessages: chatMessages,
      posts: posts,
      sharedFiles: sharedFiles,
      calendarEvents: calendarEvents,
      notifications: notifications,
      khelwaDays: khelwaDays,
    );
  }

  @override
  Future<void> persistSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {
    try {
      final encoded = jsonEncode(stateJson);
      await AppPreferences.setCachedStateJson(encoded);
      if (currentUserId.isNotEmpty) {
        await AppPreferences.setCurrentUserId(currentUserId);
      }
    } catch (_) {}
  }

  @override
  Future<void> clearCachedState() async {
    await AppPreferences.clearCachedState();
  }

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
}
