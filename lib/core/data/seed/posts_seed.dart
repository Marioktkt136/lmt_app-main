import '../../models/lmt_models.dart';
import '../../utils/app_assets.dart';

/// Default seed timeline posts (Simple, Poll, and Media) for L.M.T.
class PostsSeed {
  PostsSeed._();

  /// Initial posts displayed in the Timeline Feed.
  static List<PostModel> get initialPosts {
    final now = DateTime.now();
    return [
      PostModel(
        id: 'post_1',
        creatorId: 'LMT-2026-001',
        creatorName: 'Mario Naiem',
        creatorAvatar: AppAssets.ktktProfileAvatar,
        creatorRole: UserRole.admin,
        creatorCommittee: 'اللجنة الفنية',
        publishTime: now.subtract(const Duration(days: 1, hours: 3)),
        type: PostCategoryType.poll,
        content:
            'عندنا خدمة وعرض مسرحي في جمعية عين شمس الجمعة الجاية الساعة ٤ العصر.. مين جاي معانا؟ 🎭🚌',
        pollOptions: const [
          PollOptionModel(
            id: 'opt_1',
            text: 'جاي أكيد إن شاء الله 🎭',
            voterIds: [
              'LMT-2026-001',
              'LMT-2026-002',
              'LMT-2026-003',
              'LMT-2026-004',
              'LMT-2026-006',
            ],
          ),
          PollOptionModel(
            id: 'opt_2',
            text: 'هحاول ألحق البروفة النهائية',
            voterIds: ['LMT-2026-005'],
          ),
          PollOptionModel(
            id: 'opt_3',
            text: 'مش جاي للأسف (عندي عذر)',
            voterIds: [],
          ),
        ],
        likedByIds: const [
          'LMT-2026-001',
          'LMT-2026-002',
          'LMT-2026-004',
          'LMT-2026-006',
        ],
        comments: [
          PostCommentModel(
            id: 'cmt_1',
            authorId: 'LMT-2026-002',
            authorName: 'Samy Farouk',
            authorAvatar: AppAssets.samyProfileAvatar,
            authorRole: UserRole.editor,
            content:
                'التجمع هيكون الساعة ٢:٣٠ ظهرًا علشان نراجع الإضاءة والديكور قبل العرض!',
            createdAt: now.subtract(const Duration(days: 1, hours: 1)),
          ),
          PostCommentModel(
            id: 'cmt_2',
            authorId: 'LMT-2026-004',
            authorName: 'Marina Emad',
            authorAvatar: AppAssets.accountIcon,
            authorRole: UserRole.member,
            content: 'معاكم بإذن الله، الملابس والاكسسوارات كلها جاهزة 👏',
            createdAt: now.subtract(const Duration(hours: 18)),
          ),
        ],
      ),
      PostModel(
        id: 'post_2',
        creatorId: 'LMT-2026-002',
        creatorName: 'Samy Farouk',
        creatorAvatar: AppAssets.samyProfileAvatar,
        creatorRole: UserRole.editor,
        creatorCommittee: 'اللجنة الفنية',
        publishTime: now.subtract(const Duration(days: 2, hours: 5)),
        type: PostCategoryType.simple,
        content:
            'مستنينكم يوم الأثنين الجاي الساعة ٦ ونص مساءً 🎬\nهيكون عندنا قاعدة فنية وقراءة كاملة لاسكريبت العرض الجديد وتوزيع المشاهد.. ما تتأخروش!',
        likedByIds: const [
          'LMT-2026-001',
          'LMT-2026-003',
          'LMT-2026-004',
          'LMT-2026-005',
        ],
        comments: [
          PostCommentModel(
            id: 'cmt_3',
            authorId: 'LMT-2026-003',
            authorName: 'Mina Adel',
            authorAvatar: AppAssets.accountIcon,
            authorRole: UserRole.editor,
            content: 'هجهز سماعة البروفة والمؤثرات الصوتية التجريبية للقراءة.',
            createdAt: now.subtract(const Duration(days: 2, hours: 2)),
          ),
        ],
      ),
      PostModel(
        id: 'post_3',
        creatorId: 'LMT-2026-001',
        creatorName: 'Mario Naiem',
        creatorAvatar: AppAssets.ktktProfileAvatar,
        creatorRole: UserRole.admin,
        creatorCommittee: 'اللجنة الفنية',
        publishTime: now.subtract(const Duration(days: 3)),
        type: PostCategoryType.media,
        content:
            'من كواليس وتجهيزات عروض فريق الرسالة الاخيرة (The Last Message Team) 🎭✨\nهدفنا توصيل الرسالة بكل إبداع في التمثيل والدراما والمسرح #تغيروا_2026',
        mediaPath: AppAssets.actIcon,
        isVideo: false,
        videoUrl: 'https://www.youtube.com',
        likedByIds: const [
          'LMT-2026-001',
          'LMT-2026-002',
          'LMT-2026-003',
          'LMT-2026-004',
          'LMT-2026-005',
          'LMT-2026-006',
        ],
        comments: const [],
      ),
    ];
  }
}
