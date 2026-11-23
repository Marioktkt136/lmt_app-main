import '../../models/lmt_models.dart';

/// Default seed calendar events and notifications for L.M.T (clean start).
class EventsNotificationsSeed {
  EventsNotificationsSeed._();

  /// Initial calendar events (empty for real usage).
  static List<CalendarEventModel> get initialEvents => const [];

  /// Initial notifications (empty for real usage).
  static List<AppNotificationModel> get initialNotifications => const [];
}
