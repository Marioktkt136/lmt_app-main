import '../../models/lmt_models.dart';
import '../../utils/app_assets.dart';

/// Default seed chat groups and initial messages for L.M.T.
class ChatSeed {
  ChatSeed._();

  /// Initial chat groups including the dedicated Daily Khelwa group (`grp_khelwa`).
  static List<ChatGroupModel> get initialGroups {
    final now = DateTime.now();
    return [
      ChatGroupModel(
        id: 'grp_general',
        name: 'فريق الرسالة الاخيرة - العام 🎭',
        description:
            'المجموعة الرسمية لكل أعضاء فريق L.M.T للتنسيق والإعلانات العامة',
        imagePath: AppAssets.appLogo,
        memberIds: const [
          'LMT-2026-001',
          'LMT-2026-002',
          'LMT-2026-003',
          'LMT-2026-004',
          'LMT-2026-005',
          'LMT-2026-006',
        ],
        adminId: 'LMT-2026-001',
        adminName: 'Mario Naiem',
        isPinned: true,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      ChatGroupModel(
        id: 'grp_rehearsals',
        name: 'بروفات مسرحية تغيروا 2026 🎬',
        description:
            'متابعة مواعيد البروفات، المشاهد، وتوزيع الأدوار المسرحية',
        imagePath: AppAssets.actIcon,
        memberIds: const [
          'LMT-2026-001',
          'LMT-2026-002',
          'LMT-2026-004',
          'LMT-2026-005',
        ],
        adminId: 'LMT-2026-002',
        adminName: 'Samy Farouk',
        isPinned: true,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      ChatGroupModel(
        id: 'grp_scripts',
        name: 'لجنة الاسكريبت والدراما ✍️',
        description: 'كتابة ومراجعة النصوص المسرحية والاسكتشات الدرامية',
        imagePath: AppAssets.postIcon,
        memberIds: const [
          'LMT-2026-001',
          'LMT-2026-002',
          'LMT-2026-004',
        ],
        adminId: 'LMT-2026-002',
        adminName: 'Samy Farouk',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      ChatGroupModel(
        id: 'grp_khelwa',
        name: 'جروب الخلوة اليومية 🙏',
        description:
            'جروب مخصص لمتابعة الخلوة اليومية ونشر القائمة اليومية بأسماء من أخذوا الخلوة كل يوم',
        imagePath: AppAssets.prayIcon,
        memberIds: const [
          'LMT-2026-001',
          'LMT-2026-002',
          'LMT-2026-003',
          'LMT-2026-004',
          'LMT-2026-005',
          'LMT-2026-006',
        ],
        adminId: 'LMT-2026-001',
        adminName: 'Mario Naiem',
        isPinned: true,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      ChatGroupModel(
        id: 'grp_media',
        name: 'لجنة الميديا والصوتيات 🎧',
        description: 'المؤثرات الصوتية، تراكات المسرح، الإضاءة والتصوير',
        imagePath: AppAssets.videoIcon,
        memberIds: const [
          'LMT-2026-001',
          'LMT-2026-003',
          'LMT-2026-006',
        ],
        adminId: 'LMT-2026-003',
        adminName: 'Mina Adel',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ];
  }

  /// Initial chat messages across the seeded chat groups.
  static List<ChatMessageModel> get initialMessages {
    final now = DateTime.now();
    final defaultSeen = [
      SeenStatusModel(
        memberId: 'LMT-2026-001',
        memberName: 'Mario Naiem',
        avatarPath: AppAssets.ktktProfileAvatar,
        timestamp: now.subtract(const Duration(minutes: 45)),
        hasListened: true,
      ),
      SeenStatusModel(
        memberId: 'LMT-2026-002',
        memberName: 'Samy Farouk',
        avatarPath: AppAssets.samyProfileAvatar,
        timestamp: now.subtract(const Duration(minutes: 30)),
        hasListened: true,
      ),
      SeenStatusModel(
        memberId: 'LMT-2026-004',
        memberName: 'Marina Emad',
        avatarPath: AppAssets.accountIcon,
        timestamp: now.subtract(const Duration(minutes: 15)),
        hasListened: true,
      ),
    ];

    return [
      ChatMessageModel(
        id: 'msg_1',
        groupId: 'grp_general',
        senderId: 'LMT-2026-001',
        senderName: 'Mario Naiem',
        senderAvatar: AppAssets.ktktProfileAvatar,
        senderRole: UserRole.admin,
        type: MessageType.text,
        content:
            'مساء الخير يا فريق الرسالة الاخيرة 🎭✨\nبنفكركم إن شعار السنة دي #تغيروا_2026 وبروفة العرض الجاي يوم الإثنين الساعة 6:30 م.',
        reactions: const {
          '❤️': ['Samy Farouk', 'Marina Emad', 'Karim Youssef'],
          '🔥': ['Mina Adel', 'Veronica Nabil'],
        },
        seenBy: defaultSeen,
        sentAt: now.subtract(const Duration(hours: 4)),
      ),
      ChatMessageModel(
        id: 'msg_2',
        groupId: 'grp_general',
        senderId: 'LMT-2026-002',
        senderName: 'Samy Farouk',
        senderAvatar: AppAssets.samyProfileAvatar,
        senderRole: UserRole.editor,
        type: MessageType.file,
        content:
            'ده ملف اسكريبت مسرحية "جبل نور" بعد التعديل الأخير علشان الكل يراجعه قبل البروفة 📄',
        attachmentPath: 'اسكريبت_مسرحية_جبل_نور_2026.pdf',
        fileSize: '2.4 MB',
        replyToMessageId: 'msg_1',
        replyToSenderName: 'Mario Naiem',
        replyToPreview:
            'بنفكركم إن شعار السنة دي #تغيروا_2026 وبروفة العرض الجاي...',
        reactions: const {
          '👏': ['Mario Naiem', 'Marina Emad'],
        },
        seenBy: defaultSeen,
        sentAt: now.subtract(const Duration(hours: 3, minutes: 20)),
      ),
      ChatMessageModel(
        id: 'msg_3',
        groupId: 'grp_general',
        senderId: 'LMT-2026-003',
        senderName: 'Mina Adel',
        senderAvatar: AppAssets.accountIcon,
        senderRole: UserRole.editor,
        type: MessageType.voiceNote,
        content:
            'تسجيل صوتي: شرح توزيع المايكات والمؤثرات الصوتية في المشهد التالت',
        voiceDurationSeconds: 42,
        reactions: const {
          '👍': ['Mario Naiem', 'Samy Farouk'],
        },
        seenBy: defaultSeen,
        sentAt: now.subtract(const Duration(hours: 2)),
      ),
      ChatMessageModel(
        id: 'msg_4',
        groupId: 'grp_general',
        senderId: 'LMT-2026-004',
        senderName: 'Marina Emad',
        senderAvatar: AppAssets.accountIcon,
        senderRole: UserRole.member,
        type: MessageType.sticker,
        content: '🎭🔥 جاهزين للعرض!',
        attachmentPath: AppAssets.actIcon,
        seenBy: defaultSeen,
        sentAt: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),
      ChatMessageModel(
        id: 'msg_5',
        groupId: 'grp_rehearsals',
        senderId: 'LMT-2026-002',
        senderName: 'Samy Farouk',
        senderAvatar: AppAssets.samyProfileAvatar,
        senderRole: UserRole.editor,
        type: MessageType.image,
        content:
            'صورة كروكي حركة الممثلين على خشبة المسرح للمشهد الافتتاحي 🎬',
        attachmentPath: AppAssets.actIcon,
        reactions: const {
          '🔥': ['Mario Naiem', 'Karim Youssef'],
        },
        seenBy: defaultSeen,
        sentAt: now.subtract(const Duration(hours: 2, minutes: 30)),
      ),
      ChatMessageModel(
        id: 'msg_6',
        groupId: 'grp_scripts',
        senderId: 'LMT-2026-002',
        senderName: 'Samy Farouk',
        senderAvatar: AppAssets.samyProfileAvatar,
        senderRole: UserRole.editor,
        type: MessageType.text,
        content:
            'تم رفع مسودة الاسكتش الدرامي الجديد على شيت الاسكريبتات وفي قسم الملفات المشتركة.',
        seenBy: defaultSeen,
        sentAt: now.subtract(const Duration(hours: 5)),
      ),
      ChatMessageModel(
        id: 'msg_7',
        groupId: 'grp_media',
        senderId: 'LMT-2026-003',
        senderName: 'Mina Adel',
        senderAvatar: AppAssets.accountIcon,
        senderRole: UserRole.editor,
        type: MessageType.text,
        content:
            'جهزنا بلاي ليست المؤثرات الصوتية وخطة الإضاءة لعرض الجمعة الجاية 🎧💡',
        seenBy: defaultSeen,
        sentAt: now.subtract(const Duration(hours: 3)),
      ),
      ChatMessageModel(
        id: 'msg_khelwa_welcome',
        groupId: 'grp_khelwa',
        senderId: 'LMT-2026-001',
        senderName: 'Mario Naiem',
        senderAvatar: AppAssets.ktktProfileAvatar,
        senderRole: UserRole.admin,
        type: MessageType.text,
        content:
            '🙏 أهلاً بكم في جروب الخلوة اليومية لفريق الرسالة الاخيرة (L.M.T)\nفي نهاية كل يوم (وعند تسجيل الخلوة) يتم نشر وتحديث قائمة بأسماء الأعضاء الذين أخذوا الخلوة اليومية هنا لتشجيع بعضنا البعض 📖✨',
        seenBy: defaultSeen,
        sentAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }
}
