import '../models/lmt_models.dart';
import 'seed/chat_seed.dart';
import 'seed/events_notifications_seed.dart';
import 'seed/members_seed.dart';
import 'seed/posts_seed.dart';
import 'seed/shared_files_seed.dart';

/// Facade providing default seed data for "The Last Message Team"
/// (`فريق الرسالة الاخيرة` - `L.M.T`).
///
/// Individual entity seed lists are organized into dedicated files under
/// `lib/core/data/seed/`.
class LmtSeedData {
  LmtSeedData._();

  /// Default annual slogan.
  static const String defaultSlogan = '#تغيروا_2026';

  /// Default annual Bible verse (Arabic).
  static const String defaultVerseAr =
      '«وَلاَ تُشَاكِلُوا هذَا الدَّهْرَ، بَلْ تَغَيَّرُوا عَنْ شَكْلِكُمْ بِتَجْدِيدِ أَذْهَانِكُمْ» (رو 12: 2)';

  /// Default annual Bible verse (English).
  static const String defaultVerseEn =
      '"Do not be conformed to this world, but be transformed by the renewal of your mind" (Romans 12:2)';

  /// Seeded team members.
  static List<MemberModel> get initialMembers => MembersSeed.initialMembers;

  /// Seeded chat groups.
  static List<ChatGroupModel> get initialGroups => ChatSeed.initialGroups;

  /// Seeded chat messages.
  static List<ChatMessageModel> get initialMessages => ChatSeed.initialMessages;

  /// Seeded timeline posts.
  static List<PostModel> get initialPosts => PostsSeed.initialPosts;

  /// Seeded shared files, documents, and cards.
  static List<SharedFileModel> get initialSharedFiles =>
      SharedFilesSeed.initialSharedFiles;

  /// Seeded calendar events.
  static List<CalendarEventModel> get initialEvents =>
      EventsNotificationsSeed.initialEvents;

  /// Seeded notifications.
  static List<AppNotificationModel> get initialNotifications =>
      EventsNotificationsSeed.initialNotifications;
}
