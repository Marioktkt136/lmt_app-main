import 'package:flutter/services.dart';

/// Native Android/iOS Bridge for Microphone Permission, Real Voice Note Recording
/// & Playback, and Public Downloads Storage (`/storage/emulated/0/Download/LMT`).
class NativeMediaService {
  NativeMediaService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.lmt/native_media');

  /// Opens the native Android/iOS Gallery (for image/video/media) or system file
  /// browser (for any/custom files) and returns `{name, path, size}`, or `null`.
  static Future<Map<dynamic, dynamic>?> pickDeviceFile({
    String type = 'any',
    List<String>? allowedExtensions,
  }) async {
    return _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickDeviceFile',
      {
        'type': type,
        'allowedExtensions': allowedExtensions,
      },
    );
  }

  /// Launches the device Camera immediately to capture a photo and returns
  /// `{name, path, size}`, or `null` if cancelled.
  static Future<Map<dynamic, dynamic>?> captureCameraPhoto() async {
    return _channel.invokeMethod<Map<dynamic, dynamic>>('captureCameraPhoto');
  }

  /// Requests microphone recording permission (`RECORD_AUDIO`) from the OS.
  static Future<bool> requestMicrophonePermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestMicPermission');
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Starts recording a voice note from the device microphone and returns the output file path.
  static Future<String?> startVoiceRecording() async {
    try {
      return await _channel.invokeMethod<String>('startVoiceRecording');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Stops the active voice note recording and returns the saved `.m4a` file path.
  static Future<String?> stopVoiceRecording() async {
    try {
      return await _channel.invokeMethod<String>('stopVoiceRecording');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Cancels and deletes the current voice note recording.
  static Future<void> cancelVoiceRecording() async {
    try {
      await _channel.invokeMethod<void>('cancelVoiceRecording');
    } catch (_) {}
  }

  /// Plays or resumes a recorded `.m4a` voice note file through the device speaker
  /// with optional playback [speed] (`1.0`, `1.5`, `2.0`) and seek [positionMs].
  static Future<bool> playVoiceNote(
    String filePath, {
    double speed = 1.0,
    int? positionMs,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'playVoiceNote',
        {
          'path': filePath,
          'speed': speed,
          'positionMs': positionMs,
        },
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Pauses the currently playing voice note without losing its seek position.
  static Future<void> pauseVoiceNote() async {
    try {
      await _channel.invokeMethod<void>('pauseVoiceNote');
    } catch (_) {}
  }

  /// Seeks the active voice note to [positionMs] milliseconds.
  static Future<void> seekVoiceNote(int positionMs) async {
    try {
      await _channel.invokeMethod<void>(
        'seekVoiceNote',
        {'positionMs': positionMs},
      );
    } catch (_) {}
  }

  /// Updates the active voice note playback speed (`1.0`, `1.5`, or `2.0`).
  static Future<void> setVoicePlaybackSpeed(double speed) async {
    try {
      await _channel.invokeMethod<void>(
        'setVoicePlaybackSpeed',
        {'speed': speed},
      );
    } catch (_) {}
  }

  /// Stops any currently playing voice note.
  static Future<void> stopVoiceNote() async {
    try {
      await _channel.invokeMethod<void>('stopVoiceNote');
    } catch (_) {}
  }

  /// Saves a file from [sourcePath] into the phone's public `Download/LMT` folder
  /// (`/storage/emulated/0/Download/LMT/<fileName>`) via `MediaStore.Downloads`.
  static Future<String?> saveFileToPublicDownloads({
    required String sourcePath,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    try {
      return await _channel.invokeMethod<String>(
        'saveFileToPublicDownloads',
        {
          'sourcePath': sourcePath,
          'fileName': fileName,
          'mimeType': mimeType,
        },
      );
    } catch (_) {
      return null;
    }
  }
}
