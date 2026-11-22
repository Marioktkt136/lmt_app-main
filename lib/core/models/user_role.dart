/// Member roles classified according to the L.M.T specification.
///
/// - [UserRole.admin]: Can create, add, delete, and update any resource.
/// - [UserRole.editor]: Can manage member accounts, promote/demote between
///   [UserRole.member] and [UserRole.editor], and manage shared files, posts,
///   chatting groups, and calendar events.
/// - [UserRole.member]: Can view and interact with chats, shared files, posts,
///   and the calendar.
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

  /// Whether this role can create and edit member accounts.
  bool get canManageMembers =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can permanently delete member accounts.
  bool get canDeleteMembers => this == UserRole.admin;

  /// Whether this role can assign or edit any member's departments (`القسم`)
  /// and committees (`اللجنة`). Restricted strictly to [UserRole.admin].
  bool get canEditDepartmentsAndCommittees => this == UserRole.admin;

  /// Whether this role can create, update, or delete chatting groups.
  bool get canManageGroups =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can upload, update, or delete shared files and cards.
  bool get canManageFiles =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can create, update, or delete calendar events.
  bool get canManageCalendar =>
      this == UserRole.admin || this == UserRole.editor;

  /// Whether this role can publish posts in the timeline.
  bool get canCreatePosts => true;

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
