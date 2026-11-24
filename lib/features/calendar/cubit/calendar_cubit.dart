import 'dart:async';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/services/local_notification_service.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Calendar & Events feature module.
typedef CalendarCubit = LmtCubit;

/// Encapsulates Calendar Events CRUD (including multi-day events and nullable
/// Google Maps locations), automatic 1-day-before reminders for all members,
/// foreground/background Calendar reminder timers, and In-App notification sync.
mixin CalendarCubitMixin on LmtBaseCubit {
  final Map<String, Timer> _calendarReminderTimers = {};

  /// Cancels all active foreground calendar timers on Cubit disposal.
  void cancelCalendarTimers() {
    for (final timer in _calendarReminderTimers.values) {
      timer.cancel();
    }
    _calendarReminderTimers.clear();
  }

  /// Schedules OS reminders and foreground timers for all upcoming events
  /// (both custom reminders and automatic 1-day-before reminders).
  Future<void> scheduleAllCalendarNotifications() async {
    cancelCalendarTimers();
    for (final evt in state.calendarEvents) {
      await _scheduleBothEventReminders(evt);
    }
  }

  Future<void> _scheduleBothEventReminders(CalendarEventModel evt) async {
    final now = DateTime.now();

    // 1. Automatic 1-day-before reminder for ALL members (Calendar_Notifications)
    final oneDayBefore = evt.eventDateTime.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await LocalNotificationService.scheduleOneDayBeforeEventReminder(
        eventId: evt.id,
        title: evt.title,
        description: evt.description,
        location: evt.location,
        eventDateTime: evt.eventDateTime,
      );
      _scheduleForegroundTimer(
        key: '1day_${evt.id}',
        triggerAt: oneDayBefore,
        onFire: () => _emitDueOneDayBeforeNotification(evt, showOsBanner: false),
      );
    }

    // 2. Event custom reminder when active (Calendar_Notifications)
    if (evt.isReminderActive && evt.reminderDateTime != null) {
      final remAt = evt.reminderDateTime!;
      if (remAt.isAfter(now)) {
        await LocalNotificationService.scheduleEventReminder(
          eventId: evt.id,
          title: evt.title,
          description: evt.description,
          location: evt.location,
          reminderDateTime: remAt,
        );
        _scheduleForegroundTimer(
          key: 'rem_${evt.id}',
          triggerAt: remAt,
          onFire: () => _emitDueCustomReminderNotification(evt, showOsBanner: false),
        );
      }
    }
  }

  void _scheduleForegroundTimer({
    required String key,
    required DateTime triggerAt,
    required Future<void> Function() onFire,
  }) {
    _calendarReminderTimers[key]?.cancel();
    final delay = triggerAt.difference(DateTime.now());
    if (delay.isNegative || delay.inDays > 30) return;

    _calendarReminderTimers[key] = Timer(delay, () async {
      await onFire();
    });
  }

  /// Ensures any Calendar Reminder (custom or automatic 1-day-before) whose
  /// time has arrived is added into the in-app Notification screen (`NotificationScreen`)
  /// with deep-link navigation to the event.
  Future<void> syncDueCalendarReminders() async {
    final now = DateTime.now();
    bool changed = false;

    for (final evt in state.calendarEvents) {
      // Check automatic 1-day-before reminder (within [eventDateTime - 1d, eventDateTime + 2h])
      final oneDayBefore = evt.eventDateTime.subtract(const Duration(days: 1));
      final eventWindowEnd = evt.eventDateTime.add(const Duration(hours: 2));
      if (!oneDayBefore.isAfter(now) && now.isBefore(eventWindowEnd)) {
        final notifId = 'notif_1day_${evt.id}';
        if (!state.notifications.any((n) => n.id == notifId)) {
          await _emitDueOneDayBeforeNotification(
            evt,
            showOsBanner: true,
          );
          changed = true;
        }
      }

      // Check custom reminder
      if (evt.isReminderActive && evt.reminderDateTime != null) {
        final remAt = evt.reminderDateTime!;
        if (!remAt.isAfter(now) && now.isBefore(eventWindowEnd)) {
          final notifId = 'notif_rem_${evt.id}';
          if (!state.notifications.any((n) => n.id == notifId)) {
            await _emitDueCustomReminderNotification(
              evt,
              showOsBanner: true,
            );
            changed = true;
          }
        }
      }
    }

    if (changed) {
      await persistState();
    }
  }

  Future<void> _emitDueOneDayBeforeNotification(
    CalendarEventModel evt, {
    required bool showOsBanner,
  }) async {
    final hasLoc = evt.location != null && evt.location!.trim().isNotEmpty;
    pushNotification(
      id: 'notif_1day_${evt.id}',
      title: 'تذكير تلقائي قبل الموعد بيوم 🗓️🔔: ${evt.title}',
      description: hasLoc
          ? 'موعدنا غداً: ${evt.description} • المكان: ${evt.location!.trim()}'
          : 'موعدنا غداً: ${evt.description}',
      category: NotificationCategory.calendar,
      targetTabIndex: 3,
      targetEventId: evt.id,
      showOsBanner: showOsBanner,
    );
  }

  Future<void> _emitDueCustomReminderNotification(
    CalendarEventModel evt, {
    required bool showOsBanner,
  }) async {
    final hasLoc = evt.location != null && evt.location!.trim().isNotEmpty;
    pushNotification(
      id: 'notif_rem_${evt.id}',
      title: 'تذكير فعالية L.M.T 🗓️🔔: ${evt.title}',
      description: hasLoc
          ? '${evt.description} • المكان: ${evt.location!.trim()}'
          : evt.description,
      category: NotificationCategory.calendar,
      targetTabIndex: 3,
      targetEventId: evt.id,
      showOsBanner: showOsBanner,
    );
  }

  /// Adds a new calendar event and schedules both its custom reminder and
  /// automatic 1-day-before reminder for everyone.
  Future<void> addCalendarEvent({
    required String title,
    required String description,
    required DateTime eventDateTime,
    DateTime? endDateTime,
    DateTime? reminderDateTime,
    String? location,
    String category = 'Rehearsal / بروفة مسرح',
  }) async {
    if (!state.currentUser.role.canManageCalendar) return;

    final cleanedLocation =
        (location == null || location.trim().isEmpty) ? null : location.trim();

    final newEvent = CalendarEventModel(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      eventDateTime: eventDateTime,
      endDateTime: endDateTime,
      reminderDateTime:
          reminderDateTime ?? eventDateTime.subtract(const Duration(hours: 2)),
      isReminderActive: true,
      location: cleanedLocation,
      createdBy: state.currentUser.name,
      category: category,
    );

    final updatedEvents = [...state.calendarEvents, newEvent]
      ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

    final otherMemberIds = state.members
        .where((m) => m.id != state.currentUser.id)
        .map((m) => m.id)
        .toList();
    if (otherMemberIds.isNotEmpty) {
      pushNotification(
        title: 'فعالية جديدة في التقويم 🗓️',
        description: cleanedLocation != null
            ? '${newEvent.title} - المكان: $cleanedLocation'
            : newEvent.title,
        category: NotificationCategory.calendar,
        tone: LmtNotificationTone.calendar,
        targetTabIndex: 3,
        targetEventId: newEvent.id,
        targetMemberIds: otherMemberIds,
        excludedMemberIds: [state.currentUser.id],
      );
    }

    emit(state.copyWith(calendarEvents: updatedEvents));
    await _scheduleBothEventReminders(newEvent);
    await syncDueCalendarReminders();
    await persistState();
  }

  /// Updates an existing calendar event and reschedules its reminders.
  Future<void> updateCalendarEvent(CalendarEventModel updatedEvent) async {
    if (!state.currentUser.role.canManageCalendar) return;
    final updatedEvents = state.calendarEvents
        .map((e) => e.id == updatedEvent.id ? updatedEvent : e)
        .toList()
      ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

    await LocalNotificationService.cancelEventReminder(updatedEvent.id);
    _calendarReminderTimers.remove('rem_${updatedEvent.id}')?.cancel();
    _calendarReminderTimers.remove('1day_${updatedEvent.id}')?.cancel();

    emit(state.copyWith(calendarEvents: updatedEvents));
    await _scheduleBothEventReminders(updatedEvent);
    await syncDueCalendarReminders();
    await persistState();
  }

  /// Deletes a calendar event and cancels all scheduled reminders for it (Admin only).
  Future<void> deleteCalendarEvent(String eventId) async {
    if (!state.currentUser.role.canDeleteCalendar) return;
    await LocalNotificationService.cancelEventReminder(eventId);
    _calendarReminderTimers.remove('rem_$eventId')?.cancel();
    _calendarReminderTimers.remove('1day_$eventId')?.cancel();

    emit(
      state.copyWith(
        calendarEvents:
            state.calendarEvents.where((e) => e.id != eventId).toList(),
      ),
    );
    await persistState();
  }

  /// Toggles or updates a custom reminder time for an event (Admin & Editor only),
  /// ensuring both OS and in-app notifications reflect it using `Calendar_Notifications`.
  Future<void> toggleEventReminder(
    String eventId, {
    DateTime? customReminderTime,
  }) async {
    if (!state.currentUser.role.canManageCalendar) return;
    CalendarEventModel? targetUpdated;
    final updatedEvents = state.calendarEvents.map((e) {
      if (e.id != eventId) return e;
      final nextState =
          customReminderTime != null ? true : !e.isReminderActive;
      final updated = e.copyWith(
        isReminderActive: nextState,
        reminderDateTime: customReminderTime ??
            e.reminderDateTime ??
            e.eventDateTime.subtract(const Duration(hours: 2)),
      );
      targetUpdated = updated;
      return updated;
    }).toList();

    emit(state.copyWith(calendarEvents: updatedEvents));

    if (targetUpdated != null) {
      final evt = targetUpdated!;
      if (evt.isReminderActive && evt.reminderDateTime != null) {
        await _scheduleBothEventReminders(evt);
        final remAt = evt.reminderDateTime!;
        if (!remAt.isAfter(DateTime.now())) {
          await _emitDueCustomReminderNotification(evt, showOsBanner: true);
        } else {
          pushNotification(
            title: 'تم تفعيل تذكير الفعالية 🗓️🔔',
            description:
                'سيتم تذكيرك بـ "${evt.title}" تلقائياً في الموعد المحدد.',
            category: NotificationCategory.calendar,
            targetTabIndex: 3,
            targetEventId: evt.id,
          );
        }
      } else {
        _calendarReminderTimers.remove('rem_${evt.id}')?.cancel();
        await LocalNotificationService.cancelEventReminder(evt.id);
        await LocalNotificationService.scheduleOneDayBeforeEventReminder(
          eventId: evt.id,
          title: evt.title,
          description: evt.description,
          location: evt.location,
          eventDateTime: evt.eventDateTime,
        );
      }
    }

    await persistState();
  }
}
