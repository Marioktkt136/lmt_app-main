import '../models/lmt_models.dart';
import '../routes/routes.dart';
import '../utils/app_assets.dart';

/// Default Seed Data for "The Last Message Team" (فريق الرسالة الاخيرة - L.M.T)
class LmtSeedData {
  LmtSeedData._();

  static const String defaultSlogan = '#تغيروا_2026';
  static const String defaultVerseAr =
      '«وَلاَ تُشَاكِلُوا هذَا الدَّهْرَ، بَلْ تَغَيَّرُوا عَنْ شَكْلِكُمْ بِتَجْدِيدِ أَذْهَانِكُمْ» (رو 12: 2)';
  static const String defaultVerseEn =
      '"Do not be conformed to this world, but be transformed by the renewal of your mind" (Romans 12:2)';

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
      id: 'LMT-2026-003',
      username: 'mina',
      password: 'password123',
      name: 'Mina Adel',
      role: UserRole.editor,
      avatarPath: AppAssets.accountIcon,
      groups: ['فريق الرسالة الاخيرة - العام', 'لجنة الميديا والصوتيات'],
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
      groups: ['فريق الرسالة الاخيرة - العام', 'بروفات مسرحية تغيروا 2026'],
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
      groups: ['فريق الرسالة الاخيرة - العام', 'بروفات مسرحية تغيروا 2026'],
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
      groups: ['فريق الرسالة الاخيرة - العام', 'لجنة الميديا والصوتيات'],
      specialistAt: 'تصوير ومونتاج (Photography & Video Editing)',
      committee: 'لجنة الميديا (Media Committee)',
    ),
  ];

  static List<ChatGroupModel> get initialGroups {
    final now = DateTime.now();
    return [
      ChatGroupModel(
        id: 'grp_general',
        name: 'فريق الرسالة الاخيرة - العام 🎭',
        description: 'المجموعة الرسمية لكل أعضاء فريق L.M.T للتنسيق والإعلانات العامة',
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
        description: 'متابعة مواعيد البروفات، المشاهد، وتوزيع الأدوار المسرحية',
        imagePath: AppAssets.actIcon,
        memberIds: const ['LMT-2026-001', 'LMT-2026-002', 'LMT-2026-004', 'LMT-2026-005'],
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
        memberIds: const ['LMT-2026-001', 'LMT-2026-002', 'LMT-2026-004'],
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
        memberIds: const ['LMT-2026-001', 'LMT-2026-003', 'LMT-2026-006'],
        adminId: 'LMT-2026-003',
        adminName: 'Mina Adel',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ];
  }

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
        id: 'msg_3',
        groupId: 'grp_general',
        senderId: 'LMT-2026-003',
        senderName: 'Mina Adel',
        senderAvatar: AppAssets.accountIcon,
        senderRole: UserRole.editor,
        type: MessageType.voiceNote,
        content: 'تسجيل صوتي: شرح توزيع المايكات والمؤثرات الصوتية في المشهد التالت',
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
        content: 'جهزنا بلاي ليست المؤثرات الصوتية وخطة الإضاءة لعرض الجمعة الجاية 🎧💡',
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

  static List<PostModel> get initialPosts {
    final now = DateTime.now();
    return [
      PostModel(
        id: 'post_1',
        creatorId: 'LMT-2026-001',
        creatorName: 'Mario Naiem',
        creatorAvatar: AppAssets.ktktProfileAvatar,
        creatorRole: UserRole.admin,
        creatorCommittee: 'اللجنة الفنية والمسرح',
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
          PollOptionModel(id: 'opt_3', text: 'مش جاي للأسف (عندي عذر)', voterIds: []),
        ],
        likedByIds: const ['LMT-2026-001', 'LMT-2026-002', 'LMT-2026-004', 'LMT-2026-006'],
        comments: [
          PostCommentModel(
            id: 'cmt_1',
            authorId: 'LMT-2026-002',
            authorName: 'Samy Farouk',
            authorAvatar: AppAssets.samyProfileAvatar,
            authorRole: UserRole.editor,
            content: 'التجمع هيكون الساعة ٢:٣٠ ظهرًا علشان نراجع الإضاءة والديكور قبل العرض!',
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
        id: 'post_3',
        creatorId: 'LMT-2026-001',
        creatorName: 'Mario Naiem',
        creatorAvatar: AppAssets.ktktProfileAvatar,
        creatorRole: UserRole.admin,
        creatorCommittee: 'اللجنة الفنية والمسرح',
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

  static List<SharedFileModel> get initialSharedFiles {
    final now = DateTime.now();
    return [
      // Cards with Hyperlinks 🔗 & App Navigation
      SharedFileModel(
        id: 'file_card_scripts',
        title: 'اسكريبتات الفريق (Scripts Sheet)',
        description: 'جدول نصوص واسكريبتات عروض فريق الرسالة الاخيرة على Google Sheets',
        category: SharedFileType.card,
        imagePath: AppAssets.postIcon,
        fileExtension: 'LINK 🔗',
        fileSize: 'Google Sheets',
        externalUrl:
            'https://docs.google.com/spreadsheets/d/1OIzUep2K6-TXfmP-z6q3Fm_BfnXQOg3615n1cl3rrQs/edit?usp=sharing',
        uploadedBy: 'Mario Naiem',
        uploadedAt: now.subtract(const Duration(days: 14)),
      ),
      SharedFileModel(
        id: 'file_card_drive',
        title: 'درايف الفريق المشترك (L.M.T Drive)',
        description: 'مجلد Google Drive الرسمي للصور، التراكات الصوتية، والملفات المشتركة',
        category: SharedFileType.card,
        imagePath: AppAssets.driveIcon,
        fileExtension: 'LINK 🔗',
        fileSize: 'Google Drive',
        externalUrl:
            'https://drive.google.com/drive/folders/1Y3wdKNkWGBOb2Pw2CN-0XcIOHkSoJEyZ?usp=sharing',
        uploadedBy: 'Mario Naiem',
        uploadedAt: now.subtract(const Duration(days: 12)),
      ),
      SharedFileModel(
        id: 'file_card_form',
        title: 'فورم المتابعة والاقتراحات (Team Form)',
        description: 'نموذج تسجيل الحضور والاقتراحات الفنية لأعضاء الفريق',
        category: SharedFileType.card,
        imagePath: AppAssets.formIcon,
        fileExtension: 'LINK 🔗',
        fileSize: 'Google Form',
        externalUrl: 'https://forms.gle/ZYtUriGzQnqiYrVL6',
        uploadedBy: 'Samy Farouk',
        uploadedAt: now.subtract(const Duration(days: 10)),
      ),
      SharedFileModel(
        id: 'file_card_khelwa',
        title: 'الخلوة اليومية (Spiritual Khelwa)',
        description: 'متابعة وتسجيل الخلوة الروحية اليومية لأعضاء الفريق',
        category: SharedFileType.card,
        imagePath: AppAssets.prayIcon,
        fileExtension: 'APP 🔗',
        fileSize: 'Internal View',
        internalRoute: Routes.khelwa,
        uploadedBy: 'Mario Naiem',
        uploadedAt: now.subtract(const Duration(days: 10)),
      ),
      SharedFileModel(
        id: 'file_card_youtube',
        title: 'عروضنا على يوتيوب (YouTube Channel)',
        description: 'مكتبة الفيديوهات والعروض المسرحية لفريق الرسالة الاخيرة',
        category: SharedFileType.card,
        imagePath: AppAssets.youtubeIcon,
        fileExtension: 'VIDEO 🔗',
        fileSize: 'YouTube Gallery',
        internalRoute: Routes.youtube,
        uploadedBy: 'Veronica Nabil',
        uploadedAt: now.subtract(const Duration(days: 8)),
      ),

      // PDF Files
      SharedFileModel(
        id: 'file_pdf_1',
        title: 'اسكريبت مسرحية جبل نور - النسخة النهائية.pdf',
        description: 'النص المسرحي الكامل مع ملاحظات المخرج والإضاءة لجميع المشاهد',
        category: SharedFileType.pdf,
        imagePath: AppAssets.reviewIcon,
        fileExtension: 'PDF',
        fileSize: '2.4 MB',
        documentContent: '''
مسرحية: جبل نور (تغيروا 2026)
تأليف وإعداد: لجنة الاسكريبت - فريق الرسالة الاخيرة (L.M.T)
=====================================================

[المشهد الأول: ساحة المسرح - إضاءة خافتة زرقاء]
يدخل الراوي من يمين المسرح مع مؤثر صوتي هادئ...
الراوي: "في وسط الزحمة والأصوات الكتير، بتفضل رسالة واحدة بس هي اللي بتنور الطريق..."

[ملاحظات الإخراج]:
- دخول الممثلين من العمق بحركة تعبيرية بطيئة.
- رفع تدريجي لإضاءة الـ Spot على منتصف المسرح.
- تشغيل التراك الصوتي رقم (2) عند جملة النهاية.
''',
        uploadedBy: 'Samy Farouk',
        uploadedAt: now.subtract(const Duration(days: 4)),
      ),
      SharedFileModel(
        id: 'file_pdf_2',
        title: 'دليل التدريب المسرحي وفن التمثيل LMT.pdf',
        description: 'أساسيات التمثيل المسرحي، التحكم في الصوت، لغة الجسد، والبانتومايم',
        category: SharedFileType.pdf,
        imagePath: AppAssets.postIcon,
        fileExtension: 'PDF',
        fileSize: '3.8 MB',
        documentContent: '''
دليل الممثل المسرحي - فريق الرسالة الاخيرة (The Last Message Team)
1. التدريب الصوتي والتنفس الحجابي.
2. التركيز والتعبير الحركي على خشبة المسرح.
3. الالتزام بمواعيد البروفات وروح الفريق الواحد.
''',
        uploadedBy: 'Mario Naiem',
        uploadedAt: now.subtract(const Duration(days: 7)),
      ),

      // Word / Excel Files
      SharedFileModel(
        id: 'file_office_1',
        title: 'جدول_مواعيد_البروفات_والخدمات_2026.xlsx',
        description: 'شيت إكسيل بمواعيد البروفات الأسبوعية وتوزيع المهام واللجان',
        category: SharedFileType.wordExcel,
        imagePath: AppAssets.calendarIcon,
        fileExtension: 'XLSX',
        fileSize: '840 KB',
        documentContent: '''
جدول البروفات والخدمات - L.M.T 2026:
- الإثنين 6:30 م: قراءة اسكريبت وتدريب تمثيل
- الخميس 7:00 م: بروفة جنرال بالديكور والإضاءة
- الجمعة 4:00 م: خدمة وعرض مسرحي خارجي
''',
        uploadedBy: 'Mario Naiem',
        uploadedAt: now.subtract(const Duration(days: 3)),
      ),
      SharedFileModel(
        id: 'file_office_2',
        title: 'توزيع_الأدوار_والاكسسوارات_المسرحية.docx',
        description: 'ملف وورد يوضح أبطال كل مشهد ومستلزمات الديكور والملابس',
        category: SharedFileType.wordExcel,
        imagePath: AppAssets.formIcon,
        fileExtension: 'DOCX',
        fileSize: '1.1 MB',
        documentContent: '''
قائمة توزيع الأدوار والاكسسوارات:
- المشهد الأول: Mario Naiem, Marina Emad
- مسؤول الصوت والإضاءة: Mina Adel
- مسؤول الديكور والاكسسوارات: Karim Youssef
''',
        uploadedBy: 'Samy Farouk',
        uploadedAt: now.subtract(const Duration(days: 5)),
      ),

      // Paperwork
      SharedFileModel(
        id: 'file_paperwork_1',
        title: 'ورقة عمل وخطة الإخراج والإضاءة - المشهد الختامي',
        description: 'توجيهات حركة الممثلين (Blocking) وتوقيتات دخول الإضاءة والموسيقى',
        category: SharedFileType.paperwork,
        imagePath: AppAssets.reviewIcon,
        fileExtension: 'PAPERWORK',
        fileSize: '420 KB',
        documentContent: '''
ورقة عمل الإخراج المسرحي (Stage Blocking & Cues):
- Cue 1: إظلام تام (Blackout) لمدة ثانيتين.
- Cue 2: إضاءة دافئة على مقدمة المسرح مع دخول الكورال.
- Cue 3: عرض آية السنة #تغيروا_2026 على الخلفية.
''',
        uploadedBy: 'Mina Adel',
        uploadedAt: now.subtract(const Duration(days: 2)),
      ),

      // Images
      SharedFileModel(
        id: 'file_img_1',
        title: 'بوستر عرض مسرحية تغيروا 2026.png',
        description: 'التصميم الرسمي للبوستر الدعائي لعرض الفريق',
        category: SharedFileType.image,
        imagePath: AppAssets.actIcon,
        fileExtension: 'PNG',
        fileSize: '4.2 MB',
        uploadedBy: 'Veronica Nabil',
        uploadedAt: now.subtract(const Duration(days: 1)),
      ),
      SharedFileModel(
        id: 'file_img_2',
        title: 'شعار فريق الرسالة الاخيرة الرسمي (Logo HD).png',
        description: 'لوجو الفريق بجودة عالية للاستخدام في المطبوعات والميديا',
        category: SharedFileType.image,
        imagePath: AppAssets.appLogo,
        fileExtension: 'PNG',
        fileSize: '1.9 MB',
        uploadedBy: 'Veronica Nabil',
        uploadedAt: now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  static List<CalendarEventModel> get initialEvents {
    final now = DateTime.now();
    return [
      CalendarEventModel(
        id: 'evt_2',
        title: 'بروفة جنرال (صوت وإضاءة وديكور) 🎭💡',
        description:
            'بروفة كاملة بالملابس والاكسسوارات وتجربة المؤثرات الصوتية والإضاءة قبل العرض.',
        eventDateTime: DateTime(now.year, now.month, now.day + 3, 19, 0),
        reminderDateTime: DateTime(now.year, now.month, now.day + 3, 17, 0),
        isReminderActive: true,
        location: 'مسرح الفريق الرئيسي',
        createdBy: 'Mario Naiem',
        category: 'Rehearsal / بروفة جنرال',
      ),
      CalendarEventModel(
        id: 'evt_3',
        title: 'خدمة وعرض مسرحي في جمعية عين شمس 🌟',
        description: 'تقديم عرض مسرحية "جبل نور" وفقرة البانتومايم. التجمع الساعة ٢:٣٠ ظهرًا.',
        eventDateTime: DateTime(now.year, now.month, now.day + 5, 16, 0),
        reminderDateTime: DateTime(now.year, now.month, now.day + 5, 13, 0),
        isReminderActive: true,
        location: 'جمعية عين شمس - القاعة الكبرى',
        createdBy: 'Mario Naiem',
        category: 'Service / خدمة وعرض',
      ),
      CalendarEventModel(
        id: 'evt_4',
        title: 'يوم روحي وخلوة فريق الرسالة الاخيرة 🙏',
        description: 'يوم روحي، صلاة، ومشاركة حول شعار وآية السنة #تغيروا_2026.',
        eventDateTime: DateTime(now.year, now.month, now.day + 8, 10, 0),
        reminderDateTime: DateTime(now.year, now.month, now.day + 7, 21, 0),
        isReminderActive: false,
        location: 'بيت الخلوة - وادي النطرون',
        createdBy: 'Mario Naiem',
        category: 'Spiritual / يوم روحي',
      ),
      CalendarEventModel(
        id: 'evt_5',
        title: 'مهرجان المسرح القبطي وعرض "تغيروا 2026" الكبير 🎭🏆',
        description: 'العرض المسرحي الرئيسي للشهر القادم بحضور كل اللجان والفرق المشاركة.',
        eventDateTime: DateTime(now.year, now.month + 1, 12, 18, 0),
        reminderDateTime: DateTime(now.year, now.month + 1, 11, 18, 0),
        isReminderActive: true,
        location: 'المسرح الكبير - وسط البلد',
        createdBy: 'Mario Naiem',
        category: 'Service / عرض مسرحي',
      ),
    ];
  }

  static List<AppNotificationModel> get initialNotifications {
    final now = DateTime.now();
    return [
      AppNotificationModel(
        id: 'notif_1',
        title: 'رسالة جديدة في بروفات مسرحية تغيروا 2026 🎭',
        description: 'قام Samy Farouk بإرسال صورة كروكي حركة الممثلين للمشهد الافتتاحي.',
        dateTime: now.subtract(const Duration(minutes: 12)),
        category: NotificationCategory.chat,
        isRead: false,
        targetTabIndex: 1, // Chats Tab
        targetGroupId: 'grp_rehearsals',
      ),
      AppNotificationModel(
        id: 'notif_2',
        title: 'تذكير بالتقويم: قاعدة فنية وقراءة اسكريبت 🗓️',
        description: 'غداً الساعة 6:30 مساءً في قاعة المسرح الرئيسية - لا تتأخروا!',
        dateTime: now.subtract(const Duration(hours: 1)),
        category: NotificationCategory.calendar,
        isRead: false,
        targetTabIndex: 3, // Calendar Tab
      ),
      AppNotificationModel(
        id: 'notif_3',
        title: 'ملف PDF جديد في الملفات المشتركة 📄',
        description: 'تمت إضافة "اسكريبت مسرحية جبل نور - النسخة النهائية.pdf" بواسطة Samy Farouk.',
        dateTime: now.subtract(const Duration(hours: 3)),
        category: NotificationCategory.files,
        isRead: false,
        targetTabIndex: 2, // Shared Files Tab
      ),
      AppNotificationModel(
        id: 'notif_4',
        title: 'تفاعل جديد على منشورك ❤️',
        description: 'أعجب 4 أعضاء بمنشور استطلاع الرأي الخاص بخدمة جمعية عين شمس.',
        dateTime: now.subtract(const Duration(hours: 5)),
        category: NotificationCategory.posts,
        isRead: true,
        targetTabIndex: 0, // Posts Feed Tab
      ),
      AppNotificationModel(
        id: 'notif_5',
        title: 'تذكير الخلوة اليومية 🙏',
        description: 'لا تنسَ تسجيل خلوة اليوم في عداد الخلوة الخاص بفريق الرسالة الاخيرة.',
        dateTime: now.subtract(const Duration(days: 1)),
        category: NotificationCategory.system,
        isRead: true,
        targetRoute: Routes.khelwa,
      ),
    ];
  }
}
