import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/utils/app_preferences.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Profile feature module.
typedef ProfileCubit = LmtCubit;

/// Encapsulates User Profile updates, Password changes, and Biometric settings.
mixin ProfileCubitMixin on LmtBaseCubit {
  /// Verifies [currentPassword], then updates the active user's password
  /// and persists the updated credentials.
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty || newPassword.trim().length < 6) {
      return false;
    }
    if (!state.currentUser.verifyPassword(currentPassword)) {
      return false;
    }

    final updatedUser = state.currentUser.copyWith(password: newPassword.trim());
    final updatedMembers = state.members
        .map((m) => m.id == updatedUser.id ? updatedUser : m)
        .toList();

    await AppPreferences.saveLogin(
      username: updatedUser.username,
      userId: updatedUser.id,
    );

    emit(
      state.copyWith(
        currentUser: updatedUser,
        members: updatedMembers,
      ),
    );
    await persistState();
    return true;
  }

  /// Propagates updates to [updatedUser] across members, posts, comments,
  /// chat messages, and seen receipts so the new name/avatar appears everywhere.
  Future<void> _emitAndPropagateUserProfile(MemberModel updatedUser) async {
    final updatedMembers = state.members
        .map((m) => m.id == updatedUser.id ? updatedUser : m)
        .toList();

    final updatedPosts = state.posts.map((post) {
      final commentsChanged =
          post.comments.any((c) => c.authorId == updatedUser.id);
      final updatedComments = commentsChanged
          ? post.comments
              .map(
                (c) => c.authorId == updatedUser.id
                    ? c.copyWith(
                        authorName: updatedUser.name,
                        authorAvatar: updatedUser.avatarPath,
                      )
                    : c,
              )
              .toList()
          : post.comments;

      if (post.creatorId == updatedUser.id || commentsChanged) {
        return post.copyWith(
          creatorName: post.creatorId == updatedUser.id
              ? updatedUser.name
              : post.creatorName,
          creatorAvatar: post.creatorId == updatedUser.id
              ? updatedUser.avatarPath
              : post.creatorAvatar,
          comments: updatedComments,
        );
      }
      return post;
    }).toList();

    final updatedMessages = state.chatMessages.map((msg) {
      final seenChanged = msg.seenBy.any((s) => s.memberId == updatedUser.id);
      final updatedSeenBy = seenChanged
          ? msg.seenBy
              .map(
                (s) => s.memberId == updatedUser.id
                    ? s.copyWith(
                        memberName: updatedUser.name,
                        avatarPath: updatedUser.avatarPath,
                      )
                    : s,
              )
              .toList()
          : msg.seenBy;
      if (msg.senderId == updatedUser.id || seenChanged) {
        return msg.copyWith(
          senderName:
              msg.senderId == updatedUser.id ? updatedUser.name : msg.senderName,
          senderAvatar: msg.senderId == updatedUser.id
              ? updatedUser.avatarPath
              : msg.senderAvatar,
          seenBy: updatedSeenBy,
        );
      }
      return msg;
    }).toList();

    emit(
      state.copyWith(
        currentUser: updatedUser,
        members: updatedMembers,
        posts: updatedPosts,
        chatMessages: updatedMessages,
      ),
    );
    await persistState();
  }

  /// Updates only the active user's profile avatar image path.
  Future<void> updateProfileAvatar(String avatarPath) async {
    final trimmed = avatarPath.trim();
    if (trimmed.isEmpty) return;
    final updatedUser = state.currentUser.copyWith(avatarPath: trimmed);
    await _emitAndPropagateUserProfile(updatedUser);
  }

  /// Updates the active user's profile details (any user can update name & avatar).
  ///
  /// Only [UserRole.admin] (`canEditDepartmentsAndCommittees`) is allowed to
  /// modify [departments] (`القسم`) and [committees] (`اللجنة`).
  Future<void> updateProfileInfo({
    required String name,
    required List<String> departments,
    required List<String> committees,
    String? avatarPath,
  }) async {
    final canEditDeptsAndComms =
        state.currentUser.role.canEditDepartmentsAndCommittees;
    final resolvedName =
        name.trim().isNotEmpty ? name.trim() : state.currentUser.name;
    final updatedUser = state.currentUser.copyWith(
      name: resolvedName,
      avatarPath: (avatarPath != null && avatarPath.trim().isNotEmpty)
          ? avatarPath.trim()
          : state.currentUser.avatarPath,
      departments: canEditDeptsAndComms
          ? (departments.isEmpty
              ? [MemberModel.availableDepartments.first]
              : departments)
          : state.currentUser.departments,
      committees: canEditDeptsAndComms
          ? (committees.isEmpty
              ? [MemberModel.availableCommittees.first]
              : committees)
          : state.currentUser.committees,
    );
    await _emitAndPropagateUserProfile(updatedUser);
  }

  /// Enables or disables biometric authentication in user preferences.
  Future<void> setBiometricEnabled(bool enabled) async {
    await AppPreferences.setBiometricEnabled(enabled);
    emit(state.copyWith(biometricEnabled: enabled));
  }
}
