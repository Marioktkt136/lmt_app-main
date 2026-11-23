import 'package:equatable/equatable.dart';

import '../utils/app_assets.dart';
import 'user_role.dart';

/// Represents a team member account in the L.M.T application.
class MemberModel extends Equatable {
  /// Official list of team departments (`القسم`).
  static const List<String> availableDepartments = [
    'ديكور',
    'إضاءة',
    'ملابس وإكسسوار',
    'مزيكا وميكسر',
    'ميك اب',
  ];

  /// Official list of team committees (`اللجنة`).
  static const List<String> availableCommittees = [
    'اللجنة الفنية',
    'اللجنة الإدارية',
    'اللجنة الروحية',
    'اللجنة العامة',
  ];

  /// The unique identifier of the member (e.g., `LMT-2026-001`).
  final String id;

  /// The login username of the member.
  final String username;

  /// The member's account password.
  final String password;

  /// The full display name of the member.
  final String name;

  /// The authorization role assigned to the member.
  final UserRole role;

  /// The asset or local file path for the member's profile avatar.
  final String avatarPath;

  /// The list of chatting group names the member belongs to.
  final List<String> groups;

  /// The list of team departments (`القسم`) assigned to the member.
  ///
  /// Each member can be assigned to one or more departments from
  /// [availableDepartments].
  final List<String> departments;

  /// The list of team committees (`اللجنة`) assigned to the member.
  ///
  /// Each member can be assigned to one or more committees from
  /// [availableCommittees].
  final List<String> committees;

  /// Formatted display string of all assigned departments (`القسم`).
  String get specialistAt =>
      departments.isEmpty ? availableDepartments.first : departments.join(' • ');

  /// Formatted display string of all assigned committees (`اللجنة`).
  String get committee =>
      committees.isEmpty ? availableCommittees.first : committees.join(' • ');

  /// Creates a [MemberModel] instance.
  const MemberModel({
    required this.id,
    required this.username,
    this.password = '',
    required this.name,
    required this.role,
    this.avatarPath = AppAssets.accountIcon,
    required this.groups,
    this.departments = const ['ديكور'],
    this.committees = const ['اللجنة الفنية'],
  });

  /// Creates a copy of this member with the given fields replaced.
  MemberModel copyWith({
    String? id,
    String? username,
    String? password,
    String? name,
    UserRole? role,
    String? avatarPath,
    List<String>? groups,
    List<String>? departments,
    List<String>? committees,
  }) {
    return MemberModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      groups: groups ?? this.groups,
      departments: departments ?? this.departments,
      committees: committees ?? this.committees,
    );
  }

  /// Verifies [inputPassword] strictly against this member's stored [password].
  bool verifyPassword(String inputPassword) {
    return password.isNotEmpty && password == inputPassword;
  }

  /// Serializes this member to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'password': password,
        'name': name,
        'role': role.name,
        'avatarPath': avatarPath,
        'groups': groups,
        'departments': departments,
        'committees': committees,
        'specialistAt': specialistAt,
        'committee': committee,
      };

  static List<String> _parseDepartments(
    Map<String, dynamic> json,
    String memberId,
  ) {
    final rawList = (json['departments'] as List<dynamic>?)
        ?.map((e) => e.toString().trim())
        .where((e) => availableDepartments.contains(e))
        .toList();
    if (rawList != null && rawList.isNotEmpty) {
      return rawList;
    }

    final rawSingle = (json['specialistAt'] as String? ?? '').trim();
    final matchedFromSingle = availableDepartments
        .where((dept) => rawSingle.contains(dept))
        .toList();
    if (matchedFromSingle.isNotEmpty) {
      return matchedFromSingle;
    }

    if (memberId == 'LMT-2026-001') {
      return const ['إضاءة', 'مزيكا وميكسر'];
    }
    return const ['ديكور'];
  }

  static List<String> _parseCommittees(
    Map<String, dynamic> json,
    String memberId,
  ) {
    final rawList = (json['committees'] as List<dynamic>?)
        ?.map((e) => e.toString().trim())
        .where((e) => availableCommittees.contains(e))
        .toList();
    if (rawList != null && rawList.isNotEmpty) {
      return rawList;
    }

    final rawSingle = (json['committee'] as String? ?? '').trim();
    final matchedFromSingle = availableCommittees
        .where((comm) => rawSingle.contains(comm))
        .toList();
    if (matchedFromSingle.isNotEmpty) {
      return matchedFromSingle;
    }

    if (memberId == 'LMT-2026-001') {
      return const ['اللجنة الفنية', 'اللجنة الإدارية'];
    }
    return const ['اللجنة الفنية'];
  }

  /// Deserializes a [MemberModel] from a JSON map.
  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? 'LMT-2026-001';
    return MemberModel(
      id: id,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      name: json['name'] as String? ?? 'Member',
      role: UserRole.fromString(json['role'] as String? ?? 'member'),
      avatarPath: json['avatarPath'] as String? ?? AppAssets.accountIcon,
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      departments: _parseDepartments(json, id),
      committees: _parseCommittees(json, id),
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        password,
        name,
        role,
        avatarPath,
        groups,
        departments,
        committees,
      ];
}
