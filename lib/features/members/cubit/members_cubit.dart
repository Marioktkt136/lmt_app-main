import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Member List Management feature module.
typedef MembersCubit = LmtCubit;

/// Encapsulates Member List CRUD and Role Authority operations (Admin & Editor).
mixin MembersCubitMixin on LmtBaseCubit {
  /// Adds a new team member respecting role-based permissions.
  Future<void> addMember({
    required String name,
    required String username,
    required String password,
    required UserRole role,
    required List<String> departments,
    required List<String> committees,
    required List<String> groups,
  }) async {
    if (!state.currentUser.role.canManageMembers) return;

    final effectiveRole =
        (state.currentUser.role == UserRole.editor && role == UserRole.admin)
            ? UserRole.editor
            : role;

    final nextIndex = state.members.length + 1;
    final newId = 'LMT-2026-${nextIndex.toString().padLeft(3, '0')}';

    final newMember = MemberModel(
      id: newId,
      username: username.trim(),
      password: password.trim().isEmpty ? 'password123' : password.trim(),
      name: name.trim(),
      role: effectiveRole,
      groups: groups.isEmpty
          ? const ['فريق الرسالة الاخيرة - العام']
          : groups,
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
    );

    emit(state.copyWith(members: updatedMembers, chatGroups: updatedGroups));
    await persistState();
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

  /// Deletes a member (Admin only).
  Future<void> deleteMember(String memberId) async {
    if (!state.currentUser.role.canDeleteMembers) return;
    if (memberId == state.currentUser.id) return;

    final updatedMembers =
        state.members.where((m) => m.id != memberId).toList();
    emit(state.copyWith(members: updatedMembers));
    await persistState();
  }
}
