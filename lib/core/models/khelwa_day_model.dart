import 'package:equatable/equatable.dart';

/// Represents the team's daily Spiritual Khelwa attendance record for a
/// single calendar day (`yyyy-MM-dd`), synced across all devices in Cloud
/// Firestore (`khelwa_days/{dateKey}`).
class KhelwaDayModel extends Equatable {
  /// Document identifier matching [dateKey] (e.g. `2026-11-23`).
  final String id;

  /// Canonical calendar day string formatted `yyyy-MM-dd`.
  final String dateKey;

  /// Ordered member IDs of everyone who recorded Khelwa on [dateKey].
  final List<String> attendeeIds;

  /// Ordered display names matching [attendeeIds].
  final List<String> attendeeNames;

  /// Timestamp of the latest check-in or reset on this day.
  final DateTime updatedAt;

  /// Creates a [KhelwaDayModel].
  const KhelwaDayModel({
    required this.id,
    required this.dateKey,
    this.attendeeIds = const [],
    this.attendeeNames = const [],
    required this.updatedAt,
  });

  /// Formats [date] as `yyyy-MM-dd`.
  static String formatDateKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Parses [dateKey] (`yyyy-MM-dd`) into a midnight [DateTime], or `null`.
  DateTime? get parsedDate {
    final parts = dateKey.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Creates a copy with updated fields.
  KhelwaDayModel copyWith({
    String? id,
    String? dateKey,
    List<String>? attendeeIds,
    List<String>? attendeeNames,
    DateTime? updatedAt,
  }) {
    return KhelwaDayModel(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      attendeeNames: attendeeNames ?? this.attendeeNames,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes this record to JSON / Firestore document map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'attendeeIds': attendeeIds,
        'attendeeNames': attendeeNames,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserializes from JSON / Firestore document map.
  factory KhelwaDayModel.fromJson(Map<String, dynamic> json) {
    final dateKey = (json['dateKey'] as String? ?? json['id'] as String? ?? '')
        .trim();
    return KhelwaDayModel(
      id: (json['id'] as String? ?? dateKey).trim(),
      dateKey: dateKey,
      attendeeIds: (json['attendeeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      attendeeNames: (json['attendeeNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, dateKey, attendeeIds, attendeeNames, updatedAt];
}
