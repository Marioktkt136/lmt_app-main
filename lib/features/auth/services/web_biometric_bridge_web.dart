import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../../core/utils/app_preferences.dart';

/// Real browser & iOS Home Screen PWA Face ID / Touch ID / Windows Hello
/// authentication backed by the W3C WebAuthn Platform Authenticator API
/// (`navigator.credentials.create` / `navigator.credentials.get`).
class WebBiometricBridge {
  WebBiometricBridge._();

  static final Random _rng = Random.secure();
  static bool? _cachedPlatformSupported;

  static String _storageKey(String userId) =>
      'lmt_webauthn_cred_v1_${userId.trim()}';

  static String? _readStoredCredentialIdSync(String userId) {
    try {
      final raw = web.window.localStorage.getItem(_storageKey(userId));
      return (raw != null && raw.trim().isNotEmpty) ? raw.trim() : null;
    } catch (_) {
      return null;
    }
  }

  static void _saveCredentialIdSync(String userId, String credIdB64) {
    try {
      web.window.localStorage.setItem(_storageKey(userId), credIdB64);
    } catch (_) {}
    unawaited(AppPreferences.setWebAuthnCredentialId(userId, credIdB64));
  }

  static void _removeCredentialIdSync(String userId) {
    try {
      web.window.localStorage.removeItem(_storageKey(userId));
    } catch (_) {}
    unawaited(AppPreferences.setWebAuthnCredentialId(userId, null));
  }

