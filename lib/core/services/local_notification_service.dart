import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/auth/services/biometric_session_lock_controller.dart';
import 'web_notification_bridge.dart';

/// Custom audio channels for L.M.T OS & Web notifications.
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

  /// Bundled MP3 asset path used on Web browsers to play each custom tone.
  String get webAssetPath => switch (this) {
        LmtNotificationTone.normal =>
          'assets/notifications_tones/Normal_Notfications.mp3',
        LmtNotificationTone.calendar =>
          'assets/notifications_tones/Calendar_Reminder.mp3',
        LmtNotificationTone.chatMessage =>
          'assets/notifications_tones/Chat_Message_Tone.mp3',
        LmtNotificationTone.postInteractions =>
          'assets/notifications_tones/Post_Interactions.mp3',
        LmtNotificationTone.messageReacts =>
          'assets/notifications_tones/Message_Reacts.mp3',
      };

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

/// Payload emitted when a notification arrives in-app (especially on Web).
class ForegroundNotificationEvent {
  final String idKey;
  final String title;
  final String body;
  final LmtNotificationTone tone;
  final String? payload;

  const ForegroundNotificationEvent({
    required this.idKey,
    required this.title,
    required this.body,
    required this.tone,
    this.payload,
  });
}

/// Real Mobile & Web Notification + Scheduled Reminder Service across
/// Android, iOS (`flutter_local_notifications`), and Web Browsers.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Map<String, Timer> _webScheduledTimers = <String, Timer>{};
  static final StreamController<ForegroundNotificationEvent>
      _foregroundController =
      StreamController<ForegroundNotificationEvent>.broadcast();

  /// Broadcast stream of foreground notifications (used for rich Web banners).
  static Stream<ForegroundNotificationEvent> get foregroundStream =>
      _foregroundController.stream;

  /// Whether browser Desktop Notifications are supported on this runtime.
  static bool get isWebNotificationsSupported => WebNotificationBridge.isSupported;

  /// Current browser notification permission (`granted`, `denied`, `default`, `unsupported`).
  static String get webPermissionStatus => WebNotificationBridge.permissionStatus;

  /// Prompts the browser user (should be triggered from a user gesture on Web).
  static Future<String> requestWebPermission() =>
      WebNotificationBridge.requestPermission();

  /// Ensures browser Web Audio context is unlocked after a user tap/gesture.
  static Future<void> unlockWebAudioFromGesture() =>
      WebNotificationBridge.unlockFromUserGesture();

  /// Requests OS-level notification permission safely AFTER the Flutter Activity
  /// / browser gesture is active (fixes Android 13+ silent permission failures).
  static Future<bool> requestOsPermissions() async {
    if (kIsWeb) {
      final status = await WebNotificationBridge.requestPermission();
      return status == 'granted';
    }
    BiometricSessionLockController.instance.suppressNextResumeLock();
    try {
      await init();
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
        if (granted != null) return granted;
        return await androidImpl.areNotificationsEnabled() ?? true;
      }
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        return await iosImpl.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } catch (e) {
      debugPrint('requestOsPermissions error: $e');
      return false;
    }
  }

  /// Checks whether OS status-bar notifications are currently allowed.
  static Future<bool> areOsNotificationsEnabled() async {
    if (kIsWeb) {
      return WebNotificationBridge.permissionStatus == 'granted';
    }
    try {
      await init();
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? true;
      }
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final perms = await iosImpl.checkPermissions();
        return perms?.isEnabled ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Optional callback invoked when the user taps any OS notification banner.
  static void Function(String? payload)? onNotificationTapped;

  /// Stores a cold-start notification payload until the UI/Cubit listener attaches.
  static String? pendingLaunchPayload;

  static const String _normalChannelId = 'lmt_normal_notifications_v3';
  static const String _calendarChannelId = 'lmt_calendar_notifications_v3';
  static const String _chatMessageChannelId = 'lmt_chat_message_tone_v2';
  static const String _postInteractionsChannelId = 'lmt_post_interactions_v2';
  static const String _messageReactsChannelId = 'lmt_message_reacts_v2';

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
    audioAttributesUsage: AudioAttributesUsage.notification,
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
    audioAttributesUsage: AudioAttributesUsage.notification,
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
    audioAttributesUsage: AudioAttributesUsage.notification,
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
    audioAttributesUsage: AudioAttributesUsage.notification,
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
    audioAttributesUsage: AudioAttributesUsage.notification,
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
  /// browser support on Web cleanly without throwing on unsupported targets.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
    } catch (_) {}

    if (kIsWeb) {
      WebNotificationBridge.init(
        LmtNotificationTone.values.map((t) => t.webAssetPath),
      );
      _initialized = true;
      return;
    }

    try {
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
        // Delete legacy/cached channels so Android creates fresh channels with
        // intact raw sounds and AudioAttributesUsage.notification.
        for (final legacyId in const [
          'lmt_high_importance_channel',
          'lmt_custom_tone_channel_v1',
          'lmt_normal_notifications_v2',
          'lmt_calendar_notifications_v2',
          'lmt_chat_message_tone_v1',
          'lmt_post_interactions_v1',
          'lmt_message_reacts_v1',
        ]) {
          await androidImpl.deleteNotificationChannel(legacyId);
        }

        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _normalChannelId,
            'L.M.T Normal Notifications',
            description:
                'إشعارات المحادثات والمنشورات والملفات لفريق الرسالة الاخيرة (L.M.T App)',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('normal_notifications'),
            audioAttributesUsage: AudioAttributesUsage.notification,
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
            audioAttributesUsage: AudioAttributesUsage.notification,
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
            audioAttributesUsage: AudioAttributesUsage.notification,
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
            audioAttributesUsage: AudioAttributesUsage.notification,
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
            audioAttributesUsage: AudioAttributesUsage.notification,
            enableVibration: true,
          ),
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

  /// Displays a real mobile status-bar / lock-screen notification (or browser
  /// notification + custom MP3 chime on Web) using [tone].
  static Future<void> showInstantNotification({
    required String idKey,
    required String title,
    required String body,
    LmtNotificationTone tone = LmtNotificationTone.normal,
    Map<String, dynamic>? payloadData,
  }) async {
    final encodedPayload = payloadData != null ? jsonEncode(payloadData) : null;
    if (!_foregroundController.isClosed) {
      _foregroundController.add(
        ForegroundNotificationEvent(
          idKey: idKey,
          title: title,
          body: body,
          tone: tone,
          payload: encodedPayload,
        ),
      );
    }

    if (kIsWeb) {
      await WebNotificationBridge.showNotification(
        idKey: idKey,
        title: title,
        body: body,
        toneAssetPath: tone.webAssetPath,
        payload: encodedPayload,
        onTap: onNotificationTapped,
      );
      return;
    }

    try {
      await init();
      await _plugin.show(
        _stableIdFromString(idKey),
        title,
        body,
        _detailsFor(tone),
        payload: encodedPayload,
      );
    } catch (e) {
      debugPrint('showInstantNotification primary error, trying fallback: $e');
      try {
        await _plugin.show(
          _stableIdFromString(idKey),
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'lmt_fallback_alerts_v1',
              'L.M.T Alerts',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: _normalIosDetails,
          ),
          payload: encodedPayload,
        );
      } catch (e2) {
        debugPrint('showInstantNotification fallback error: $e2');
      }
    }
  }

  /// Unlocks audio (Web/iOS Safari), requests OS notification permission if
  /// missing, and immediately fires a test notification using [tone].
  static Future<bool> testToneAndAlert({
    LmtNotificationTone tone = LmtNotificationTone.chatMessage,
    required String title,
    required String body,
  }) async {
    await unlockWebAudioFromGesture();
    final granted = await requestOsPermissions();
    await showInstantNotification(
      idKey: 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      tone: tone,
    );
    return granted;
  }

  static void _scheduleWebTimer({
    required String timerKey,
    required DateTime scheduledAt,
    required String idKey,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) {
    _webScheduledTimers.remove(timerKey)?.cancel();
    final diff = scheduledAt.difference(DateTime.now());
    // Avoid 32-bit JS timer overflow (~24.8 days max).
    if (diff <= Duration.zero || diff > const Duration(days: 20)) return;
    _webScheduledTimers[timerKey] = Timer(diff, () {
      _webScheduledTimers.remove(timerKey);
      showInstantNotification(
        idKey: idKey,
        title: title,
        body: body,
        tone: LmtNotificationTone.calendar,
        payloadData: payload,
      );
    });
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
    final now = DateTime.now();
    final hasLoc = location != null && location.trim().isNotEmpty;
    final bodyText =
        hasLoc ? '$description • المكان: ${location.trim()}' : description;
    final payload = <String, dynamic>{
      'tab': 3,
      'eventId': eventId,
      'notifId': 'notif_rem_$eventId',
    };
    final notifTitle = 'تذكير فعالية L.M.T 🗓️: $title';

    if (kIsWeb) {
      if (reminderDateTime.isAfter(now)) {
        _scheduleWebTimer(
          timerKey: 'evt_rem_$eventId',
          scheduledAt: reminderDateTime,
          idKey: 'notif_rem_$eventId',
          title: notifTitle,
          body: bodyText,
          payload: payload,
        );
      }
      return;
    }

    try {
      await init();
      final notifId = _stableIdFromString('evt_rem_$eventId');
      await _plugin.cancel(notifId);

      if (reminderDateTime.isAfter(now)) {
        final scheduledTz = tz.TZDateTime.from(reminderDateTime, tz.local);
        await _plugin.zonedSchedule(
          notifId,
          notifTitle,
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
    final notifTitle = 'تذكير تلقائي قبل الموعد بيوم 🗓️🔔: $title';

    if (kIsWeb) {
      _scheduleWebTimer(
        timerKey: 'evt_1day_$eventId',
        scheduledAt: oneDayBefore,
        idKey: 'notif_1day_$eventId',
        title: notifTitle,
        body: bodyText,
        payload: payload,
      );
      return;
    }

    try {
      await init();
      final notifId = _stableIdFromString('evt_1day_$eventId');
      await _plugin.cancel(notifId);

      final scheduledTz = tz.TZDateTime.from(oneDayBefore, tz.local);
      await _plugin.zonedSchedule(
        notifId,
        notifTitle,
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
    _webScheduledTimers.remove('evt_rem_$eventId')?.cancel();
    _webScheduledTimers.remove('evt_1day_$eventId')?.cancel();
    if (kIsWeb) return;

    try {
      await init();
      await _plugin.cancel(_stableIdFromString('evt_rem_$eventId'));
      await _plugin.cancel(_stableIdFromString('evt_1day_$eventId'));
    } catch (e) {
      debugPrint('cancelEventReminder error: $e');
    }
  }
}
