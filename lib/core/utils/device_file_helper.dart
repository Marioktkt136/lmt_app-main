import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/lmt_models.dart';
import '../services/native_media_service.dart';
import 'app_assets.dart';
import 'cloud_media_storage.dart';
import 'device_files/device_file_platform.dart';
import 'device_files/file_size_formatter.dart';
import 'device_files/file_type.dart';
import 'device_files/platform_file.dart';

export 'device_files/file_type.dart';
export 'device_files/platform_file.dart';

/// Cross-platform facade for device file & image handling across Mobile & Web.
///
/// - Displays images from `cloud://blob/...`, `data:` URLs, `http(s):` URLs,
///   local disk files (on IO platforms), or bundled Flutter assets.
/// - Uploads picked files/avatars/media to [CloudMediaStorage] automatically so
///   every phone & Web client renders and downloads the exact real file.
class DeviceFileHelper {
  DeviceFileHelper._();

  /// Whether [path] refers to a bundled Flutter asset.
  static bool isAssetPath(String path) => path.startsWith('assets/');

  /// Whether [path] refers to a cross-device cloud blob URI (`cloud://blob/...`).
  static bool isCloudUri(String? path) => CloudMediaStorage.isCloudUri(path);

  /// Clean human-readable file name extracted from [path] (handles `cloud://` URIs).
  static String displayFileName(String? path, {String fallback = 'File'}) =>
      CloudMediaStorage.displayFileName(path, fallback: fallback);

  /// Whether [path] refers to an HTTP(S) or inline `data:` / `blob:` URL.
  static bool isRemoteOrDataUri(String path) =>
      path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('data:') ||
      path.startsWith('blob:');

  /// Whether [path] refers to a video file based on its extension or URI query.
  static bool isVideoPath(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    final cleanName = CloudMediaStorage.displayFileName(path, fallback: path);
    final mime = CloudMediaStorage.mimeTypeFromUri(path) ?? '';
    if (mime.startsWith('video/')) return true;
    final lower = cleanName.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.m4v') ||
        path.toLowerCase().startsWith('data:video/');
  }

  static Uint8List? _decodeDataImageBytes(String dataUrl) {
    if (!dataUrl.startsWith('data:')) return null;
    try {
      return UriData.parse(dataUrl).contentAsBytes();
    } catch (_) {
      final commaIdx = dataUrl.indexOf(',');
      if (commaIdx == -1) return null;
      try {
        return base64Decode(dataUrl.substring(commaIdx + 1));
      } catch (_) {
        return null;
      }
    }
  }

