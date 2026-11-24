import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// Browser & iOS PWA implementation of Web Notifications and unlocked Web Audio
/// MP3 chimes using `AudioContext` (`AudioBufferSourceNode`) + `HTMLAudioElement`
/// + `ServiceWorkerRegistration.showNotification` fallback.
class WebNotificationBridge {
  WebNotificationBridge._();

  static final Map<String, String> _cachedToneUrls = <String, String>{};
  static final Map<String, Uint8List> _cachedToneBytes = <String, Uint8List>{};
  static final Map<String, JSAny> _decodedBuffers = <String, JSAny>{};
  static final Map<String, Future<JSAny?>> _inflightDecodes =
      <String, Future<JSAny?>>{};
  static final Set<String> _preloadAssetPaths = <String>{};

  static JSObject? _audioCtx;
  static bool _listenersInstalled = false;
  static bool _unlocked = false;

  /// Installs persistent DOM user-gesture unlock hooks so Chrome, Edge, Safari,
  /// and iOS Home Screen PWA allow asynchronous notification chimes even after
  /// Firestore pushes updates without an active user gesture.
  static void init([Iterable<String> toneAssetPaths = const []]) {
    _preloadAssetPaths.addAll(toneAssetPaths.where((p) => p.isNotEmpty));
    _installGestureUnlockListeners();
    unawaited(_preloadAssetBytes());
  }

  static Future<void> _preloadAssetBytes() async {
    for (final path in _preloadAssetPaths) {
      await _loadAssetBytes(path);
    }
  }

  static void _installGestureUnlockListeners() {
    if (_listenersInstalled) return;
    _listenersInstalled = true;
    try {
      final handler = ((web.Event _) {
        _unlockAudioContextSync();
      }).toJS;
      final opts = web.AddEventListenerOptions(capture: true, passive: true);
      web.document.addEventListener('pointerdown', handler, opts);
      web.document.addEventListener('touchstart', handler, opts);
      web.document.addEventListener('click', handler, opts);
      web.document.addEventListener('keydown', handler, opts);
    } catch (e) {
      debugPrint('WebAudio gesture hook install skipped: $e');
    }
  }

  static JSObject? _ensureAudioContext() {
    if (_audioCtx != null) return _audioCtx;
    try {
      final winObj = web.window as JSObject;
      var ctorAny = winObj.getProperty<JSAny?>('AudioContext'.toJS);
      if (ctorAny == null || ctorAny.isUndefinedOrNull) {
        ctorAny = winObj.getProperty<JSAny?>('webkitAudioContext'.toJS);
      }
      if (ctorAny != null && !ctorAny.isUndefinedOrNull) {
        _audioCtx = (ctorAny as JSFunction).callAsConstructor<JSObject>();
      }
    } catch (e) {
      debugPrint('AudioContext creation error: $e');
    }
    return _audioCtx;
  }

  static String _audioCtxState(JSObject ctx) {
    try {
      return ctx.getProperty<JSString>('state'.toJS).toDart;
    } catch (_) {
      return 'unknown';
    }
  }

  static void _unlockAudioContextSync() {
    final ctx = _ensureAudioContext();
    if (ctx == null) return;
    try {
      if (_audioCtxState(ctx) != 'running') {
        ctx.callMethod<JSAny?>('resume'.toJS);
      }
      if (!_unlocked) {
        // Play a 1-sample silent buffer inside the active user gesture so
        // iOS Safari / WebKit permanently unlocks audio playback for the session.
        final emptyBuf = ctx.callMethod<JSObject>(
          'createBuffer'.toJS,
          1.toJS,
          1.toJS,
          22050.toJS,
        );
        final src = ctx.callMethod<JSObject>('createBufferSource'.toJS);
        src.setProperty('buffer'.toJS, emptyBuf);
        final dest = ctx.getProperty<JSObject>('destination'.toJS);
        src.callMethod<JSAny?>('connect'.toJS, dest);
        src.callMethod<JSAny?>('start'.toJS, 0.toJS);
        _unlocked = true;
      }
      // Decode any preloaded MP3 tones into Web Audio buffers.
      for (final path in _preloadAssetPaths) {
        if (!_decodedBuffers.containsKey(path)) {
          unawaited(_getOrDecodeBuffer(path));
        }
      }
    } catch (e) {
      debugPrint('WebAudio unlock attempt: $e');
    }
  }

