import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Real Mobile Notification & Background Lock-Screen Reminder Service
/// Uses flutter_local_notifications with exactAllowWhileIdle alarms
/// so reminders & notifications fire even when the phone screen is locked or app is closed.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const AndroidNotificationDetails _androidChannelDetails =
      AndroidNotificationDetails(
    'lmt_custom_tone_channel_v1',
    'L.M.T App Notifications & Reminders',
    channelDescription:
        'تنبيهات وإشعارات وتذكيرات تقويم فريق الرسالة الاخيرة (L.M.T App)',
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('lmt_tone'),
    enableVibration: true,
    enableLights: true,
    fullScreenIntent: true,
    ticker: 'L.M.T App Notification',
    icon: '@drawable/ic_notification',
    largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
    color: Color(0xFF1E88E5),
  );

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'lmt_tone.wav',
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidChannelDetails,
    iOS: _iosDetails,
  );

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

      await _plugin.initialize(initSettings);

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
      }
      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService init error: $e');
    }
  }

  static int _stableIdFromString(String key) {
    return key.hashCode.abs() % 2147483647;
  }

  /// Displays a real mobile status-bar and lock-screen notification immediately
  static Future<void> showInstantNotification({
    required String idKey,
    required String title,
    required String body,
  }) async {
    try {
      await init();
      await _plugin.show(
        _stableIdFromString(idKey),
        title,
        body,
        _notificationDetails,
      );
    } catch (e) {
      debugPrint('showInstantNotification error: $e');
    }
  }

  /// Schedules a real OS alarm reminder that triggers even when the phone is locked or app is closed
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

      if (reminderDateTime.isAfter(now)) {
        final scheduledTz = tz.TZDateTime.from(reminderDateTime, tz.local);
        await _plugin.zonedSchedule(
          notifId,
          'تذكير فعالية L.M.T 🗓️: $title',
          bodyText,
          scheduledTz,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } else {
        // If reminder time is now or already reached, trigger immediately
        await showInstantNotification(
          idKey: 'evt_rem_$eventId',
          title: 'تذكير فعالية L.M.T 🗓️: $title',
          body: bodyText,
        );
      }
    } catch (e) {
      debugPrint('scheduleEventReminder error: $e');
    }
  }

  static Future<void> cancelEventReminder(String eventId) async {
    try {
      await init();
      final notifId = _stableIdFromString('evt_rem_$eventId');
      await _plugin.cancel(notifId);
    } catch (e) {
      debugPrint('cancelEventReminder error: $e');
    }
  }
}
