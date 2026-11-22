import 'package:equatable/equatable.dart';

/// Represents a scheduled team event, rehearsal, or multi-day trip in the L.M.T calendar.
class CalendarEventModel extends Equatable {
  /// The unique identifier of the event.
  final String id;

  /// The title of the event.
  final String title;

  /// Detailed description of the event.
  final String description;

  /// The scheduled start date and time of the event.
  final DateTime eventDateTime;

  /// Optional end date and time for multi-day events (e.g., a 5-day trip).
  final DateTime? endDateTime;

  /// Optional custom reminder date and time for local alarm scheduling.
  final DateTime? reminderDateTime;

  /// Whether the device alarm reminder is active for this event.
  final bool isReminderActive;

  /// Optional physical venue, address, or Google Maps location of the event.
  final String? location;

  /// The name of the member who created the event.
  final String createdBy;

  /// The category label of the event.
  final String category;

  /// Creates a [CalendarEventModel].
  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDateTime,
    this.endDateTime,
    this.reminderDateTime,
    this.isReminderActive = true,
    this.location,
    required this.createdBy,
    this.category = 'Rehearsal / بروفة مسرح',
  });

  /// Whether this event spans across multiple calendar days.
  bool get isMultiDay {
    if (endDateTime == null) return false;
    final startDay = DateTime(
      eventDateTime.year,
      eventDateTime.month,
      eventDateTime.day,
    );
    final endDay = DateTime(
      endDateTime!.year,
      endDateTime!.month,
      endDateTime!.day,
    );
    return endDay.isAfter(startDay);
  }

  /// Total inclusive number of days for this event (1 for single-day events).
  int get durationInDays {
    if (!isMultiDay) return 1;
    final startDay = DateTime(
      eventDateTime.year,
      eventDateTime.month,
      eventDateTime.day,
    );
    final endDay = DateTime(
      endDateTime!.year,
      endDateTime!.month,
      endDateTime!.day,
    );
    return endDay.difference(startDay).inDays + 1;
  }

  /// Returns `true` if this event occurs on [day] (inclusive of start and end days).
  bool occursOnDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final startDay = DateTime(
      eventDateTime.year,
      eventDateTime.month,
      eventDateTime.day,
    );
    if (!isMultiDay) {
      return target == startDay;
    }
    final endDay = DateTime(
      endDateTime!.year,
      endDateTime!.month,
      endDateTime!.day,
    );
    return !target.isBefore(startDay) && !target.isAfter(endDay);
  }

  /// Returns `true` if any day of this event falls within [year] and [month].
  bool occursInMonth(int year, int month) {
    if (!isMultiDay) {
      return eventDateTime.year == year && eventDateTime.month == month;
    }
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final startDay = DateTime(
      eventDateTime.year,
      eventDateTime.month,
      eventDateTime.day,
    );
    final endDay = DateTime(
      endDateTime!.year,
      endDateTime!.month,
      endDateTime!.day,
    );
    return !endDay.isBefore(monthStart) && !startDay.isAfter(monthEnd);
  }

  /// Whether a non-empty location is saved for this event.
  bool get hasLocation => location != null && location!.trim().isNotEmpty;

  /// Returns a Google Maps URL for the saved [location], or `null` if no location is set.
  String? get googleMapsUrl {
    if (!hasLocation) return null;
    final trimmed = location!.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}';
  }

  /// Creates a copy of this event with updated fields.
  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDateTime,
    DateTime? endDateTime,
    bool clearEndDateTime = false,
    DateTime? reminderDateTime,
    bool? isReminderActive,
    String? location,
    bool clearLocation = false,
    String? createdBy,
    String? category,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      endDateTime:
          clearEndDateTime ? null : (endDateTime ?? this.endDateTime),
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      isReminderActive: isReminderActive ?? this.isReminderActive,
      location: clearLocation ? null : (location ?? this.location),
      createdBy: createdBy ?? this.createdBy,
      category: category ?? this.category,
    );
  }

  /// Serializes this event to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'eventDateTime': eventDateTime.toIso8601String(),
        'endDateTime': endDateTime?.toIso8601String(),
        'reminderDateTime': reminderDateTime?.toIso8601String(),
        'isReminderActive': isReminderActive,
        'location': location,
        'createdBy': createdBy,
        'category': category,
      };

  /// Deserializes a [CalendarEventModel] from a JSON map.
  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    final rawLoc = (json['location'] as String?)?.trim();
    return CalendarEventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      eventDateTime:
          DateTime.tryParse(json['eventDateTime'] as String? ?? '') ??
              DateTime.now(),
      endDateTime: json['endDateTime'] != null
          ? DateTime.tryParse(json['endDateTime'] as String)
          : null,
      reminderDateTime: json['reminderDateTime'] != null
          ? DateTime.tryParse(json['reminderDateTime'] as String)
          : null,
      isReminderActive: json['isReminderActive'] as bool? ?? true,
      location: (rawLoc == null || rawLoc.isEmpty) ? null : rawLoc,
      createdBy: json['createdBy'] as String? ?? 'Mario Naiem',
      category: json['category'] as String? ?? 'Rehearsal / بروفة مسرح',
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        eventDateTime,
        endDateTime,
        reminderDateTime,
        isReminderActive,
        location,
        createdBy,
        category,
      ];
}
