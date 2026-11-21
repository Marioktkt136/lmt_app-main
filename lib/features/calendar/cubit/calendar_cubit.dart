import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/services/local_notification_service.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Calendar & Events feature module.
typedef CalendarCubit = LmtCubit;

/// Encapsulates Calendar Events CRUD and Exact Lock-Screen Reminder scheduling.
mixin CalendarCubitMixin on LmtBaseCubit {
  /// Adds a new calendar event and schedules its OS reminder notification.
  Future<void> addCalendarEvent({
    required String title,
    required String description,
    required DateTime eventDateTime,
    DateTime? reminderDateTime,
    required String location,
    String category = 'Rehearsal / بروفة مسرح',
  }) async {
    if (!state.currentUser.role.canManageCalendar) return;

    final newEvent = CalendarEventModel(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      eventDateTime: eventDateTime,
      reminderDateTime:
          reminderDateTime ?? eventDateTime.subtract(const Duration(hours: 2)),
      isReminderActive: true,
      location: location.trim(),
      createdBy: state.currentUser.name,
      category: category,
    );

    final updatedEvents = [...state.calendarEvents, newEvent]
      ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

    pushNotification(
      title: 'فعالية جديدة في التقويم 🗓️',
      description: '${newEvent.title} - المكان: ${newEvent.location}',
      category: NotificationCategory.calendar,
      targetTabIndex: 3,
    );

    if (newEvent.isReminderActive && newEvent.reminderDateTime != null) {
      await LocalNotificationService.scheduleEventReminder(
        eventId: newEvent.id,
        title: newEvent.title,
        description: newEvent.description,
        location: newEvent.location,
        reminderDateTime: newEvent.reminderDateTime!,
      );
    }

    emit(state.copyWith(calendarEvents: updatedEvents));
    await persistState();
  }

  /// Updates an existing calendar event and reschedules its reminder.
  Future<void> updateCalendarEvent(CalendarEventModel updatedEvent) async {
    if (!state.currentUser.role.canManageCalendar) return;
    final updatedEvents = state.calendarEvents
        .map((e) => e.id == updatedEvent.id ? updatedEvent : e)
        .toList()
      ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

    if (updatedEvent.isReminderActive && updatedEvent.reminderDateTime != null) {
      await LocalNotificationService.scheduleEventReminder(
        eventId: updatedEvent.id,
        title: updatedEvent.title,
        description: updatedEvent.description,
        location: updatedEvent.location,
        reminderDateTime: updatedEvent.reminderDateTime!,
      );
    } else {
      await LocalNotificationService.cancelEventReminder(updatedEvent.id);
    }

    emit(state.copyWith(calendarEvents: updatedEvents));
    await persistState();
  }

  /// Deletes a calendar event and cancels its scheduled reminder.
  Future<void> deleteCalendarEvent(String eventId) async {
    if (!state.currentUser.role.canManageCalendar) return;
    await LocalNotificationService.cancelEventReminder(eventId);
    emit(
      state.copyWith(
        calendarEvents:
            state.calendarEvents.where((e) => e.id != eventId).toList(),
      ),
    );
    await persistState();
  }

  /// Toggles or updates a custom reminder time for an event.
  Future<void> toggleEventReminder(
    String eventId, {
    DateTime? customReminderTime,
  }) async {
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

    if (targetUpdated != null) {
      if (targetUpdated!.isReminderActive &&
          targetUpdated!.reminderDateTime != null) {
        await LocalNotificationService.scheduleEventReminder(
          eventId: targetUpdated!.id,
          title: targetUpdated!.title,
          description: targetUpdated!.description,
          location: targetUpdated!.location,
          reminderDateTime: targetUpdated!.reminderDateTime!,
        );
        await LocalNotificationService.showInstantNotification(
          idKey:
              'confirm_${targetUpdated!.id}_${DateTime.now().millisecondsSinceEpoch}',
          title: 'تم تفعيل تذكير الفعالية 🔔',
          body:
              'سيتم تذكيرك بـ "${targetUpdated!.title}" حتى لو كان الهاتف مغلقاً.',
        );
      } else {
        await LocalNotificationService.cancelEventReminder(targetUpdated!.id);
      }
    }

    emit(state.copyWith(calendarEvents: updatedEvents));
    await persistState();
  }
}
