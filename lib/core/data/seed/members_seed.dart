import '../../models/lmt_models.dart';
import '../../utils/app_assets.dart';

/// Default seed members for "The Last Message Team" (L.M.T).
///
/// Starts clean with only the primary Administrator bootstrap account so the
/// team admin can create and manage real member accounts from within the app.
class MembersSeed {
  MembersSeed._();

  /// Initial member list containing only the primary Administrator account.
  static List<MemberModel> get initialMembers => [
        MemberModel(
          id: 'LMT-2026-001',
          username: 'admin',
          password: 'password123',
          name: 'Mario Naiem',
          role: UserRole.admin,
          avatarPath: AppAssets.ktktProfileAvatar,
          groups: const ['جروب الخلوة اليومية 🙏'],
          departments: const ['إضاءة', 'مزيكا وميكسر'],
          committees: const ['اللجنة الفنية', 'اللجنة الإدارية'],
        ),
      ];
}
