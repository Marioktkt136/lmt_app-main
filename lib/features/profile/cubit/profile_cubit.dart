import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/utils/app_preferences.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Profile feature module.
typedef ProfileCubit = LmtCubit;

/// Encapsulates User Profile updates, Password changes, and Biometric settings.
mixin ProfileCubitMixin on LmtBaseCubit {
  /// Updates the active user's password and persists the updated credentials.
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final updatedUser = state.currentUser.copyWith(password: newPassword);
    final updatedMembers = state.members
        .map((m) => m.id == updatedUser.id ? updatedUser : m)
        .toList();

    await AppPreferences.saveLogin(
      username: updatedUser.username,
      password: newPassword,
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

  /// Updates the active user's profile details (name, specialty, committee).
  Future<void> updateProfileInfo({
    required String name,
    required String specialistAt,
    required String committee,
  }) async {
    final updatedUser = state.currentUser.copyWith(
      name: name.trim(),
      specialistAt: specialistAt.trim(),
      committee: committee.trim(),
    );
    final updatedMembers = state.members
        .map((m) => m.id == updatedUser.id ? updatedUser : m)
        .toList();

    emit(
      state.copyWith(
        currentUser: updatedUser,
        members: updatedMembers,
      ),
    );
    await persistState();
  }

  /// Enables or disables biometric authentication in user preferences.
  Future<void> setBiometricEnabled(bool enabled) async {
    await AppPreferences.setBiometricEnabled(enabled);
    emit(state.copyWith(biometricEnabled: enabled));
  }
}