  /// Explicitly unlocks browser audio & preloads tones inside a user tap.
  static Future<void> unlockFromUserGesture() async {
    _unlockAudioContextSync();
    final ctx = _audioCtx;
    if (ctx != null && _audioCtxState(ctx) == 'suspended') {
      try {
        await ctx.callMethod<JSPromise<JSAny?>>('resume'.toJS).toDart;
      } catch (_) {}
    }
  }

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
    await unlockFromUserGesture();
    if (!isSupported) return 'unsupported';
    try {
      final result = await web.Notification.requestPermission().toDart;
      return result.toDart;
    } catch (_) {
      return permissionStatus;
    }
  }

  static Future<Uint8List?> _loadAssetBytes(String assetPath) async {
    final existing = _cachedToneBytes[assetPath];
    if (existing != null) return existing;
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      _cachedToneBytes[assetPath] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('Web tone asset load error ($assetPath): $e');
      return null;
    }
  }

  static Future<JSAny?> _getOrDecodeBuffer(String assetPath) {
    final cached = _decodedBuffers[assetPath];
    if (cached != null) return Future<JSAny?>.value(cached);
    final inflight = _inflightDecodes[assetPath];
    if (inflight != null) return inflight;

    final future = () async {
      try {
        final ctx = _ensureAudioContext();
        if (ctx == null) return null;
        final bytes = await _loadAssetBytes(assetPath);
        if (bytes == null || bytes.isEmpty) return null;
        // Clone before handing ArrayBuffer to decodeAudioData (which detaches it).
        final freshArrayBuffer = Uint8List.fromList(bytes).buffer.toJS;
        final decoded = await ctx
            .callMethod<JSPromise<JSAny?>>('decodeAudioData'.toJS, freshArrayBuffer)
            .toDart;
        if (decoded != null) {
          _decodedBuffers[assetPath] = decoded;
        }
        return decoded;
      } catch (e) {
        debugPrint('WebAudio decodeAudioData failed ($assetPath): $e');
        return null;
      } finally {
        _inflightDecodes.remove(assetPath);
      }
    }();

    _inflightDecodes[assetPath] = future;
    return future;
  }

  static Future<String?> _resolveToneUrl(String assetPath) async {
    final existing = _cachedToneUrls[assetPath];
    if (existing != null) return existing;
    final bytes = await _loadAssetBytes(assetPath);
    if (bytes == null || bytes.isEmpty) return null;
    final blob = web.Blob(
      <JSUint8Array>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'audio/mpeg'),
    );
    final blobUrl = web.URL.createObjectURL(blob);
    _cachedToneUrls[assetPath] = blobUrl;
    return blobUrl;
  }

  static bool _playSynthesizedChime(JSObject ctx) {
    try {
      final now = ctx.getProperty<JSNumber>('currentTime'.toJS).toDartDouble;
      final dest = ctx.getProperty<JSObject>('destination'.toJS);
      final gainNode = ctx.callMethod<JSObject>('createGain'.toJS);
      final gainParam = gainNode.getProperty<JSObject>('gain'.toJS);
      gainParam.callMethod<JSAny?>('setValueAtTime'.toJS, 0.001.toJS, now.toJS);
      gainParam.callMethod<JSAny?>(
          'exponentialRampToValueAtTime'.toJS, 0.28.toJS, (now + 0.02).toJS);
      gainParam.callMethod<JSAny?>(
          'exponentialRampToValueAtTime'.toJS, 0.001.toJS, (now + 0.42).toJS);

      final osc = ctx.callMethod<JSObject>('createOscillator'.toJS);
      osc.setProperty('type'.toJS, 'sine'.toJS);
      final freq = osc.getProperty<JSObject>('frequency'.toJS);
      freq.callMethod<JSAny?>('setValueAtTime'.toJS, 880.0.toJS, now.toJS);
      freq.callMethod<JSAny?>(
          'setValueAtTime'.toJS, 1174.66.toJS, (now + 0.11).toJS);

      osc.callMethod<JSAny?>('connect'.toJS, gainNode);
      gainNode.callMethod<JSAny?>('connect'.toJS, dest);
      osc.callMethod<JSAny?>('start'.toJS, now.toJS);
      osc.callMethod<JSAny?>('stop'.toJS, (now + 0.44).toJS);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Plays [assetPath] using unlocked Web Audio `AudioBufferSourceNode`,
  /// falling back to `HTMLAudioElement` or a gentle WebAudio chime.
  static Future<bool> playToneAsset(String assetPath) async {
    if (assetPath.isEmpty) return false;
    try {
      final ctx = _ensureAudioContext();
      if (ctx != null) {
        if (_audioCtxState(ctx) == 'suspended') {
          try {
            await ctx
                .callMethod<JSPromise<JSAny?>>('resume'.toJS)
                .toDart
                .timeout(const Duration(milliseconds: 250));
          } catch (_) {}
        }

        if (_audioCtxState(ctx) == 'running') {
          final decoded = await _getOrDecodeBuffer(assetPath);
          if (decoded != null) {
            final src = ctx.callMethod<JSObject>('createBufferSource'.toJS);
            src.setProperty('buffer'.toJS, decoded);
            final gainNode = ctx.callMethod<JSObject>('createGain'.toJS);
            gainNode
                .getProperty<JSObject>('gain'.toJS)
                .setProperty('value'.toJS, 1.0.toJS);
            final dest = ctx.getProperty<JSObject>('destination'.toJS);
            src.callMethod<JSAny?>('connect'.toJS, gainNode);
            gainNode.callMethod<JSAny?>('connect'.toJS, dest);
            src.callMethod<JSAny?>('start'.toJS, 0.toJS);
            return true;
          }
          if (_playSynthesizedChime(ctx)) {
            return true;
          }
        }
      }

      final toneUrl = await _resolveToneUrl(assetPath);
      if (toneUrl != null) {
        final audio = web.HTMLAudioElement()
          ..src = toneUrl
          ..volume = 1.0;
        await audio.play().toDart;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Web audio chime skipped ($assetPath): $e');
      return false;
    }
  }

  static Future<bool> showNotification({
    required String idKey,
    required String title,
    required String body,
    required String toneAssetPath,
    String? payload,
    void Function(String? payload)? onTap,
  }) async {
    unawaited(playToneAsset(toneAssetPath));

    if (!isSupported || permissionStatus != 'granted') return false;
    try {
      final notif = web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: 'icons/Icon-192.png?v=3',
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
      return true;
    } catch (_) {
      // Fallback for mobile Android Chrome / iOS PWA where Notification()
      // constructor requires ServiceWorkerRegistration.showNotification().
      try {
        final navObj = web.window.navigator as JSObject;
        final sw = navObj.getProperty<JSObject?>('serviceWorker'.toJS);
        if (sw == null) return false;
        final reg = await sw
            .getProperty<JSPromise<JSObject>>('ready'.toJS)
            .toDart
            .timeout(const Duration(seconds: 2));
        final opts = JSObject()
          ..setProperty('body'.toJS, body.toJS)
          ..setProperty('icon'.toJS, 'icons/Icon-192.png?v=3'.toJS)
          ..setProperty('tag'.toJS, idKey.toJS);
        await reg
            .callMethod<JSPromise<JSAny?>>(
              'showNotification'.toJS,
              title.toJS,
              opts,
            )
            .toDart;
        return true;
      } catch (e) {
        debugPrint('Web Notification dispatch error: $e');
        return false;
      }
    }
  }
}
