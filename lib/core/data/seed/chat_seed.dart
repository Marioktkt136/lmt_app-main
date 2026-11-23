import '../../models/lmt_models.dart';
import '../../utils/app_assets.dart';

/// Default seed chat groups and initial messages for L.M.T.
///
/// Starts clean with only the dedicated Daily Khelwa group (`grp_khelwa`) and
/// the bootstrap administrator; new members are automatically added on creation.
class ChatSeed {
  ChatSeed._();

  /// Initial chat groups containing only the dedicated Daily Khelwa group (`grp_khelwa`).
  static List<ChatGroupModel> get initialGroups {
    final now = DateTime.now();
    return [
      ChatGroupModel(
        id: 'grp_khelwa',
        name: 'جروب الخلوة اليومية 🙏',
        description:
            'جروب مخصص لمتابعة الخلوة اليومية ونشر القائمة اليومية بأسماء من أخذوا الخلوة كل يوم',
        imagePath: AppAssets.prayIcon,
        memberIds: const ['LMT-2026-001'],
        adminId: 'LMT-2026-001',
        adminName: 'Mario Naiem',
        isPinned: true,
        createdAt: now,
      ),
    ];
  }

  /// Initial chat messages (empty for a clean production start).
  static List<ChatMessageModel> get initialMessages => const [];
}