  /// Launches the device camera directly on mobile (or browser upload on Web).
  static Future<PlatformFile?> capturePhotoFromCamera(
    BuildContext context,
  ) async {
    if (kIsWeb) {
      return pickFallbackOrWebFile(context, type: FileType.image);
    }
    try {
      final resultMap = await NativeMediaService.captureCameraPhoto();
      if (resultMap != null) {
        final path = resultMap['path'] as String?;
        if (path != null && path.isNotEmpty) {
          return PlatformFile(
            name: (resultMap['name'] as String?) ?? 'camera_photo.jpg',
            path: path,
            size: (resultMap['size'] as int?) ?? 0,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns an [ImageProvider] for a `cloud://blob/...`, `data:` image,
  /// network URL, local disk file (on IO), or bundled asset.
  static ImageProvider imageProviderFor(String path, {String? fallbackAsset}) {
    if (CloudMediaStorage.isCloudUri(path)) {
      return CloudBlobImageProvider(
        path,
        fallbackAsset: fallbackAsset ?? AppAssets.appLogo,
      );
    }
    if (path.startsWith('data:image/')) {
      final bytes = _decodeDataImageBytes(path);
      if (bytes != null) return MemoryImage(bytes);
    }
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      final local = localFileImageProvider(path);
      if (local != null) return local;
    }
    return AssetImage(
      isAssetPath(path) ? path : (fallbackAsset ?? AppAssets.appLogo),
    );
  }

  /// Builds an [Image] widget for `cloud://blob/...`, `data:` images, network
  /// URLs, local files (on IO), or bundled assets.
  static Widget buildImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (CloudMediaStorage.isCloudUri(path)) {
      return Image(
        image: CloudBlobImageProvider(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ??
            (_, _, _) => Image.asset(
                  AppAssets.appLogo,
                  width: width,
                  height: height,
                  fit: fit,
                ),
      );
    }
    if (path.startsWith('data:image/')) {
      final bytes = _decodeDataImageBytes(path);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      }
    }
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
    if (!kIsWeb) {
      final localWidget = buildLocalFileImage(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
      if (localWidget != null) return localWidget;
    }
    return Image.asset(
      isAssetPath(path) ? path : AppAssets.appLogo,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  /// Picks a file via native Gallery/File browser on mobile or `<input type="file">`
  /// on Web, falling back safely to [FallbackFilePickerDialog] on mobile IO.
  static Future<PlatformFile?> pickFileSafely(
    BuildContext context, {
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    if (kIsWeb) {
      return pickFallbackOrWebFile(
        context,
        type: type,
        allowedExtensions: allowedExtensions,
      );
    }
    try {
      final resultMap = await NativeMediaService.pickDeviceFile(
        type: type.name,
        allowedExtensions: allowedExtensions,
      );
      if (resultMap != null) {
        final path = resultMap['path'] as String?;
        if (path != null && path.isNotEmpty) {
          return PlatformFile(
            name: (resultMap['name'] as String?) ?? 'file',
            path: path,
            size: (resultMap['size'] as int?) ?? 0,
          );
        }
      }
      return null;
    } on MissingPluginException {
      if (!context.mounted) return null;
      return pickFallbackOrWebFile(
        context,
        type: type,
        allowedExtensions: allowedExtensions,
      );
    } on PlatformException {
      if (!context.mounted) return null;
      return pickFallbackOrWebFile(
        context,
        type: type,
        allowedExtensions: allowedExtensions,
      );
    } catch (_) {
      if (!context.mounted) return null;
      return pickFallbackOrWebFile(
        context,
        type: type,
        allowedExtensions: allowedExtensions,
      );
    }
  }

  /// Persists and uploads a picked file to [CloudMediaStorage] (`cloud://blob/...`)
  /// when online, falling back to persistent local app storage when offline.
  static Future<String> persistPickedFile(
    String sourcePath,
    String fileName, {
    Uint8List? bytes,
  }) =>
      persistPickedFilePlatform(sourcePath, fileName, bytes: bytes);

  /// Formats a byte count into KB / MB.
  static String formatBytes(int bytes) => FileSizeFormatter.format(bytes);

  /// Downloads [file] (fetching real bytes from [CloudMediaStorage] when needed).
  static Future<String> downloadAndOpenRealFile(
    SharedFileModel file, {
    bool openAfterSave = true,
  }) =>
      downloadAndOpenRealFilePlatform(file, openAfterSave: openAfterSave);

  /// Materializes a `cloud://blob/...` URI to a playable file path (IO) or Blob URL (Web).
  static Future<String?> resolvePlayablePath(String path) =>
      materializeCloudFilePlatform(path);

  /// Plays an audio voice note in browser on Web (`false` on IO so caller uses [NativeMediaService]).
  static Future<bool> playAudioOnWeb(String path, {double speed = 1.0}) =>
      playAudioUrlWebPlatform(path, speed: speed);

  /// Pauses any playing audio on Web.
  static Future<void> pauseAudioOnWeb() => pauseAudioWebPlatform();

  /// Opens [path] natively on mobile or in a browser tab/download on Web.
  static Future<String?> openPath(String path) =>
      openLocalOrExternalPathPlatform(path);
}
