import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/lmt_models.dart';
import '../../services/native_media_service.dart';
import 'mime_type_util.dart';

/// Materialises a [SharedFileModel] on disk, publishes it to the public
/// Download folder and optionally opens it with the native viewer.
class FileDownloadService {
  FileDownloadService._();

  /// Downloads [file] and returns the public download path.
  ///
  /// Staging order: user-uploaded local file, bundled image asset, then a
  /// generated text document. When [openAfterSave] is true the staged file is
  /// opened via [OpenFilex].
  static Future<String> downloadAndOpen(
    SharedFileModel file, {
    bool openAfterSave = true,
  }) async {
    final baseDir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${baseDir.path}/LMT_Downloads');
    if (!downloadsDir.existsSync()) {
      await downloadsDir.create(recursive: true);
    }

    final staged = await _stage(file, downloadsDir);
    final publicPath = await _publish(staged);

    if (openAfterSave) {
      try {
        await OpenFilex.open(staged.file.path);
      } catch (_) {}
    }
    return publicPath;
  }

  static Future<_Staged> _stage(SharedFileModel file, Directory dir) async {
    // 1. File uploaded from the device and still present.
    final localPath = file.localFilePath;
    if (localPath != null && localPath.isNotEmpty) {
      final source = File(localPath);
      if (source.existsSync()) {
        final name = source.uri.pathSegments.last;
        final target = File('${dir.path}/$name');
        if (source.path != target.path) await source.copy(target.path);
        return _Staged(target, name, MimeTypeUtil.forFileName(name));
      }
    }

    // 2. Bundled image asset.
    if (file.category == SharedFileType.image &&
        file.imagePath.startsWith('assets/')) {
      final data = await rootBundle.load(file.imagePath);
      final safeTitle = MimeTypeUtil.sanitizeFileName(file.title);
      final name = safeTitle.toLowerCase().endsWith('.png')
          ? safeTitle
          : '$safeTitle.png';
      final target = File('${dir.path}/$name');
      await target.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return _Staged(target, name, 'image/png');
    }

    // 3. Generated document for seed items.
    final baseName = MimeTypeUtil.sanitizeFileName(
      file.title.replaceAll(
        RegExp(r'\.(pdf|docx|xlsx|txt|png)$', caseSensitive: false),
        '',
      ),
    ).trim();
    final name = '$baseName.txt';
    final target = File('${dir.path}/$name');
    await target.writeAsString('''
=============================================================
The Last Message Team (فريق الرسالة الاخيرة - L.M.T)
=============================================================
العنوان: ${file.title}
النوع: ${file.fileExtension} (${file.fileSize})
بواسطة: ${file.uploadedBy}
الوصف: ${file.description}
-------------------------------------------------------------

${file.documentContent ?? file.description}
''', flush: true);
    return _Staged(target, name, 'text/plain');
  }

  static Future<String> _publish(_Staged staged) async {
    final viaNative = await NativeMediaService.saveFileToPublicDownloads(
      sourcePath: staged.file.path,
      fileName: staged.name,
      mimeType: staged.mimeType,
    );
    if (viaNative != null) return viaNative;
    try {
      final publicDir = Directory('/storage/emulated/0/Download/LMT');
      if (!publicDir.existsSync()) await publicDir.create(recursive: true);
      final publicFile = File('${publicDir.path}/${staged.name}');
      await staged.file.copy(publicFile.path);
      return publicFile.path;
    } catch (_) {
      return '/storage/emulated/0/Download/LMT/${staged.name}';
    }
  }
}

class _Staged {
  const _Staged(this.file, this.name, this.mimeType);
  final File file;
  final String name;
  final String mimeType;
}
