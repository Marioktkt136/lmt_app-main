import 'package:equatable/equatable.dart';

/// Categories of application notifications and reminders.
enum NotificationCategory {
  chat,
  calendar,
  files,
  posts,
  system;

  /// Parses a [NotificationCategory] from its string [value].
  static NotificationCategory fromString(String value) {
    return NotificationCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationCategory.system,
    );
  }
}

/// Represents an in-app notification item with deep-link navigation targets
/// and optional audience scoping (`targetMemberIds`).
class AppNotificationModel extends Equatable {
  /// The unique identifier of the notification.
  final String id;

  /// The headline title of the notification.
  final String title;

  /// The detailed body text of the notification.
  final String description;

  /// The timestamp when the notification was generated.
  final DateTime dateTime;

  /// The module category that triggered the notification.
  final NotificationCategory category;

  /// Whether the user has read this notification.
  final bool isRead;

  /// Optional layout tab index to navigate to when tapped.
  final int? targetTabIndex;

  /// Optional specific chat group ID to open when tapped.
  final String? targetGroupId;

  /// Optional specific calendar event ID to open when tapped.
  final String? targetEventId;

  /// Optional named route to push when tapped.
  final String? targetRoute;

  /// Optional list of member IDs allowed to see this notification.
  ///
  /// When empty, the notification is visible to all team members.
  final List<String> targetMemberIds;

  /// Creates an [AppNotificationModel].
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.category,
    this.isRead = false,
    this.targetTabIndex,
    this.targetGroupId,
    this.targetEventId,
    this.targetRoute,
    this.targetMemberIds = const [],
  });

  /// Returns `true` if [memberId] is authorized to see this notification.
  bool isVisibleTo(String memberId) =>
      targetMemberIds.isEmpty || targetMemberIds.contains(memberId);

  /// Creates a copy of this notification with updated fields.
  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    NotificationCategory? category,
    bool? isRead,
    int? targetTabIndex,
    String? targetGroupId,
    String? targetEventId,
    String? targetRoute,
    List<String>? targetMemberIds,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      targetTabIndex: targetTabIndex ?? this.targetTabIndex,
      targetGroupId: targetGroupId ?? this.targetGroupId,
      targetEventId: targetEventId ?? this.targetEventId,
      targetRoute: targetRoute ?? this.targetRoute,
      targetMemberIds: targetMemberIds ?? this.targetMemberIds,
    );
  }

  /// Serializes this notification to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dateTime': dateTime.toIso8601String(),
        'category': category.name,
        'isRead': isRead,
        'targetTabIndex': targetTabIndex,
        'targetGroupId': targetGroupId,
        'targetEventId': targetEventId,
        'targetRoute': targetRoute,
        'targetMemberIds': targetMemberIds,
      };

  /// Deserializes an [AppNotificationModel] from a JSON map.
  factory AppNotificationModel.fromJson(Map<String, dynamic> json) =>
      AppNotificationModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ??
            DateTime.now(),
        category: NotificationCategory.fromString(
            json['category'] as String? ?? 'system'),
        isRead: json['isRead'] as bool? ?? false,
        targetTabIndex: json['targetTabIndex'] as int?,
        targetGroupId: json['targetGroupId'] as String?,
        targetEventId: json['targetEventId'] as String?,
        targetRoute: json['targetRoute'] as String?,
        targetMemberIds: (json['targetMemberIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dateTime,
        category,
        isRead,
        targetTabIndex,
        targetGroupId,
        targetEventId,
        targetRoute,
        targetMemberIds,
      ];
}
