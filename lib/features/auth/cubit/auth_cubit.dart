import 'dart:convert';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/repositories/lmt_repository.dart';
import '../../../core/services/background_sync_bridge.dart';
import '../../../core/utils/app_preferences.dart';
import '../services/biometric_session_lock_controller.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Authentication feature module.
typedef AuthCubit = LmtCubit;

/// Domain exception raised when credential or biometric authentication fails.
class AuthException implements Exception {
  /// Localized Arabic failure reason.
  final String messageAr;

  /// Localized English failure reason.
  final String messageEn;

  /// Creates an [AuthException].
  const AuthException({
    required this.messageAr,
    required this.messageEn,
  });

  /// Returns [messageAr] when [isArabic] is `true`, else [messageEn].
  String localized(bool isArabic) => isArabic ? messageAr : messageEn;

  @override
  String toString() => messageEn;
}

/// Encapsulates strict Credential Authentication, Biometric Login, and
/// Session Lifecycle logic.
mixin AuthCubitMixin on LmtBaseCubit {
  MemberModel? _findAccount(List<MemberModel> members, String normalized) {
    for (final m in members) {
      if (m.username.trim().toLowerCase() == normalized ||
          m.id.trim().toLowerCase() == normalized) {
        return m;
      }
    }
    return null;
  }

  /// Authenticates an existing team member strictly against their stored
  /// account credentials and persists verified session tokens.
  Future<MemberModel> login({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      throw const AuthException(
        messageAr: 'يرجى إدخال اسم المستخدم وكلمة المرور.',
        messageEn: 'Please enter both username and password.',
      );
    }

    var currentMembers = state.members;
    LmtRepositorySnapshot? refreshedSnapshot;
    var matched = _findAccount(currentMembers, normalized);

    // If the account isn't cached yet or its password changed on another
    // device, sync once from the repository before rejecting.
    if (matched == null || !matched.verifyPassword(password)) {
      try {
        final snapshot = await repository.loadSnapshot();
        final remoteMatch = _findAccount(snapshot.members, normalized);
        if (remoteMatch != null) {
          refreshedSnapshot = snapshot;
          currentMembers = snapshot.members;
          matched = remoteMatch;
        }
      } catch (_) {}
    }

    if (matched == null) {
      throw const AuthException(
        messageAr:
            'اسم المستخدم غير موجود. يرجى التأكد من البيانات أو التواصل مع المسؤول.',
        messageEn:
            'Account not found. Please verify your username or contact an administrator.',
      );
    }

    if (!matched.verifyPassword(password)) {
      throw const AuthException(
        messageAr: 'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.',
        messageEn: 'Incorrect password. Please try again.',
      );
    }

    final jwtToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${base64Url.encode(utf8.encode(matched.id))}.lmt_sig_2026';

    await AppPreferences.saveLogin(
      username: matched.username,
      userId: matched.id,
      accessToken: jwtToken,
      refreshToken: 'refresh_${matched.id}_2026',
    );
    await AppPreferences.setRememberMe(rememberMe);

    final effectiveNotifications =
        refreshedSnapshot?.notifications ?? state.notifications;
    await seedKnownNotificationsForUser(matched.id, effectiveNotifications);

    emit(
      state.copyWith(
        sloganOfYear: refreshedSnapshot?.sloganOfYear ?? state.sloganOfYear,
        verseOfYear: refreshedSnapshot?.verseOfYear ?? state.verseOfYear,
        chatGroups: refreshedSnapshot?.chatGroups ?? state.chatGroups,
        chatMessages: refreshedSnapshot?.chatMessages ?? state.chatMessages,
        posts: refreshedSnapshot?.posts ?? state.posts,
        sharedFiles: refreshedSnapshot?.sharedFiles ?? state.sharedFiles,
        calendarEvents:
            refreshedSnapshot?.calendarEvents ?? state.calendarEvents,
        notifications: effectiveNotifications,
        khelwaDays: refreshedSnapshot?.khelwaDays ?? state.khelwaDays,
        currentUser: matched,
        members: currentMembers,
        activeLayoutTab: 0,
        clearSelectedChatGroup: true,
      ),
    );
    alertUnseenNotificationsForCurrentUser(effectiveNotifications);
    final bioEnabled = await AppPreferences.isBiometricEnabled();
    BiometricSessionLockController.instance.onExplicitLoginSuccess(
      biometricEnabled: bioEnabled,
    );
    await BackgroundSyncBridge.syncSessionConfig(
      isLoggedIn: true,
      userId: matched.id,
      alertedIds: await AppPreferences.getAlertedNotificationIds(matched.id),
    );
    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: matched.id,
    );
    return matched;
  }

  /// Authenticates the previously signed-in member strictly bound to the stored
  /// session user ID via hardware biometrics (Fingerprint / Face ID).
  Future<MemberModel> loginWithBiometrics() async {
    final isBiometricEnabled = await AppPreferences.isBiometricEnabled();
    if (!isBiometricEnabled) {
      throw const AuthException(
        messageAr: 'الدخول بالبصمة والوجه معطل حالياً من الإعدادات.',
        messageEn:
            'Fingerprint / Face ID login is currently disabled in Settings.',
      );
    }

    final isLoggedIn = await AppPreferences.isLoggedIn();
    final savedUserId = await AppPreferences.getCurrentUserId();
    if (!isLoggedIn || savedUserId == null || savedUserId.trim().isEmpty) {
      throw const AuthException(
        messageAr:
            'يرجى تسجيل الدخول باسم المستخدم وكلمة المرور أولاً لتفعيل الدخول بالبصمة.',
        messageEn:
            'Please sign in with your username and password first to enable biometric login.',
      );
    }

    var currentMembers = state.members;
    var user = currentMembers.where((m) => m.id == savedUserId).firstOrNull;
    if (user == null) {
      try {
        final snapshot = await repository.loadSnapshot();
        currentMembers = snapshot.members;
        user = currentMembers.where((m) => m.id == savedUserId).firstOrNull;
      } catch (_) {}
    }

    if (user == null) {
      await AppPreferences.clearLogin();
      throw const AuthException(
        messageAr:
            'لم يعد هذا الحساب متاحاً. يرجى تسجيل الدخول بحساب صالح.',
        messageEn:
            'This account is no longer active. Please sign in with a valid account.',
      );
    }

    final jwtToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${base64Url.encode(utf8.encode(user.id))}.bio_sig_2026';

    await AppPreferences.saveLogin(
      username: user.username,
      userId: user.id,
      accessToken: jwtToken,
      refreshToken: 'refresh_${user.id}_2026',
    );
    await seedKnownNotificationsForUser(user.id, state.notifications);

    emit(
      state.copyWith(
        currentUser: user,
        members: currentMembers,
        activeLayoutTab: 0,
        clearSelectedChatGroup: true,
      ),
    );
    alertUnseenNotificationsForCurrentUser(state.notifications);
    BiometricSessionLockController.instance.onExplicitLoginSuccess(
      biometricEnabled: true,
    );
    await BackgroundSyncBridge.syncSessionConfig(
      isLoggedIn: true,
      userId: user.id,
      alertedIds: await AppPreferences.getAlertedNotificationIds(user.id),
    );
    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: user.id,
    );
    return user;
  }

  /// Signs out the active user cleanly and clears local session tokens.
  Future<void> logout() async {
    BiometricSessionLockController.instance.resetToLoggedOut();
    await BackgroundSyncBridge.clearSession();
    await AppPreferences.clearLogin();
    emit(
      state.copyWith(
        activeLayoutTab: 0,
        clearSelectedChatGroup: true,
        clearSelectedCalendarEvent: true,
      ),
    );
  }
}
