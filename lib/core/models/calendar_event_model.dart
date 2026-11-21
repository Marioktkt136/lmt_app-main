import 'package:equatable/equatable.dart';

/// Represents a scheduled team event or rehearsal in the L.M.T calendar.
class CalendarEventModel extends Equatable {
  /// The unique identifier of the event.
  final String id;

  /// The title of the event.
  final String title;

  /// Detailed description of the event.
  final String description;

  /// The scheduled date and time of the event.
  final DateTime eventDateTime;

  /// Optional custom reminder date and time for local alarm scheduling.
  final DateTime? reminderDateTime;

  /// Whether the device alarm reminder is active for this event.
  final bool isReminderActive;

  /// The physical venue or location of the event.
  final String location;

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
    this.reminderDateTime,
    this.isReminderActive = true,
    required this.location,
    required this.createdBy,
    this.category = 'Rehearsal / بروفة مسرح',
  });

  /// Creates a copy of this event with updated fields.
  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDateTime,
    DateTime? reminderDateTime,
    bool? isReminderActive,
    String? location,
    String? createdBy,
    String? category,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      isReminderActive: isReminderActive ?? this.isReminderActive,
      location: location ?? this.location,
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
        'reminderDateTime': reminderDateTime?.toIso8601String(),
        'isReminderActive': isReminderActive,
        'location': location,
        'createdBy': createdBy,
        'category': category,
      };

  /// Deserializes a [CalendarEventModel] from a JSON map.
  factory CalendarEventModel.fromJson(Map<String, dynamic> json) =>
      CalendarEventModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        eventDateTime:
            DateTime.tryParse(json['eventDateTime'] as String? ?? '') ??
                DateTime.now(),
        reminderDateTime: json['reminderDateTime'] != null
            ? DateTime.tryParse(json['reminderDateTime'] as String)
            : null,
        isReminderActive: json['isReminderActive'] as bool? ?? true,
        location: json['location'] as String? ?? '',
        createdBy: json['createdBy'] as String? ?? 'Mario Naiem',
        category: json['category'] as String? ?? 'Rehearsal / بروفة مسرح',
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        eventDateTime,
        reminderDateTime,
        isReminderActive,
        location,
        createdBy,
        category,
      ];
}
