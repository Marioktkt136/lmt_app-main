import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';

/// Date helpers shared by all calendar widgets.
///
/// Keeps day/month comparison and locale-aware formatting in one place so
/// widgets never duplicate it.
class CalendarDateUtils {
  CalendarDateUtils._();

  /// Whether [a] and [b] fall on the same calendar day.
  static bool isSameDay(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whether [a] and [b] fall in the same month of the same year.
  static bool isSameMonth(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month;

  /// Whether [day] is today.
  static bool isToday(DateTime day) => isSameDay(day, DateTime.now());

  /// Returns events whose date is on [day].
  static List<CalendarEventModel> eventsOnDay(
    Iterable<CalendarEventModel> events,
    DateTime day,
  ) =>
      events.where((e) => isSameDay(e.eventDateTime, day)).toList();

  /// Returns events whose date is in the month of [month].
  static List<CalendarEventModel> eventsInMonth(
    Iterable<CalendarEventModel> events,
    DateTime month,
  ) =>
      events.where((e) => isSameMonth(e.eventDateTime, month)).toList();

  /// Whether the active locale is Arabic.
  static bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  /// Formats [date] with [pattern] using the app's active locale.
  ///
  /// Falls back to the default locale if locale data is unavailable.
  static String format(BuildContext context, String pattern, DateTime date) {
    final lang = Localizations.localeOf(context).languageCode;
    try {
      return DateFormat(pattern, lang).format(date);
    } catch (_) {
      return DateFormat(pattern).format(date);
    }
  }
}
