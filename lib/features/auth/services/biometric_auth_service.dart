import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/utils/app_preferences.dart';
import 'web_biometric_bridge.dart';

/// Possible outcomes of a [BiometricAuthService.authenticate] call.
enum BiometricStatus {
  /// The user passed the hardware prompt.
  success,

  /// The prompt was dismissed or the user failed to authenticate.
  cancelled,

  /// Device has no enrolled / supported biometrics.
  notEnrolled,

  /// The local_auth plugin is unavailable (e.g. desktop / tests); the UI
  /// should show its interactive fallback dialog.
  pluginMissing,

  /// A platform error occurred; see [BiometricResult.message].
  error,
}

/// Result object returned by [BiometricAuthService.authenticate].
class BiometricResult {
  /// Creates a result with a [status] and optional platform [message].
  const BiometricResult(this.status, [this.message]);

  /// Outcome of the attempt.
  final BiometricStatus status;

  /// Platform error text, only set when [status] is [BiometricStatus.error].
  final String? message;
}

/// Thin wrapper around `local_auth` that hides plugin/exception handling.
///
/// It performs no UI work and holds no state, so it can be reused or faked in
/// tests. Rule: callers decide whether biometrics are *allowed* (only after a
/// previous login); this service only talks to the hardware.
class BiometricAuthService {
  /// Creates the service, optionally with a custom [LocalAuthentication].
  BiometricAuthService([LocalAuthentication? localAuth])
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Prepares WebAuthn capability metadata ahead of a user tap on Web / iOS PWA
  /// so biometric prompts open cleanly inside the click gesture window.
  Future<void> warmUp() async {
    if (kIsWeb) {
      await WebBiometricBridge.warmUp();
    }
  }

  /// Shows the system biometric prompt (or WebAuthn Face ID / Touch ID on
  /// HTTPS Web & iOS Home Screen PWA) using [localizedReason].
  Future<BiometricResult> authenticate({
    required String localizedReason,
    String? userId,
    String? username,
  }) async {
    if (kIsWeb) {
      final resolvedUserId =
          userId ?? (await AppPreferences.getCurrentUserId()) ?? 'lmt_user';
      final resolvedUsername =
          username ?? (await AppPreferences.getSavedUsername()) ?? resolvedUserId;
      final res = await WebBiometricBridge.authenticate(
        userId: resolvedUserId,
        username: resolvedUsername,
        localizedReason: localizedReason,
      );
      return switch (res.status) {
        'success' => const BiometricResult(BiometricStatus.success),
        'cancelled' => BiometricResult(BiometricStatus.cancelled, res.message),
        'notEnrolled' => const BiometricResult(BiometricStatus.notEnrolled),
        'pluginMissing' => const BiometricResult(BiometricStatus.pluginMissing),
        _ => BiometricResult(BiometricStatus.error, res.message),
      };
    }
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      if (!isSupported || (!canCheck && available.isEmpty)) {
        return const BiometricResult(BiometricStatus.notEnrolled);
      }
      final ok = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      return BiometricResult(
        ok ? BiometricStatus.success : BiometricStatus.cancelled,
      );
    } on MissingPluginException {
      return const BiometricResult(BiometricStatus.pluginMissing);
    } on PlatformException catch (e) {
      return BiometricResult(BiometricStatus.error, e.message ?? e.code);
    }
  }
}
