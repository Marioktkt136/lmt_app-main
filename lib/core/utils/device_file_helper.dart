 import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/lmt_models.dart';
import '../services/native_media_service.dart';
import 'app_assets.dart';
import 'device_files/device_file_platform.dart';
import 'device_files/file_size_formatter.dart';
import 'device_files/file_type.dart';
import 'device_files/platform_file.dart';

export 'device_files/file_type.dart';
export 'device_files/platform_file.dart';

/// Cross-platform facade for device file & image handling across Mobile & Web.
///
/// - Displays images from bundled assets, `data:` URLs, `http(s):` URLs,
///   and local disk files (on IO platforms).
/// - Picks files via the native picker on mobile or HTML `<input type="file">`
///   on Web, falling back safely to [FallbackFilePickerDialog] on mobile IO.
/// - Persists, formats, downloads, and opens files cross-platform.
class DeviceFileHelper {
  DeviceFileHelper._();

  /// Whether [path] refers to a bundled Flutter asset.
  static bool isAssetPath(String path) => path.startsWith('assets/');

  /// Whether [path] refers to an HTTP(S) or inline `data:` / `blob:` URL.
  static bool isRemoteOrDataUri(String path) =>
      path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('data:') ||
      path.startsWith('blob:');

  /// Whether [path] refers to a video file based on its extension.
  static bool isVideoPath(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.m4v') ||
        lower.startsWith('data:video/');
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

  /// Launches the device camera directly on mobile (or opens browser image
  /// upload with camera capture hint on Web).
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

  /// Returns an [ImageProvider] for a `data:` image, network URL, local disk
  /// file (on IO), or bundled asset.
  static ImageProvider imageProviderFor(String path, {String? fallbackAsset}) {
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

  /// Builds an [Image] widget for `data:` images, network URLs, local files
  /// (on IO), or bundled assets.
  static Widget buildImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
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

  /// Copies a picked file into persistent storage on IO platforms or keeps URLs
  /// / `data:` URIs intact on Web.
  static Future<String> persistPickedFile(
    String sourcePath,
    String fileName,
  ) =>
      persistPickedFilePlatform(sourcePath, fileName);

  /// Formats a byte count into KB / MB.
  static String formatBytes(int bytes) => FileSizeFormatter.format(bytes);

  /// Downloads [file] (browser download on Web, public folder on mobile).
  static Future<String> downloadAndOpenRealFile(
    SharedFileModel file, {
    bool openAfterSave = true,
  }) =>
      downloadAndOpenRealFilePlatform(file, openAfterSave: openAfterSave);

  /// Opens [path] natively on mobile or in a new browser tab on Web.
  /// Returns `null` on success or a human-readable error message on failure.
  static Future<String?> openPath(String path) =>
      openLocalOrExternalPathPlatform(path);
}
