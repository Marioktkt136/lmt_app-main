import 'package:flutter/widgets.dart';

import 'biometric_auth_service.dart';

/// Coordinates app-wide Biometric / Face ID session locking so that:
/// - Logged-in users remain permanently authenticated across restarts and lock
///   screens without re-entering username/password (until explicit logout).
/// - When Biometrics / Face ID is enabled, the app requires biometric verification
///   on cold open and whenever returning from background or phone lock screen.
/// - When Biometrics / Face ID is disabled, the app opens straight in cleanly.
class BiometricSessionLockController {
  BiometricSessionLockController._();

  /// Shared application-wide instance.
  static final BiometricSessionLockController instance =
      BiometricSessionLockController._();

  /// Reactive lock visibility driving the full-screen biometric shield.
  final ValueNotifier<bool> isLocked = ValueNotifier<bool>(false);

  bool _isInAuthenticatedShell = false;
  bool _biometricEnabled = true;
  bool _isPromptInFlight = false;
  int _suppressNextLockCount = 0;
  DateTime? _lastUnlockAt;

  /// Whether the user is currently inside an authenticated session shell.
  bool get isInAuthenticatedShell => _isInAuthenticatedShell;

  /// Whether Biometric / Face ID protection is currently active.
  bool get biometricEnabled => _biometricEnabled;

  /// Whether a hardware / fallback biometric prompt is currently open.
  bool get isPromptInFlight => _isPromptInFlight;

  /// Enters the authenticated app shell after session restoration (cold open).
  void enterAuthenticatedSession({
    required bool biometricEnabled,
    bool? lockNow,
  }) {
    _isInAuthenticatedShell = true;
    _biometricEnabled = biometricEnabled;
    _suppressNextLockCount = 0;
    isLocked.value = lockNow ?? biometricEnabled;
  }

  /// Marks explicit credential or biometric login success (starts unlocked).
  void onExplicitLoginSuccess({required bool biometricEnabled}) {
    _isInAuthenticatedShell = true;
    _biometricEnabled = biometricEnabled;
    _suppressNextLockCount = 0;
    _lastUnlockAt = DateTime.now();
    isLocked.value = false;
  }

  /// Clears lock state cleanly when the user explicitly signs out.
  void resetToLoggedOut() {
    _isInAuthenticatedShell = false;
    _isPromptInFlight = false;
    _suppressNextLockCount = 0;
    _lastUnlockAt = null;
    isLocked.value = false;
  }

  /// Updates the Biometric Lock toggle while preserving active session access.
  void setBiometricEnabled(bool enabled) {
    _biometricEnabled = enabled;
    if (!enabled) {
      isLocked.value = false;
    }
  }

  /// Temporarily suppresses locking across the next system modal/picker
  /// (e.g., gallery picker, camera, permission prompt, Settings toggle prompt).
  void suppressNextResumeLock() {
    _suppressNextLockCount++;
  }

  /// Processes OS lifecycle transitions to lock immediately when the screen
  /// locks or the app moves behind another app, returning whether the UI should
  /// auto-prompt biometrics upon resume.
  bool handleAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (!_isInAuthenticatedShell ||
          !_biometricEnabled ||
          _isPromptInFlight) {
        return false;
      }
      if (_suppressNextLockCount > 0) {
        _suppressNextLockCount--;
        return false;
      }
      final recentlyUnlocked = _lastUnlockAt != null &&
          DateTime.now().difference(_lastUnlockAt!).inMilliseconds < 650;
      if (recentlyUnlocked) {
        return false;
      }
      isLocked.value = true;
      return false;
    }

    if (state == AppLifecycleState.resumed) {
      if (!_isInAuthenticatedShell) return false;
      if (!_biometricEnabled) {
        isLocked.value = false;
        return false;
      }
      return isLocked.value && !_isPromptInFlight;
    }

    return false;
  }

  /// Runs Biometric / Face ID verification to unlock the active session.
  Future<BiometricStatus> attemptUnlock({
    required String userId,
    required String username,
    required String localizedReason,
    BiometricAuthService? service,
    Future<bool?> Function()? onPluginMissingFallback,
  }) async {
    if (!_biometricEnabled || !isLocked.value) {
      isLocked.value = false;
      return BiometricStatus.success;
    }
    if (_isPromptInFlight) {
      return BiometricStatus.cancelled;
    }

    _isPromptInFlight = true;
    try {
      final authService = service ?? BiometricAuthService();
      final result = await authService.authenticate(
        userId: userId,
        username: username,
        localizedReason: localizedReason,
      );

      if (result.status == BiometricStatus.success) {
        _lastUnlockAt = DateTime.now();
        _suppressNextLockCount = 0;
        isLocked.value = false;
        return BiometricStatus.success;
      }

      if (result.status == BiometricStatus.pluginMissing &&
          onPluginMissingFallback != null) {
        final confirmed = await onPluginMissingFallback();
        if (confirmed == true) {
          _lastUnlockAt = DateTime.now();
          _suppressNextLockCount = 0;
          isLocked.value = false;
          return BiometricStatus.success;
        }
        return BiometricStatus.cancelled;
      }

      return result.status;
    } finally {
      _isPromptInFlight = false;
    }
  }
}
