/// Member roles classified according to the L.M.T specification.
///
/// - [UserRole.admin]: Full authority to create, edit, and delete users, posts,
///   chat groups, calendar events, and shared files.
/// - [UserRole.editor]: Can create and edit posts, chat groups, calendar events,
///   and shared files, and edit non-admin member roles/details, but CANNOT
///   create users or delete users, posts, chat groups, events, or shared files.
/// - [UserRole.member]: View and interact only (chatting, reacting, liking,
///   commenting, voting in polls) without creating, editing, or deleting
///   structural resources.
enum UserRole {
  admin,
  editor,
  member;

  /// The emoji badge representing this role.
  String get badgeEmoji {
    switch (this) {
      case UserRole.admin:
        return '👨‍💻';
      case UserRole.editor:
        return '✍️';
      case UserRole.member:
        return '👤';
    }
  }

  /// Returns the full localized display label for this role.
  String label(bool isArabic) {
    switch (this) {
      case UserRole.admin:
        return isArabic ? 'مسؤول (Administrator) 👨‍💻' : 'Administrator 👨‍💻';
      case UserRole.editor:
        return isArabic ? 'محرر (Editor) ✍️' : 'Editor ✍️';
      case UserRole.member:
        return isArabic ? 'عضو (Member) 👤' : 'Member 👤';
    }
  }

  /// Returns the compact localized display label for this role.
  String shortLabel(bool isArabic) {
    switch (this) {
      case UserRole.admin:
        return isArabic ? 'مسؤول 👨‍💻' : 'Admin 👨‍💻';
      case UserRole.editor:
        return isArabic ? 'محرر ✍️' : 'Editor ✍️';
      case UserRole.member:
        return isArabic ? 'عضو 👤' : 'Member 👤';
    }
  }

  /// Whether this role has full unrestricted administrator privileges.
  bool get canDoAnything => this == UserRole.admin;

  /// Whether this role can create new member accounts (Administrator only).
  bool get canCreateMembers => this == UserRole.admin;

  /// Whether this role can open member account management to edit roles/info.
  bool get canManageMembers =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can permanently delete member accounts.
  bool get canDeleteMembers => this == UserRole.admin;

  /// Whether this role can assign or edit any member's departments (`القسم`)
  /// and committees (`اللجنة`). Restricted strictly to [UserRole.admin].
  bool get canEditDepartmentsAndCommittees => this == UserRole.admin;

  /// Whether this role can create or edit chatting groups.
  bool get canManageGroups =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can permanently delete chatting groups.
  bool get canDeleteGroups => this == UserRole.admin;

  /// Whether this role can upload or edit shared files and cards.
  bool get canManageFiles =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can permanently delete shared files and cards.
  bool get canDeleteFiles => this == UserRole.admin;

  /// Whether this role can create or edit calendar events.
  bool get canManageCalendar =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can permanently delete calendar events.
  bool get canDeleteCalendar => this == UserRole.admin;

  /// Whether this role can create or edit posts in the timeline.
  bool get canCreatePosts =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can edit existing posts in the timeline.
  bool get canEditPosts =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can permanently delete posts in the timeline.
  bool get canDeletePosts => this == UserRole.admin;

  /// Determines whether this role is authorized to change a member from
  /// [targetCurrentRole] to [newRole].
  bool canChangeRoleTo(UserRole targetCurrentRole, UserRole newRole) {
    if (this == UserRole.admin) return true;
    if (this == UserRole.editor) {
      if (targetCurrentRole == UserRole.admin) return false;
      return newRole == UserRole.editor || newRole == UserRole.member;
    }
    return false;
  }

  /// Parses a [UserRole] from its string [value].
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'editor':
        return UserRole.editor;
      default:
        return UserRole.member;
    }
  }
}
