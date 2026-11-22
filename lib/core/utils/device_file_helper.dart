import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../models/lmt_models.dart';
import '../services/native_media_service.dart';
import 'app_assets.dart';
import 'device_files/fallback_file_picker_dialog.dart';
import 'device_files/file_download_service.dart';
import 'device_files/file_size_formatter.dart';
import 'device_files/file_type.dart';
import 'device_files/mime_type_util.dart';
import 'device_files/platform_file.dart';

export 'device_files/file_type.dart';
export 'device_files/platform_file.dart';

/// Facade for device file & image handling.
///
/// - Displays images from device storage ([File]) or bundled assets.
/// - Picks files via the native picker, falling back to a `dart:io` dialog.
/// - Persists, formats and downloads files.
///
/// Implementation lives in `utils/device_files/`; keep this public API stable.
class DeviceFileHelper {
  DeviceFileHelper._();

  /// Whether [path] refers to a bundled Flutter asset.
  static bool isAssetPath(String path) => path.startsWith('assets/');

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
        lower.endsWith('.m4v');
  }

  /// Launches the device camera directly to take a photo.
  static Future<PlatformFile?> capturePhotoFromCamera(
    BuildContext context,
  ) async {
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

  static File? _existingLocalFile(String path) {
    if (isAssetPath(path) || path.trim().isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// Returns an [ImageProvider] for a local device file or a bundled asset.
  static ImageProvider imageProviderFor(String path, {String? fallbackAsset}) {
    final file = _existingLocalFile(path);
    if (file != null) return FileImage(file);
    return AssetImage(
      isAssetPath(path) ? path : (fallbackAsset ?? AppAssets.appLogo),
    );
  }

  /// Builds an [Image] widget for a local device file or a bundled asset.
  static Widget buildImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    final file = _existingLocalFile(path);
    if (file != null) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  /// Invokes the native file picker via [NativeMediaService], falling back to
  /// [FallbackFilePickerDialog] when the plugin is unavailable or fails.
  static Future<PlatformFile?> pickFileSafely(
    BuildContext context, {
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
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
      return _fallback(context, type, allowedExtensions);
    } on PlatformException {
      if (!context.mounted) return null;
      return _fallback(context, type, allowedExtensions);
    } catch (_) {
      if (!context.mounted) return null;
      return _fallback(context, type, allowedExtensions);
    }
  }

  static Future<PlatformFile?> _fallback(
    BuildContext context,
    FileType type,
    List<String>? allowedExtensions,
  ) {
    return FallbackFilePickerDialog.show(
      context,
      type: type,
      allowedExtensions: allowedExtensions,
    );
  }

  /// Copies a picked file into persistent app storage and returns the new
  /// path (or [sourcePath] if copying fails).
  static Future<String> persistPickedFile(
    String sourcePath,
    String fileName,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final uploadsDir = Directory('${dir.path}/lmt_uploads');
      if (!uploadsDir.existsSync()) {
        await uploadsDir.create(recursive: true);
      }
      final safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${MimeTypeUtil.sanitizeFileName(fileName)}';
      final copied = await File(sourcePath).copy('${uploadsDir.path}/$safeName');
      return copied.path;
    } catch (_) {
      return sourcePath;
    }
  }

  /// Formats a byte count into KB / MB.
  static String formatBytes(int bytes) => FileSizeFormatter.format(bytes);

  /// Downloads [file] to the public Download folder and (optionally) opens
  /// it. Returns the public path. See [FileDownloadService].
  static Future<String> downloadAndOpenRealFile(
    SharedFileModel file, {
    bool openAfterSave = true,
  }) =>
      FileDownloadService.downloadAndOpen(file, openAfterSave: openAfterSave);
}
