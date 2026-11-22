import '../../models/lmt_models.dart';
import '../../utils/app_assets.dart';

/// Default seed members for "The Last Message Team" (L.M.T).
class MembersSeed {
  MembersSeed._();

  /// Initial list of team members across Admin, Editor, and Member roles.
  static List<MemberModel> get initialMembers => const [
        MemberModel(
          id: 'LMT-2026-001',
          username: 'admin',
          password: 'password123',
          name: 'Mario Naiem',
          role: UserRole.admin,
          avatarPath: AppAssets.ktktProfileAvatar,
          groups: [
            'فريق الرسالة الاخيرة - العام',
            'بروفات مسرحية تغيروا 2026',
            'لجنة الاسكريبت والدراما',
            'لجنة الميديا والصوتيات',
          ],
          departments: ['إضاءة', 'مزيكا وميكسر'],
          committees: ['اللجنة الفنية', 'اللجنة الإدارية'],
        ),
        MemberModel(
          id: 'LMT-2026-002',
          username: 'editor',
          password: 'password123',
          name: 'Samy Farouk',
          role: UserRole.editor,
          avatarPath: AppAssets.samyProfileAvatar,
          groups: [
            'فريق الرسالة الاخيرة - العام',
            'بروفات مسرحية تغيروا 2026',
            'لجنة الاسكريبت والدراما',
          ],
          departments: ['ديكور', 'ملابس وإكسسوار'],
          committees: ['اللجنة الفنية', 'اللجنة العامة'],
        ),
        MemberModel(
          id: 'LMT-2026-003',
          username: 'mina',
          password: 'password123',
          name: 'Mina Adel',
          role: UserRole.editor,
          avatarPath: AppAssets.accountIcon,
          groups: [
            'فريق الرسالة الاخيرة - العام',
            'لجنة الميديا والصوتيات',
          ],
          departments: ['إضاءة', 'مزيكا وميكسر'],
          committees: ['اللجنة الفنية'],
        ),
        MemberModel(
          id: 'LMT-2026-004',
          username: 'member',
          password: 'password123',
          name: 'Marina Emad',
          role: UserRole.member,
          avatarPath: AppAssets.accountIcon,
          groups: [
            'فريق الرسالة الاخيرة - العام',
            'بروفات مسرحية تغيروا 2026',
          ],
          departments: ['ملابس وإكسسوار', 'ميك اب'],
          committees: ['اللجنة الفنية', 'اللجنة الروحية'],
        ),
        MemberModel(
          id: 'LMT-2026-005',
          username: 'karim',
          password: 'password123',
          name: 'Karim Youssef',
          role: UserRole.member,
          avatarPath: AppAssets.accountIcon,
          groups: [
            'فريق الرسالة الاخيرة - العام',
            'بروفات مسرحية تغيروا 2026',
          ],
          departments: ['ديكور', 'إضاءة'],
          committees: ['اللجنة الإدارية', 'اللجنة العامة'],
        ),
        MemberModel(
          id: 'LMT-2026-006',
          username: 'veronica',
          password: 'password123',
          name: 'Veronica Nabil',
          role: UserRole.member,
          avatarPath: AppAssets.accountIcon,
          groups: [
            'فريق الرسالة الاخيرة - العام',
            'لجنة الميديا والصوتيات',
          ],
          departments: ['ميك اب', 'ملابس وإكسسوار'],
          committees: ['اللجنة الروحية', 'اللجنة العامة'],
        ),
      ];
}
