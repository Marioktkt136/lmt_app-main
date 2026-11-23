import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Custom audio channels for L.M.T OS notifications.
enum LmtNotificationTone {
  /// Standard chime for posts, shared files, and general alerts.
  normal,

  /// Distinct chime for calendar events and scheduled event reminders.
  calendar,

  /// Custom chime (`chat_message_tone`) for incoming chat group messages.
  chatMessage,

  /// Custom chime (`post_interactions`) for likes and comments on user's posts.
  postInteractions,

  /// Custom chime (`message_reacts`) for emoji reactions on user's chat messages.
  messageReacts;

  /// Parses [value] or falls back cleanly when reading legacy stored notifications.
  static LmtNotificationTone fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LmtNotificationTone.normal;
    }
    for (final tone in LmtNotificationTone.values) {
      if (tone.name == value.trim()) return tone;
    }
    return LmtNotificationTone.normal;
  }
}

/// Real Mobile Notification & Background Lock-Screen Reminder Service for
/// both Android and iOS (`flutter_local_notifications`).
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Optional callback invoked when the user taps any OS notification banner.
  static void Function(String? payload)? onNotificationTapped;

  /// Stores a cold-start notification payload until the UI/Cubit listener attaches.
  static String? pendingLaunchPayload;

  static const String _normalChannelId = 'lmt_normal_notifications_v2';
  static const String _calendarChannelId = 'lmt_calendar_notifications_v2';
  static const String _chatMessageChannelId = 'lmt_chat_message_tone_v1';
  static const String _postInteractionsChannelId = 'lmt_post_interactions_v1';
  static const String _messageReactsChannelId = 'lmt_message_reacts_v1';

  static const AndroidNotificationDetails _normalAndroidDetails =
      AndroidNotificationDetails(
    _normalChannelId,
    'L.M.T Normal Notifications',
    channelDescription:
        'إشعارات المنشورات والملفات لفريق الرسالة الاخيرة (L.M.T App)',
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('normal_notifications'),
    enableVibration: true,
    enableLights: true,
    fullScreenIntent: false,
    ticker: 'L.M.T App Notification',
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
    color: Color(0xFF1E88E5),
  );

  static const AndroidNotificationDetails _calendarAndroidDetails =
      AndroidNotificationDetails(
    _calendarChannelId,
    'L.M.T Calendar & Reminders',
    channelDescription:
        'تذكيرات وإشعارات فعاليات التقويم التلقائية لفريق الرسالة الاخيرة (L.M.T App)',
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('calendar_notifications'),
    enableVibration: true,
    enableLights: true,
    fullScreenIntent: true,
    ticker: 'L.M.T Calendar Reminder',
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
    color: Color(0xFF1E88E5),
  );

  static const AndroidNotificationDetails _chatMessageAndroidDetails =
      AndroidNotificationDetails(
    _chatMessageChannelId,
    'L.M.T Chat Messages',
    channelDescription: 'نغمة إشعارات رسائل الشات في المجموعات (Chat_Message_Tone)',
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('chat_message_tone'),
    enableVibration: true,
    enableLights: true,
    fullScreenIntent: false,
    ticker: 'L.M.T Chat Message',
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
    color: Color(0xFF1E88E5),
  );

  static const AndroidNotificationDetails _postInteractionsAndroidDetails =
      AndroidNotificationDetails(
    _postInteractionsChannelId,
    'L.M.T Post Interactions',
    channelDescription:
        'نغمة إشعارات الإعجاب والتعليقات على منشوراتك (Post_Interactions)',
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('post_interactions'),
    enableVibration: true,
    enableLights: true,
    fullScreenIntent: false,
    ticker: 'L.M.T Post Interaction',
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
    color: Color(0xFF1E88E5),
  );

  static const AndroidNotificationDetails _messageReactsAndroidDetails =
      AndroidNotificationDetails(
    _messageReactsChannelId,
    'L.M.T Message Reactions',
    channelDescription:
        'نغمة إشعارات التفاعل بالإيموجي على رسائلك (Message_Reacts)',
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('message_reacts'),
    enableVibration: true,
    enableLights: true,
    fullScreenIntent: false,
    ticker: 'L.M.T Message React',
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
    color: Color(0xFF1E88E5),
  );

  static const DarwinNotificationDetails _normalIosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentBadge: true,
    presentSound: true,
    sound: 'normal_notifications.wav',
  );

  static const DarwinNotificationDetails _calendarIosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentBadge: true,
    presentSound: true,
    sound: 'calendar_notifications.wav',
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  static NotificationDetails _detailsFor(LmtNotificationTone tone) {
    switch (tone) {
      case LmtNotificationTone.calendar:
        return const NotificationDetails(
          android: _calendarAndroidDetails,
          iOS: _calendarIosDetails,
        );
      case LmtNotificationTone.chatMessage:
        return const NotificationDetails(
          android: _chatMessageAndroidDetails,
          iOS: _normalIosDetails,
        );
      case LmtNotificationTone.postInteractions:
        return const NotificationDetails(
          android: _postInteractionsAndroidDetails,
          iOS: _normalIosDetails,
        );
      case LmtNotificationTone.messageReacts:
        return const NotificationDetails(
          android: _messageReactsAndroidDetails,
          iOS: _normalIosDetails,
        );
      case LmtNotificationTone.normal:
        return const NotificationDetails(
          android: _normalAndroidDetails,
          iOS: _normalIosDetails,
        );
    }
  }

  /// Initializes notification channels on Android, permissions on iOS, and
  /// deep-link tap handlers for both foreground and cold-start launches.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      const androidInit =
          AndroidInitializationSettings('@drawable/ic_notification');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            pendingLaunchPayload = payload;
            onNotificationTapped?.call(payload);
          }
        },
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          pendingLaunchPayload = payload;
        }
      }

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();

        // Remove legacy cached channels so Android picks up the new dual channels
        await androidImpl.deleteNotificationChannel('lmt_high_importance_channel');
        await androidImpl.deleteNotificationChannel('lmt_custom_tone_channel_v1');

        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _normalChannelId,
            'L.M.T Normal Notifications',
            description:
                'إشعارات المحادثات والمنشورات والملفات لفريق الرسالة الاخيرة (L.M.T App)',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('normal_notifications'),
            enableVibration: true,
          ),
        );

        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _calendarChannelId,
            'L.M.T Calendar & Reminders',
            description:
                'تذكيرات وإشعارات فعاليات التقويم التلقائية لفريق الرسالة الاخيرة (L.M.T App)',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('calendar_notifications'),
            enableVibration: true,
          ),
        );

        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _chatMessageChannelId,
            'L.M.T Chat Messages',
            description:
                'نغمة إشعارات رسائل الشات في المجموعات (Chat_Message_Tone)',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('chat_message_tone'),
            enableVibration: true,
          ),
        );

        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _postInteractionsChannelId,
            'L.M.T Post Interactions',
            description:
                'نغمة إشعارات الإعجاب والتعليقات على منشوراتك (Post_Interactions)',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('post_interactions'),
            enableVibration: true,
          ),
        );

        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _messageReactsChannelId,
            'L.M.T Message Reactions',
            description:
                'نغمة إشعارات التفاعل بالإيموجي على رسائلك (Message_Reacts)',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('message_reacts'),
            enableVibration: true,
          ),
        );
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService init error: $e');
    }
  }

  static int _stableIdFromString(String key) {
    return key.hashCode.abs() % 2147483647;
  }

  /// Displays a real mobile status-bar / lock-screen notification immediately
  /// using either [LmtNotificationTone.normal] or [LmtNotificationTone.calendar].
  static Future<void> showInstantNotification({
    required String idKey,
    required String title,
    required String body,
    LmtNotificationTone tone = LmtNotificationTone.normal,
    Map<String, dynamic>? payloadData,
  }) async {
    try {
      await init();
      await _plugin.show(
        _stableIdFromString(idKey),
        title,
        body,
        _detailsFor(tone),
        payload: payloadData != null ? jsonEncode(payloadData) : null,
      );
    } catch (e) {
      debugPrint('showInstantNotification error: $e');
    }
  }

  /// Schedules the custom reminder alarm for a Calendar event using the
  /// `Calendar_Notifications` tone and deep-link event payload.
  static Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required String description,
    String? location,
    required DateTime reminderDateTime,
  }) async {
    try {
      await init();
      final notifId = _stableIdFromString('evt_rem_$eventId');
      await _plugin.cancel(notifId);

      final now = DateTime.now();
      final hasLoc = location != null && location.trim().isNotEmpty;
      final bodyText = hasLoc
          ? '$description • المكان: ${location.trim()}'
          : description;
      final payload = <String, dynamic>{
        'tab': 3,
        'eventId': eventId,
        'notifId': 'notif_rem_$eventId',
      };

      if (reminderDateTime.isAfter(now)) {
        final scheduledTz = tz.TZDateTime.from(reminderDateTime, tz.local);
        await _plugin.zonedSchedule(
          notifId,
          'تذكير فعالية L.M.T 🗓️: $title',
          bodyText,
          scheduledTz,
          _detailsFor(LmtNotificationTone.calendar),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: jsonEncode(payload),
        );
      }
    } catch (e) {
      debugPrint('scheduleEventReminder error: $e');
    }
  }

  /// Schedules the automatic 1-day-before reminder for ALL members of any event
  /// using the `Calendar_Notifications` tone and deep-link event payload.
  static Future<void> scheduleOneDayBeforeEventReminder({
    required String eventId,
    required String title,
    required String description,
    String? location,
    required DateTime eventDateTime,
  }) async {
    try {
      await init();
      final notifId = _stableIdFromString('evt_1day_$eventId');
      await _plugin.cancel(notifId);

      final oneDayBefore = eventDateTime.subtract(const Duration(days: 1));
      if (!oneDayBefore.isAfter(DateTime.now())) return;

      final hasLoc = location != null && location.trim().isNotEmpty;
      final bodyText = hasLoc
          ? 'موعدنا غداً: $description • المكان: ${location.trim()}'
          : 'موعدنا غداً: $description';
      final payload = <String, dynamic>{
        'tab': 3,
        'eventId': eventId,
        'notifId': 'notif_1day_$eventId',
      };

      final scheduledTz = tz.TZDateTime.from(oneDayBefore, tz.local);
      await _plugin.zonedSchedule(
        notifId,
        'تذكير تلقائي قبل الموعد بيوم 🗓️🔔: $title',
        bodyText,
        scheduledTz,
        _detailsFor(LmtNotificationTone.calendar),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('scheduleOneDayBeforeEventReminder error: $e');
    }
  }

  /// Cancels both the custom reminder and the automatic 1-day-before reminder
  /// for [eventId].
  static Future<void> cancelEventReminder(String eventId) async {
    try {
      await init();
      await _plugin.cancel(_stableIdFromString('evt_rem_$eventId'));
      await _plugin.cancel(_stableIdFromString('evt_1day_$eventId'));
    } catch (e) {
      debugPrint('cancelEventReminder error: $e');
    }
  }
}
