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
          specialistAt: 'تمثيل وإخراج مسرحي (Acting & Directing)',
          committee: 'اللجنة الفنية والمسرح (Artistic Committee)',
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
          specialistAt: 'كتابة اسكريبت ودراما (Scriptwriting & Drama)',
          committee: 'لجنة التأليف والاسكريبت (Script Committee)',
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
          specialistAt: 'هندسة صوت وإضاءة مسرحية (Sound & Lighting)',
          committee: 'اللجنة التقنية والميديا (Technical & Media)',
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
          specialistAt: 'تمثيل وبانتومايم (Acting & Pantomime)',
          committee: 'اللجنة الفنية والمسرح (Artistic Committee)',
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
          specialistAt: 'سينوغرافيا وديكور مسرحي (Scenography & Decor)',
          committee: 'لجنة الديكور والاكسسوارات (Decor Committee)',
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
          specialistAt: 'تصوير ومونتاج (Photography & Video Editing)',
          committee: 'لجنة الميديا (Media Committee)',
        ),
      ];
}
