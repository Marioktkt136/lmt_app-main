import '../../models/lmt_models.dart';
import '../../routes/routes.dart';
import '../../utils/app_assets.dart';

/// Default seed shared files, documents, and hyperlink cards for L.M.T.
class SharedFilesSeed {
  SharedFilesSeed._();

  /// Initial shared files across Hyperlink Cards, PDFs, Word/Excel, Paperwork, and Images.
  static List<SharedFileModel> get initialSharedFiles {
    final now = DateTime.now();
    return [
      SharedFileModel(
        id: 'file_card_scripts',
        title: 'اسكريبتات الفريق (Scripts Sheet)',
        description:
            'جدول نصوص واسكريبتات عروض فريق الرسالة الاخيرة على Google Sheets',
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
        description:
            'مجلد Google Drive الرسمي للصور، التراكات الصوتية، والملفات المشتركة',
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
      SharedFileModel(
        id: 'file_pdf_1',
        title: 'اسكريبت مسرحية جبل نور - النسخة النهائية.pdf',
        description:
            'النص المسرحي الكامل مع ملاحظات المخرج والإضاءة لجميع المشاهد',
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
        description:
            'أساسيات التمثيل المسرحي، التحكم في الصوت، لغة الجسد، والبانتومايم',
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
      SharedFileModel(
        id: 'file_office_1',
        title: 'جدول_مواعيد_البروفات_والخدمات_2026.xlsx',
        description:
            'شيت إكسيل بمواعيد البروفات الأسبوعية وتوزيع المهام واللجان',
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
      SharedFileModel(
        id: 'file_paperwork_1',
        title: 'ورقة عمل وخطة الإخراج والإضاءة - المشهد الختامي',
        description:
            'توجيهات حركة الممثلين (Blocking) وتوقيتات دخول الإضاءة والموسيقى',
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
}