  static Uint8List _randomChallenge([int length = 32]) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _rng.nextInt(256)),
    );
  }

  /// Checks and caches WebAuthn platform authenticator readiness before a tap
  /// so tapping Face ID calls `navigator.credentials` within the gesture tick.
  static Future<void> warmUp() async {
    await _isPlatformAvailable();
  }

  static Future<bool> _isPlatformAvailable() async {
    if (_cachedPlatformSupported != null) return _cachedPlatformSupported!;
    try {
      if (!web.window.isSecureContext) {
        _cachedPlatformSupported = false;
        return false;
      }
      final winObj = web.window as JSObject;
      if (!winObj.has('PublicKeyCredential')) {
        _cachedPlatformSupported = false;
        return false;
      }
      final pkc = winObj.getProperty<JSObject>('PublicKeyCredential'.toJS);
      final promise = pkc.callMethod<JSPromise<JSBoolean>>(
        'isUserVerifyingPlatformAuthenticatorAvailable'.toJS,
      );
      final available = (await promise.toDart).toDart;
      _cachedPlatformSupported = available;
      return available;
    } catch (_) {
      _cachedPlatformSupported = false;
      return false;
    }
  }

  static ({String name, String message}) _extractJsError(Object error) {
    try {
      final obj = error as JSObject;
      final name =
          obj.getProperty<JSAny?>('name'.toJS)?.dartify()?.toString() ?? '';
      final msg =
          obj.getProperty<JSAny?>('message'.toJS)?.dartify()?.toString() ??
              error.toString();
      return (name: name, message: msg);
    } catch (_) {
      return (name: '', message: error.toString());
    }
  }

  static Future<({String status, String? message})> _createPlatformPasskey({
    required JSObject credentials,
    required String userId,
    required String username,
  }) async {
    final hostname = web.window.location.hostname.trim();
    final rp = JSObject()..setProperty('name'.toJS, 'L.M.T App'.toJS);
    if (hostname.isNotEmpty) {
      rp.setProperty('id'.toJS, hostname.toJS);
    }

    final cleanUsername = username.trim().isEmpty ? userId : username.trim();
    final userObj = JSObject()
      ..setProperty('id'.toJS, Uint8List.fromList(utf8.encode(userId)).toJS)
      ..setProperty('name'.toJS, cleanUsername.toJS)
      ..setProperty('displayName'.toJS, cleanUsername.toJS);

    final es256 = JSObject()
      ..setProperty('type'.toJS, 'public-key'.toJS)
      ..setProperty('alg'.toJS, (-7).toJS);
    final rs256 = JSObject()
      ..setProperty('type'.toJS, 'public-key'.toJS)
      ..setProperty('alg'.toJS, (-257).toJS);

    final authSel = JSObject()
      ..setProperty('authenticatorAttachment'.toJS, 'platform'.toJS)
      ..setProperty('userVerification'.toJS, 'required'.toJS)
      ..setProperty('residentKey'.toJS, 'preferred'.toJS);

    final publicKey = JSObject()
      ..setProperty('challenge'.toJS, _randomChallenge().toJS)
      ..setProperty('rp'.toJS, rp)
      ..setProperty('user'.toJS, userObj)
      ..setProperty('pubKeyCredParams'.toJS, <JSAny>[es256, rs256].toJS)
      ..setProperty('authenticatorSelection'.toJS, authSel)
      ..setProperty('timeout'.toJS, 60000.toJS)
      ..setProperty('attestation'.toJS, 'none'.toJS);

    final createOpts = JSObject()..setProperty('publicKey'.toJS, publicKey);

    try {
      final cred = await credentials
          .callMethod<JSPromise<JSObject?>>('create'.toJS, createOpts)
          .toDart;
      if (cred == null) {
        return (status: 'cancelled', message: null);
      }
      final rawIdBuf = cred.getProperty<JSArrayBuffer>('rawId'.toJS);
      final credIdB64 = base64UrlEncode(rawIdBuf.toDart.asUint8List());
      _saveCredentialIdSync(userId, credIdB64);
      return (status: 'success', message: null);
    } catch (e) {
      final err = _extractJsError(e);
      if (err.name == 'NotAllowedError' || err.name == 'AbortError') {
        return (status: 'cancelled', message: err.message);
      }
      if (err.name == 'NotSupportedError' || err.name == 'SecurityError') {
        return (status: 'pluginMissing', message: err.message);
      }
      return (status: 'error', message: err.message);
    }
  }

  /// Triggers a real native Face ID / Touch ID / Windows Hello prompt on Web
  /// using WebAuthn. If no credential exists for [userId] on this device yet,
  /// enrolls a platform passkey on first verification.
  static Future<({String status, String? message})> authenticate({
    required String userId,
    required String username,
    required String localizedReason,
  }) async {
    final navObj = web.window.navigator as JSObject;
    final credentials = navObj.getProperty<JSObject?>('credentials'.toJS);
    if (credentials == null || !web.window.isSecureContext) {
      return (status: 'pluginMissing', message: null);
    }

    if (_cachedPlatformSupported == false) {
      return (status: 'notEnrolled', message: null);
    }

    final cleanUserId = userId.trim().isEmpty ? 'lmt_default_user' : userId;
    final savedCredId = _readStoredCredentialIdSync(cleanUserId);

    // Trigger navigator.credentials.get/create immediately inside the gesture
    // tick before any slow async capability checks so iOS Safari allows Face ID.
    if (savedCredId != null) {
      try {
        final rawIdBytes =
            Uint8List.fromList(base64Url.decode(base64Url.normalize(savedCredId)));
        final descriptor = JSObject()
          ..setProperty('type'.toJS, 'public-key'.toJS)
          ..setProperty('id'.toJS, rawIdBytes.toJS)
          ..setProperty('transports'.toJS, <JSString>['internal'.toJS].toJS);

        final publicKey = JSObject()
          ..setProperty('challenge'.toJS, _randomChallenge().toJS)
          ..setProperty('userVerification'.toJS, 'required'.toJS)
          ..setProperty('timeout'.toJS, 60000.toJS)
          ..setProperty('allowCredentials'.toJS, <JSAny>[descriptor].toJS);

        final hostname = web.window.location.hostname.trim();
        if (hostname.isNotEmpty) {
          publicKey.setProperty('rpId'.toJS, hostname.toJS);
        }

        final getOpts = JSObject()..setProperty('publicKey'.toJS, publicKey);
        final assertion = await credentials
            .callMethod<JSPromise<JSObject?>>('get'.toJS, getOpts)
            .toDart;
        if (assertion != null) {
          return (status: 'success', message: null);
        }
        return (status: 'cancelled', message: null);
      } catch (e) {
        final err = _extractJsError(e);
        if (err.name == 'InvalidStateError' || err.name == 'NotFoundError') {
          _removeCredentialIdSync(cleanUserId);
          // Credential missing on device — fall through to re-enroll below.
        } else if (err.name == 'NotAllowedError' || err.name == 'AbortError') {
          // If the saved credential was deleted in iOS Keychain, Safari often
          // rejects or cancels; check platform support or return cancelled.
          final available = await _isPlatformAvailable();
          if (!available) return (status: 'pluginMissing', message: err.message);
          return (status: 'cancelled', message: err.message);
        } else if (err.name == 'NotSupportedError' ||
            err.name == 'SecurityError') {
          return (status: 'pluginMissing', message: err.message);
        } else {
          return (status: 'error', message: err.message);
        }
      }
    }

    final available = await _isPlatformAvailable();
    if (!available) {
      return (status: 'pluginMissing', message: null);
    }

    return _createPlatformPasskey(
      credentials: credentials,
      userId: cleanUserId,
      username: username,
    );
  }
}
