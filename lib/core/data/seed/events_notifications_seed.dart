import '../../models/lmt_models.dart';
import '../../routes/routes.dart';

/// Default seed calendar events and notifications for L.M.T.
class EventsNotificationsSeed {
  EventsNotificationsSeed._();

  /// Initial calendar events spanning the current and upcoming months.
  static List<CalendarEventModel> get initialEvents {
    final now = DateTime.now();
    return [
      CalendarEventModel(
        id: 'evt_1',
        title: 'قاعدة فنية وقراءة اسكريبت العرض الجديد 🎬',
        description:
            'مراجعة النص المسرحي الجديد وتوزيع الأدوار على الأعضاء ومناقشة رؤية الإخراج.',
        eventDateTime: DateTime(now.year, now.month, now.day + 1, 18, 30),
        reminderDateTime: DateTime(now.year, now.month, now.day + 1, 16, 30),
        isReminderActive: true,
        location: 'قاعة المسرح الرئيسية - الدور الثاني',
        createdBy: 'Samy Farouk',
        category: 'Rehearsal / بروفة مسرح',
      ),
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
        description:
            'تقديم عرض مسرحية "جبل نور" وفقرة البانتومايم. التجمع الساعة ٢:٣٠ ظهرًا.',
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
        description:
            'يوم روحي، صلاة، ومشاركة حول شعار وآية السنة #تغيروا_2026.',
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
        description:
            'العرض المسرحي الرئيسي للشهر القادم بحضور كل اللجان والفرق المشاركة.',
        eventDateTime: DateTime(now.year, now.month + 1, 12, 18, 0),
        reminderDateTime: DateTime(now.year, now.month + 1, 11, 18, 0),
        isReminderActive: true,
        location: 'المسرح الكبير - وسط البلد',
        createdBy: 'Mario Naiem',
        category: 'Service / عرض مسرحي',
      ),
      CalendarEventModel(
        id: 'evt_6',
        title: 'ورشة إعداد الممثل والكتابة الدرامية ✍️🎬',
        description:
            'تدريب مكثف لأعضاء الفريق الجدد على التمثيل، الإلقاء، والسينوغرافيا.',
        eventDateTime: DateTime(now.year, now.month + 2, 5, 17, 0),
        reminderDateTime: DateTime(now.year, now.month + 2, 4, 17, 0),
        isReminderActive: true,
        location: 'قاعة التدريب المسرحي - L.M.T',
        createdBy: 'Samy Farouk',
        category: 'Workshop / ورشة فنية',
      ),
    ];
  }

  /// Initial notifications displayed in the Notification Screen.
  static List<AppNotificationModel> get initialNotifications {
    final now = DateTime.now();
    return [
      AppNotificationModel(
        id: 'notif_1',
        title: 'رسالة جديدة في بروفات مسرحية تغيروا 2026 🎭',
        description:
            'قام Samy Farouk بإرسال صورة كروكي حركة الممثلين للمشهد الافتتاحي.',
        dateTime: now.subtract(const Duration(minutes: 12)),
        category: NotificationCategory.chat,
        isRead: false,
        targetTabIndex: 1,
        targetGroupId: 'grp_rehearsals',
      ),
      AppNotificationModel(
        id: 'notif_2',
        title: 'تذكير بالتقويم: قاعدة فنية وقراءة اسكريبت 🗓️',
        description:
            'غداً الساعة 6:30 مساءً في قاعة المسرح الرئيسية - لا تتأخروا!',
        dateTime: now.subtract(const Duration(hours: 1)),
        category: NotificationCategory.calendar,
        isRead: false,
        targetTabIndex: 3,
      ),
      AppNotificationModel(
        id: 'notif_3',
        title: 'ملف PDF جديد في الملفات المشتركة 📄',
        description:
            'تمت إضافة "اسكريبت مسرحية جبل نور - النسخة النهائية.pdf" بواسطة Samy Farouk.',
        dateTime: now.subtract(const Duration(hours: 3)),
        category: NotificationCategory.files,
        isRead: false,
        targetTabIndex: 2,
      ),
      AppNotificationModel(
        id: 'notif_4',
        title: 'تفاعل جديد على منشورك ❤️',
        description:
            'أعجب 4 أعضاء بمنشور استطلاع الرأي الخاص بخدمة جمعية عين شمس.',
        dateTime: now.subtract(const Duration(hours: 5)),
        category: NotificationCategory.posts,
        isRead: true,
        targetTabIndex: 0,
      ),
      AppNotificationModel(
        id: 'notif_5',
        title: 'تذكير الخلوة اليومية 🙏',
        description:
            'لا تنسَ تسجيل خلوة اليوم في عداد الخلوة الخاص بفريق الرسالة الاخيرة.',
        dateTime: now.subtract(const Duration(days: 1)),
        category: NotificationCategory.system,
        isRead: true,
        targetRoute: Routes.khelwa,
      ),
    ];
  }
}
