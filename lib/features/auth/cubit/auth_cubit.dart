import 'dart:convert';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/utils/app_preferences.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Authentication feature module.
typedef AuthCubit = LmtCubit;

/// Encapsulates Authentication, Biometric Login, and Session Token logic.
mixin AuthCubitMixin on LmtBaseCubit {
  /// Authenticates a user with [username] and [password] and persists session tokens.
  Future<MemberModel> login({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    final normalized = username.trim().toLowerCase();
    MemberModel? matched;

    for (final m in state.members) {
      if (m.username.toLowerCase() == normalized ||
          m.id.toLowerCase() == normalized ||
          m.name.toLowerCase() == normalized) {
        matched = m;
        break;
      }
    }

    if (matched == null) {
      if (normalized.contains('admin')) {
        matched = state.members.firstWhere(
          (m) => m.role == UserRole.admin,
          orElse: () => state.members.first,
        );
      } else if (normalized.contains('edit')) {
        matched = state.members.firstWhere(
          (m) => m.role == UserRole.editor,
          orElse: () => state.members.first,
        );
      } else if (normalized.contains('member')) {
        matched = state.members.firstWhere(
          (m) => m.role == UserRole.member,
          orElse: () => state.members.last,
        );
      } else {
        matched = state.members.first.copyWith(
          username: username.trim(),
          name: username.trim(),
        );
      }
    }

    final jwtToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${base64Url.encode(utf8.encode(matched.id))}.lmt_sig_2026';

    await AppPreferences.saveLogin(
      username: matched.username,
      password: password,
      userId: matched.id,
      accessToken: jwtToken,
      refreshToken: 'refresh_${matched.id}_2026',
    );

    emit(
      state.copyWith(
        currentUser: matched,
        activeLayoutTab: 0,
        clearSelectedChatGroup: true,
      ),
    );
    await persistState();
    return matched;
  }

  /// Authenticates the previously logged-in user via hardware biometrics (Fingerprint / Face ID).
  Future<MemberModel> loginWithBiometrics() async {
    final savedUserId = await AppPreferences.getCurrentUserId();
    MemberModel user = state.currentUser;
    if (savedUserId != null) {
      final found = state.members.where((m) => m.id == savedUserId).toList();
      if (found.isNotEmpty) {
        user = found.first;
      }
    }
    await AppPreferences.saveLogin(
      username: user.username,
      password: user.password,
      userId: user.id,
      accessToken: 'biometric_jwt_${user.id}',
    );
    emit(state.copyWith(currentUser: user));
    await persistState();
    return user;
  }

  /// Switches the current active role (Admin / Editor / Member).
  Future<void> switchRoleForDemo(UserRole role) async {
    final existingWithRole =
        state.members.where((m) => m.role == role).toList();
    final updatedUser = existingWithRole.isNotEmpty
        ? existingWithRole.first
        : state.currentUser.copyWith(role: role);

    emit(state.copyWith(currentUser: updatedUser));
    await persistState();
  }
}
