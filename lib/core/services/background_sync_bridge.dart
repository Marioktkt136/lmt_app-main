import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/auth/services/biometric_session_lock_controller.dart';
import '../../firebase_options.dart';
import '../utils/app_preferences.dart';

/// Native Android & iOS bridge coordinating OS-level background and lock-screen
/// notification monitoring via Firestore REST + custom Android channels + iOS
/// Background Fetch so alerts continue arriving when outside the app or when
/// the phone screen is locked.
class BackgroundSyncBridge {
  BackgroundSyncBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.example.lmt/background_sync');

  /// Optional callback invoked when the user taps a native background or
  /// lock-screen notification banner.
  static void Function(String? payload)? onBackgroundNotificationTapped;

  static bool _handlerInstalled = false;

  /// Installs the native-to-Dart method handler for background notification taps.
  static void ensureHandlerInstalled() {
    if (kIsWeb || _handlerInstalled) return;
    _handlerInstalled = true;
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onBackgroundNotificationTapped') {
          final payload = call.arguments as String?;
          if (payload != null && payload.isNotEmpty) {
            onBackgroundNotificationTapped?.call(payload);
          }
        }
      });
    } catch (_) {}
  }

  /// Syncs session credentials, alerted notification IDs, and Firebase REST
  /// options cleanly to the OS background service / scheduler.
  static Future<void> syncSessionConfig({
    required bool isLoggedIn,
    required String userId,
    Iterable<String> alertedIds = const [],
  }) async {
    if (kIsWeb) return;
    ensureHandlerInstalled();

    String? idToken;
    try {
      idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {}

    final options = DefaultFirebaseOptions.currentPlatform;
    try {
      await _channel.invokeMethod<void>('syncSessionConfig', {
        'isLoggedIn': isLoggedIn,
        'userId': userId,
        'apiKey': options.apiKey,
        'projectId': options.projectId,
        'idToken': idToken,
        'alertedIds': alertedIds.toList(),
      });
    } on MissingPluginException {
      // Safe fallback when running on older APK binaries or desktop unit tests.
    } catch (_) {}
  }

  /// Clears saved background session config and stops OS background services on logout.
  static Future<void> clearSession() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('syncSessionConfig', {
        'isLoggedIn': false,
        'userId': '',
        'apiKey': '',
        'projectId': '',
        'idToken': null,
        'alertedIds': const <String>[],
      });
    } on MissingPluginException {
      // Safe fallback on tests / unsupported hosts.
    } catch (_) {}
  }

  /// Pushes newly alerted notification IDs from foreground Dart to native prefs so
  /// the background monitor never re-fires already-shown alerts.
  static Future<void> recordAlertedIds(
    String userId,
    Iterable<String> ids,
  ) async {
    if (kIsWeb || userId.trim().isEmpty) return;
    final list = ids.where((id) => id.trim().isNotEmpty).toList();
    if (list.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('recordAlertedIds', {
        'userId': userId,
        'ids': list,
      });
    } on MissingPluginException {
      // Safe fallback.
    } catch (_) {}
  }

  /// Consumes IDs that native Android/iOS alerted while the screen was locked or
  /// the app was closed, storing them in [AppPreferences] cleanly.
  static Future<List<String>> consumeNativeAlertedIds(String userId) async {
    if (kIsWeb || userId.trim().isEmpty) return const [];
    try {
      final raw = await _channel.invokeListMethod<String>(
        'consumeNativeAlertedIds',
        {'userId': userId},
      );
      final ids = raw ?? const <String>[];
      if (ids.isNotEmpty) {
        await AppPreferences.addAlertedNotificationIds(userId, ids);
      }
      return ids;
    } on MissingPluginException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Retrieves any notification payload passed when cold-launching from a
  /// native background or lock-screen notification tap.
  static Future<String?> consumeLaunchPayload() async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<String>('consumeLaunchPayload');
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns whether Android battery optimization is currently unrestricted for
  /// reliable background & lock-screen notification delivery.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final ok = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return ok ?? true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the Android system battery optimization whitelist prompt/settings.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    BiometricSessionLockController.instance.suppressNextResumeLock();
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } on MissingPluginException {
      // Safe fallback.
    } catch (_) {}
  }
}
