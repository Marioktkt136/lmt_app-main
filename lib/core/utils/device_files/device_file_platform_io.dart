import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/lmt_models.dart';
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

/// Copies a picked file into persistent app storage on IO platforms.
Future<String> persistPickedFilePlatform(
  String sourcePath,
  String fileName,
) async {
  if (sourcePath.startsWith('data:') ||
      sourcePath.startsWith('http://') ||
      sourcePath.startsWith('https://')) {
    return sourcePath;
  }
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

/// Downloads [file] to disk and optionally opens it via [OpenFilex].
Future<String> downloadAndOpenRealFilePlatform(
  SharedFileModel file, {
  bool openAfterSave = true,
}) =>
    FileDownloadService.downloadAndOpen(file, openAfterSave: openAfterSave);

/// Opens [path] natively using [OpenFilex]. Returns an error message on failure
/// or `null` when opening succeeded.
Future<String?> openLocalOrExternalPathPlatform(String path) async {
  try {
    final res = await OpenFilex.open(path);
    if (res.type == ResultType.done) return null;
    return res.message;
  } catch (e) {
    return e.toString();
  }
}
