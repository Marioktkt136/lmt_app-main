import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/lmt_models.dart';
import '../cloud_media_storage.dart';
import 'fallback_file_picker_dialog.dart';
import 'file_download_service.dart';
import 'file_type.dart';
import 'mime_type_util.dart';
import 'platform_file.dart';

/// Checks whether a non-asset [path] points to an existing local disk file.
File? _existingLocalFile(String path) {
  if (path.startsWith('assets/') ||
      path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('data:') ||
      CloudMediaStorage.isCloudUri(path) ||
      path.trim().isEmpty) {
    return null;
  }
  final file = File(path);
  return file.existsSync() ? file : null;
}

/// Returns a [FileImage] if [path] points to an existing local file, else null.
ImageProvider? localFileImageProvider(String path) {
  final file = _existingLocalFile(path);
  return file != null ? FileImage(file) : null;
}

/// Builds an [Image.file] widget if [path] points to an existing local file.
Widget? buildLocalFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  final file = _existingLocalFile(path);
  if (file == null) return null;
  return Image.file(
    file,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}

/// Opens the native fallback file picker dialog on IO platforms.
Future<PlatformFile?> pickFallbackOrWebFile(
  BuildContext context, {
  required FileType type,
  List<String>? allowedExtensions,
}) {
  return FallbackFilePickerDialog.show(
    context,
    type: type,
    allowedExtensions: allowedExtensions,
  );
}

/// Picks multiple files on fallback IO platforms (returns 0 or 1 item safely).
Future<List<PlatformFile>> pickMultipleFallbackOrWebFiles(
  BuildContext context, {
  required FileType type,
  List<String>? allowedExtensions,
}) async {
  final single = await pickFallbackOrWebFile(
    context,
    type: type,
    allowedExtensions: allowedExtensions,
  );
  return single == null ? const [] : [single];
}

Future<Directory?> _resolveCloudCacheDir() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/lmt_cloud_cache');
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  } catch (_) {
    return null;
  }
}

/// Reads cached cloud blob bytes from local disk on IO platforms.
Future<Uint8List?> readCloudDiskCache(String blobGroupId) async {
  try {
    final cacheDir = await _resolveCloudCacheDir();
    if (cacheDir == null) return null;
    final file = File('${cacheDir.path}/$blobGroupId.bin');
    if (!file.existsSync()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Persists downloaded cloud blob bytes to local disk cache on IO platforms.
Future<void> writeCloudDiskCache(String blobGroupId, Uint8List bytes) async {
  try {
    final cacheDir = await _resolveCloudCacheDir();
    if (cacheDir == null) return;
    final file = File('${cacheDir.path}/$blobGroupId.bin');
    await file.writeAsBytes(bytes, flush: true);
  } catch (_) {}
}

/// Copies a picked file into persistent local app storage AND uploads it to
/// Firestore [CloudMediaStorage] when online so every member sees the real file/image.
Future<String> persistPickedFilePlatform(
  String sourcePath,
  String fileName, {
  Uint8List? bytes,
}) async {
  if (CloudMediaStorage.isCloudUri(sourcePath) ||
      sourcePath.startsWith('http://') ||
      sourcePath.startsWith('https://')) {
    return sourcePath;
  }

  var localResult = sourcePath;
  Uint8List? rawBytes = bytes;

  try {
    final sourceFile = File(sourcePath);
    if (rawBytes == null && sourceFile.existsSync()) {
      rawBytes = await sourceFile.readAsBytes();
    }
    final dir = await getApplicationDocumentsDirectory();
    final uploadsDir = Directory('${dir.path}/lmt_uploads');
    if (!uploadsDir.existsSync()) {
      await uploadsDir.create(recursive: true);
    }
    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}_${MimeTypeUtil.sanitizeFileName(fileName)}';
    final targetPath = '${uploadsDir.path}/$safeName';
    if (sourceFile.existsSync()) {
      final copied = await sourceFile.copy(targetPath);
      localResult = copied.path;
    } else if (rawBytes != null) {
      await File(targetPath).writeAsBytes(rawBytes, flush: true);
      localResult = targetPath;
    }
  } catch (_) {}

  if (rawBytes != null && rawBytes.isNotEmpty) {
    final cloudUri = await CloudMediaStorage.uploadBytes(
      bytes: rawBytes,
      fileName: fileName,
      mimeType: MimeTypeUtil.forFileName(fileName),
    );
    if (cloudUri != null) {
      return cloudUri;
    }
  }

  return localResult;
}

/// Downloads [file] to disk and optionally opens it via [OpenFilex].
Future<String> downloadAndOpenRealFilePlatform(
  SharedFileModel file, {
  bool openAfterSave = true,
}) =>
    FileDownloadService.downloadAndOpen(file, openAfterSave: openAfterSave);

/// Materializes a `cloud://blob/...` URI to a real local file path on IO
/// (needed for native audio/video playback & `OpenFilex`).
Future<String?> materializeCloudFilePlatform(String path) async {
  if (!CloudMediaStorage.isCloudUri(path)) return path;
  final bytes = await CloudMediaStorage.downloadBytes(path);
  if (bytes == null || bytes.isEmpty) return null;

  final fileName = MimeTypeUtil.sanitizeFileName(
    CloudMediaStorage.displayFileName(path, fallback: 'lmt_media.bin'),
  );
  final parsed = Uri.tryParse(path);
  final blobGroupId =
      parsed?.pathSegments.isNotEmpty == true ? parsed!.pathSegments.first : 'b';

  try {
    final dir = await getTemporaryDirectory();
    final outFile = File('${dir.path}/${blobGroupId}_$fileName');
    if (!outFile.existsSync() || outFile.lengthSync() != bytes.lengthInBytes) {
      await outFile.writeAsBytes(bytes, flush: true);
    }
    return outFile.path;
  } catch (_) {
    return null;
  }
}

/// Opens [path] natively using [OpenFilex] (downloading `cloud://blob/...` first
/// when needed). Returns an error message on failure or `null` when opening succeeded.
Future<String?> openLocalOrExternalPathPlatform(String path) async {
  try {
    final resolved = await materializeCloudFilePlatform(path);
    if (resolved == null) {
      return 'Unable to download cloud file';
    }
    final res = await OpenFilex.open(resolved);
    if (res.type == ResultType.done) return null;
    return res.message;
  } catch (e) {
    return e.toString();
  }
}

/// On IO, audio playback uses [NativeMediaService].
Future<bool> playAudioUrlWebPlatform(String path, {double speed = 1.0}) async =>
    false;

/// On IO, audio pause uses [NativeMediaService].
Future<void> pauseAudioWebPlatform() async {}
