import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/lmt_models.dart';
import '../../services/native_media_service.dart';
import '../cloud_media_storage.dart';
import 'mime_type_util.dart';

/// Materialises a [SharedFileModel] on disk (downloading from
/// [CloudMediaStorage] when needed), publishes it to the public Download folder,
/// and optionally opens it with the native viewer.
class FileDownloadService {
  FileDownloadService._();

  static Future<Directory> _resolveBaseDirectory() async {
    if (Platform.isAndroid) {
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) return ext;
      } catch (_) {}
    }
    return getApplicationDocumentsDirectory();
  }

  /// Downloads [file] and returns the public download path.
  static Future<String> downloadAndOpen(
    SharedFileModel file, {
    bool openAfterSave = true,
  }) async {
    final baseDir = await _resolveBaseDirectory();
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
    final localPath = file.localFilePath;

    // 0. Real cross-device file stored in Firestore media_blobs (`cloud://blob/...`).
    if (CloudMediaStorage.isCloudUri(localPath)) {
      final bytes = await CloudMediaStorage.downloadBytes(localPath!);
      if (bytes != null && bytes.isNotEmpty) {
        final realName = MimeTypeUtil.sanitizeFileName(
          CloudMediaStorage.displayFileName(
            localPath,
            fallback: file.title,
          ),
        );
        final extLower = file.fileExtension.toLowerCase();
        final finalName = (extLower.isNotEmpty &&
                extLower != 'file' &&
                !realName.toLowerCase().contains('.'))
            ? '$realName.$extLower'
            : realName;
        final target = File('${dir.path}/$finalName');
        await target.writeAsBytes(bytes, flush: true);
        return _Staged(target, finalName, MimeTypeUtil.forFileName(finalName));
      }
    }

    // 1. File uploaded from this device and still present locally.
    if (localPath != null &&
        localPath.isNotEmpty &&
        !CloudMediaStorage.isCloudUri(localPath)) {
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
    if (!Platform.isAndroid) {
      return staged.file.path;
    }
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
