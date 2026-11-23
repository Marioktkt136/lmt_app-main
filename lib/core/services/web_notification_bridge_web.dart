import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// Browser implementation of Web Notifications & custom MP3 audio chimes using
/// the standard HTML5 Notification API and `HTMLAudioElement`.
class WebNotificationBridge {
  WebNotificationBridge._();

  static final Map<String, String> _cachedToneUrls = <String, String>{};

  static bool get isSupported {
    try {
      return web.window.has('Notification');
    } catch (_) {
      return false;
    }
  }

  static String get permissionStatus {
    if (!isSupported) return 'unsupported';
    try {
      return web.Notification.permission;
    } catch (_) {
      return 'unsupported';
    }
  }

  static Future<String> requestPermission() async {
    if (!isSupported) return 'unsupported';
    try {
      final result = await web.Notification.requestPermission().toDart;
      return result.toDart;
    } catch (_) {
      return permissionStatus;
    }
  }

  static Future<String> _resolveToneUrl(String assetPath) async {
    final existing = _cachedToneUrls[assetPath];
    if (existing != null) return existing;

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final blob = web.Blob(
      <JSUint8Array>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'audio/mpeg'),
    );
    final blobUrl = web.URL.createObjectURL(blob);
    _cachedToneUrls[assetPath] = blobUrl;
    return blobUrl;
  }

  static Future<void> playToneAsset(String assetPath) async {
    if (assetPath.isEmpty) return;
    try {
      final toneUrl = await _resolveToneUrl(assetPath);
      final audio = web.HTMLAudioElement()
        ..src = toneUrl
        ..volume = 1.0;
      await audio.play().toDart;
    } catch (e) {
      debugPrint('Web audio chime skipped (awaiting user gesture or blocked): $e');
    }
  }

  static Future<void> showNotification({
    required String idKey,
    required String title,
    required String body,
    required String toneAssetPath,
    String? payload,
    void Function(String? payload)? onTap,
  }) async {
    await playToneAsset(toneAssetPath);

    if (!isSupported || permissionStatus != 'granted') return;
    try {
      final notif = web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: 'icons/Icon-192.png',
          tag: idKey,
        ),
      );
      notif.addEventListener(
        'click',
        ((web.Event _) {
          try {
            web.window.focus();
          } catch (_) {}
          notif.close();
          onTap?.call(payload);
        }).toJS,
      );
    } catch (e) {
      debugPrint('Web Notification dispatch error: $e');
    }
  }
}
