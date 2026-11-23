import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Member List Management feature module.
typedef MembersCubit = LmtCubit;

/// Encapsulates Member List CRUD and Role Authority operations (Admin & Editor).
mixin MembersCubitMixin on LmtBaseCubit {
  String _generateNextMemberId() {
    var maxSuffix = 0;
    final regex = RegExp(r'(\d+)$');
    for (final m in state.members) {
      final match = regex.firstMatch(m.id.trim());
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!) ?? 0;
        if (parsed > maxSuffix) {
          maxSuffix = parsed;
        }
      }
    }
    final nextIndex = maxSuffix + 1;
    return 'LMT-2026-${nextIndex.toString().padLeft(3, '0')}';
  }

  /// Adds a new team member respecting role-based permissions, username
  /// uniqueness, and minimum password length.
  ///
  /// Returns `null` on success or a localized validation/permission error.
  Future<String?> addMember({
    required String name,
    required String username,
    required String password,
    required UserRole role,
    required List<String> departments,
    required List<String> committees,
    required List<String> groups,
    bool isArabic = true,
  }) async {
    if (!state.currentUser.role.canCreateMembers) {
      return isArabic
          ? 'إنشاء حسابات جديدة متاح للمسؤول (Administrator) فقط.'
          : 'Only Administrators can create new member accounts.';
    }

    final cleanName = name.trim();
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanName.isEmpty) {
      return isArabic ? 'يرجى إدخال الاسم بالكامل.' : 'Full name is required.';
    }
    if (cleanUsername.length < 3) {
      return isArabic
          ? 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل.'
          : 'Username must be at least 3 characters.';
    }
    if (cleanPassword.length < 6) {
      return isArabic
          ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.'
          : 'Password must be at least 6 characters.';
    }

    final normalizedUsername = cleanUsername.toLowerCase();
    final usernameExists = state.members.any(
      (m) => m.username.trim().toLowerCase() == normalizedUsername,
    );
    if (usernameExists) {
      return isArabic
          ? 'اسم المستخدم ($cleanUsername) مستخدم بالفعل. يرجى اختيار اسم آخر.'
          : 'Username ($cleanUsername) is already taken. Choose another one.';
    }

    final effectiveRole =
        (state.currentUser.role == UserRole.editor && role == UserRole.admin)
            ? UserRole.editor
            : role;

    final newMember = MemberModel(
      id: _generateNextMemberId(),
      username: cleanUsername,
      password: cleanPassword,
      name: cleanName,
      role: effectiveRole,
      groups: groups.isEmpty ? const ['جروب الخلوة اليومية 🙏'] : groups,
      departments: departments.isEmpty
          ? [MemberModel.availableDepartments.first]
          : departments,
      committees: committees.isEmpty
          ? [MemberModel.availableCommittees.first]
          : committees,
    );

    final updatedMembers = [...state.members, newMember];
    final updatedGroups = state.chatGroups.map((g) {
      if (g.id == 'grp_khelwa' && !g.memberIds.contains(newMember.id)) {
        return g.copyWith(memberIds: [...g.memberIds, newMember.id]);
      }
      return g;
    }).toList();

    pushNotification(
      title: 'عضو جديد في الفريق 👤',
      description:
          'تمت إضافة ${newMember.name} (${newMember.id}) في ${newMember.committee}.',
      category: NotificationCategory.system,
      targetTabIndex: 4,
      excludedMemberIds: [state.currentUser.id],
    );

    emit(state.copyWith(members: updatedMembers, chatGroups: updatedGroups));
    await persistState();
    return null;
  }

  /// Resets an account's password (Admin only).
  Future<String?> resetMemberPassword({
    required String memberId,
    required String newPassword,
    bool isArabic = true,
  }) async {
    if (!state.currentUser.role.canDeleteMembers) {
      return isArabic
          ? 'إعادة تعيين كلمة المرور متاحة للمسؤول (Administrator) فقط.'
          : 'Resetting member passwords is restricted to Administrator only.';
    }

    final cleanPassword = newPassword.trim();
    if (cleanPassword.length < 6) {
      return isArabic
          ? 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل.'
          : 'New password must be at least 6 characters.';
    }

    final targetIndex = state.members.indexWhere((m) => m.id == memberId);
    if (targetIndex == -1) {
      return isArabic ? 'العضو غير موجود.' : 'Member not found.';
    }

    final updatedMember =
        state.members[targetIndex].copyWith(password: cleanPassword);
    final updatedMembers = List<MemberModel>.from(state.members);
    updatedMembers[targetIndex] = updatedMember;

    final updatedCurrentUser = state.currentUser.id == memberId
        ? updatedMember
        : state.currentUser;

    emit(
      state.copyWith(
        members: updatedMembers,
        currentUser: updatedCurrentUser,
      ),
    );
    await persistState();
    return null;
  }

  /// Changes a member's role if the current user has sufficient authority.
  Future<void> changeMemberRole({
    required String memberId,
    required UserRole newRole,
  }) async {
    final targetIndex = state.members.indexWhere((m) => m.id == memberId);
    if (targetIndex == -1) return;

    final targetMember = state.members[targetIndex];
    if (!state.currentUser.role.canChangeRoleTo(targetMember.role, newRole)) {
      return;
    }

    final updatedMember = targetMember.copyWith(role: newRole);
    final updatedMembers = List<MemberModel>.from(state.members);
    updatedMembers[targetIndex] = updatedMember;

    final updatedCurrentUser = state.currentUser.id == memberId
        ? updatedMember
        : state.currentUser;

    pushNotification(
      title: 'تحديث صلاحيات عضو ✍️',
      description:
          'تم تحديث صلاحية ${updatedMember.name} إلى ${newRole.shortLabel(true)}.',
      category: NotificationCategory.system,
      targetTabIndex: 4,
      targetMemberIds: [memberId],
      excludedMemberIds: state.currentUser.id == memberId
          ? [state.currentUser.id]
          : const [],
    );

    emit(
      state.copyWith(
        members: updatedMembers,
        currentUser: updatedCurrentUser,
      ),
    );
    await persistState();
  }

  /// Updates an existing member's profile details.
  ///
  /// Only [UserRole.admin] (`canEditDepartmentsAndCommittees`) is allowed to
  /// modify a member's [MemberModel.departments] (`القسم`) and
  /// [MemberModel.committees] (`اللجنة`).
  Future<void> updateMemberDetails(MemberModel updated) async {
    if (!state.currentUser.role.canManageMembers) return;
    final canEditDeptsAndComms =
        state.currentUser.role.canEditDepartmentsAndCommittees;

    final updatedMembers = state.members.map((m) {
      if (m.id != updated.id) return m;
      return canEditDeptsAndComms
          ? updated
          : updated.copyWith(
              departments: m.departments,
              committees: m.committees,
            );
    }).toList();

    final resolvedUpdated =
        updatedMembers.firstWhere((m) => m.id == updated.id);
    final updatedCurrentUser = state.currentUser.id == updated.id
        ? resolvedUpdated
        : state.currentUser;

    emit(
      state.copyWith(
        members: updatedMembers,
        currentUser: updatedCurrentUser,
      ),
    );
    await persistState();
  }

  /// Deletes a member (Admin only) and removes them from all group memberships.
  Future<void> deleteMember(String memberId) async {
    if (!state.currentUser.role.canDeleteMembers) return;
    if (memberId == state.currentUser.id) return;

    final updatedMembers =
        state.members.where((m) => m.id != memberId).toList();
    final updatedGroups = state.chatGroups.map((g) {
      if (!g.memberIds.contains(memberId)) return g;
      return g.copyWith(
        memberIds: g.memberIds.where((id) => id != memberId).toList(),
      );
    }).toList();

    emit(
      state.copyWith(
        members: updatedMembers,
        chatGroups: updatedGroups,
      ),
    );
    await persistState();
  }
}
