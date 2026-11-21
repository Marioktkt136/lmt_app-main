import 'package:equatable/equatable.dart';

import '../utils/app_assets.dart';
import 'user_role.dart';

/// Represents a team member account in the L.M.T application.
class MemberModel extends Equatable {
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

  /// The artistic or technical specialty of the member.
  final String specialistAt;

  /// The team committee the member belongs to.
  final String committee;

  /// Creates a [MemberModel] instance.
  const MemberModel({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.avatarPath = AppAssets.accountIcon,
    required this.groups,
    required this.specialistAt,
    required this.committee,
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
    String? specialistAt,
    String? committee,
  }) {
    return MemberModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      groups: groups ?? this.groups,
      specialistAt: specialistAt ?? this.specialistAt,
      committee: committee ?? this.committee,
    );
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
        'specialistAt': specialistAt,
        'committee': committee,
      };

  /// Deserializes a [MemberModel] from a JSON map.
  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: json['id'] as String? ?? 'LMT-001',
        username: json['username'] as String? ?? 'member',
        password: json['password'] as String? ?? '12345678',
        name: json['name'] as String? ?? 'Member',
        role: UserRole.fromString(json['role'] as String? ?? 'member'),
        avatarPath: json['avatarPath'] as String? ?? AppAssets.accountIcon,
        groups: (json['groups'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        specialistAt: json['specialistAt'] as String? ?? 'Acting & Drama',
        committee: json['committee'] as String? ?? 'Artistic Committee',
      );

  @override
  List<Object?> get props => [
        id,
        username,
        password,
        name,
        role,
        avatarPath,
        groups,
        specialistAt,
        committee,
      ];
}
