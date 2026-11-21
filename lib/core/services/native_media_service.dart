import 'package:flutter/services.dart';

/// Native Android/iOS Bridge for Microphone Permission, Real Voice Note Recording
/// & Playback, and Public Downloads Storage (`/storage/emulated/0/Download/LMT`).
class NativeMediaService {
  NativeMediaService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.lmt/native_media');

  /// Opens the native Android system file & image browser (`Intent.ACTION_OPEN_DOCUMENT`)
  /// and returns a map containing `{name, path, size}`, or `null` if cancelled.
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

  /// Plays a recorded `.m4a` voice note file through the device speaker.
  static Future<bool> playVoiceNote(String filePath) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'playVoiceNote',
        {'path': filePath},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
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
