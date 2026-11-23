import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

import '../../models/lmt_models.dart';
import 'file_type.dart';
import 'mime_type_util.dart';
import 'platform_file.dart';

/// On Web, disk paths do not exist; `data:` and `http:` URLs are handled in
/// [DeviceFileHelper].
ImageProvider? localFileImageProvider(String path) => null;

/// On Web, disk paths do not exist; `data:` and `http:` URLs are handled in
/// [DeviceFileHelper].
Widget? buildLocalFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) =>
    null;

String _acceptFilterFor(FileType type, List<String>? allowedExtensions) {
  if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
    return allowedExtensions
        .map((e) => e.startsWith('.') ? e : '.$e')
        .join(',');
  }
  return switch (type) {
    FileType.image => 'image/*',
    FileType.video => 'video/*',
    FileType.media => 'image/*,video/*',
    FileType.custom || FileType.any => '*/*',
  };
}

/// Resizes large images on an offscreen HTML `<canvas>` so browser-selected
/// avatars and timeline images fit comfortably inside Firestore documents.
Future<String?> _toCompactImageDataUrl(
  web.File webFile,
  Uint8List bytes,
  String mimeType,
) async {
  const maxRawBytes = 220 * 1024;
  if (bytes.lengthInBytes <= maxRawBytes) {
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  final objectUrl = web.URL.createObjectURL(webFile);
  final completer = Completer<String?>();
  final img = web.HTMLImageElement();

  late JSFunction onLoad;
  late JSFunction onError;

  onLoad = ((web.Event _) {
    try {
      const maxDim = 960;
      var targetW = img.naturalWidth;
      var targetH = img.naturalHeight;
      if (targetW <= 0 || targetH <= 0) {
        completer.complete('data:$mimeType;base64,${base64Encode(bytes)}');
        return;
      }
      if (targetW > maxDim || targetH > maxDim) {
        if (targetW >= targetH) {
          targetH = ((targetH * maxDim) / targetW).round().clamp(1, maxDim);
          targetW = maxDim;
        } else {
          targetW = ((targetW * maxDim) / targetH).round().clamp(1, maxDim);
          targetH = maxDim;
        }
      }
      final canvas = web.HTMLCanvasElement()
        ..width = targetW
        ..height = targetH;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (ctx == null) {
        completer.complete('data:$mimeType;base64,${base64Encode(bytes)}');
        return;
      }
      ctx.drawImage(img, 0, 0, targetW, targetH);
      completer.complete(canvas.toDataURL('image/jpeg', 0.80.toJS));
    } catch (_) {
      completer.complete('data:$mimeType;base64,${base64Encode(bytes)}');
    } finally {
      web.URL.revokeObjectURL(objectUrl);
    }
  }).toJS;

  onError = ((web.Event _) {
    web.URL.revokeObjectURL(objectUrl);
    completer.complete('data:$mimeType;base64,${base64Encode(bytes)}');
  }).toJS;

  img.addEventListener('load', onLoad);
  img.addEventListener('error', onError);
  img.src = objectUrl;

  return completer.future.timeout(
    const Duration(seconds: 6),
    onTimeout: () {
      web.URL.revokeObjectURL(objectUrl);
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    },
  );
}

/// Opens the browser native `<input type="file">` picker cleanly on Web.
Future<PlatformFile?> pickFallbackOrWebFile(
  BuildContext context, {
  required FileType type,
  List<String>? allowedExtensions,
}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = _acceptFilterFor(type, allowedExtensions)
    ..style.display = 'none';

  final completer = Completer<web.File?>();

  void finish(web.File? f) {
    if (!completer.isCompleted) {
      completer.complete(f);
    }
    input.remove();
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final files = input.files;
      finish(files != null && files.length > 0 ? files.item(0) : null);
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event _) => finish(null)).toJS,
  );

  web.document.body?.append(input);
  input.click();

  final selected = await completer.future;
  if (selected == null) return null;

  final jsBuffer = await selected.arrayBuffer().toDart;
  final bytes = jsBuffer.toDart.asUint8List();
  final name = selected.name;
  final mime = selected.type.isNotEmpty
      ? selected.type
      : MimeTypeUtil.forFileName(name);

  String? resolvedPath;
  if (mime.startsWith('image/')) {
    resolvedPath = await _toCompactImageDataUrl(selected, bytes, mime);
  } else if (bytes.lengthInBytes <= 350 * 1024) {
    resolvedPath = 'data:$mime;base64,${base64Encode(bytes)}';
  } else {
    // Keep non-image large files addressable via in-memory object URL for
    // current browser session previews/downloads without bloating Firestore.
    resolvedPath = web.URL.createObjectURL(selected);
  }

  return PlatformFile(
    name: name,
    path: resolvedPath,
    size: bytes.lengthInBytes,
    bytes: bytes,
  );
}

/// On Web, picked images/files already hold browser `data:` or `blob:` URLs.
Future<String> persistPickedFilePlatform(
  String sourcePath,
  String fileName,
) async =>
    sourcePath;

/// Triggers a real browser file download (`<a download="...">`) for [file].
Future<String> downloadAndOpenRealFilePlatform(
  SharedFileModel file, {
  bool openAfterSave = true,
}) async {
  final localPath = file.localFilePath;
  String? downloadName;
  Uint8List? bytes;
  String mime = 'application/octet-stream';

  if (localPath != null && localPath.isNotEmpty) {
    if (localPath.startsWith('http://') ||
        localPath.startsWith('https://') ||
        localPath.startsWith('blob:')) {
      final name = MimeTypeUtil.sanitizeFileName(file.title);
      final anchor = web.HTMLAnchorElement()
        ..href = localPath
        ..download = name
        ..target = '_blank'
        ..rel = 'noopener noreferrer'
        ..style.display = 'none';
      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      return name;
    }

    if (localPath.startsWith('data:')) {
      final parsed = UriData.parse(localPath);
      bytes = parsed.contentAsBytes();
      mime = parsed.mimeType;
      final safeTitle = MimeTypeUtil.sanitizeFileName(file.title);
      final extLower = file.fileExtension.toLowerCase();
      downloadName = (extLower.isNotEmpty &&
              !safeTitle.toLowerCase().endsWith('.$extLower'))
          ? '$safeTitle.$extLower'
          : safeTitle;
    }
  }

  if (bytes == null &&
      file.category == SharedFileType.image &&
      file.imagePath.startsWith('assets/')) {
    final data = await rootBundle.load(file.imagePath);
    bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    mime = 'image/png';
    final safeTitle = MimeTypeUtil.sanitizeFileName(file.title);
    downloadName =
        safeTitle.toLowerCase().endsWith('.png') ? safeTitle : '$safeTitle.png';
  }

  if (bytes == null) {
    final baseName = MimeTypeUtil.sanitizeFileName(
      file.title.replaceAll(
        RegExp(r'\.(pdf|docx|xlsx|txt|png)$', caseSensitive: false),
        '',
      ),
    ).trim();
    downloadName = '${baseName.isEmpty ? 'document' : baseName}.txt';
    mime = 'text/plain;charset=utf-8';
    final content = '''
=============================================================
The Last Message Team (فريق الرسالة الاخيرة - L.M.T)
=============================================================
العنوان: ${file.title}
النوع: ${file.fileExtension} (${file.fileSize})
بواسطة: ${file.uploadedBy}
الوصف: ${file.description}
-------------------------------------------------------------

${file.documentContent ?? file.description}
''';
    bytes = Uint8List.fromList(utf8.encode(content));
  }

  final blobParts = <JSUint8Array>[bytes.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mime));
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = downloadName ?? 'lmt_download'
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(
    const Duration(seconds: 10),
    () => web.URL.revokeObjectURL(objectUrl),
  );
  return downloadName ?? 'download';
}

/// Opens a browser URL, `blob:` URL, or triggers download for a `data:` URI.
Future<String?> openLocalOrExternalPathPlatform(String path) async {
  try {
    if (path.startsWith('data:')) {
      final parsed = UriData.parse(path);
      final bytes = parsed.contentAsBytes();
      final blob = web.Blob(
        <JSUint8Array>[bytes.toJS].toJS,
        web.BlobPropertyBag(type: parsed.mimeType),
      );
      final url = web.URL.createObjectURL(blob);
      web.window.open(url, '_blank');
      Future<void>.delayed(
        const Duration(seconds: 15),
        () => web.URL.revokeObjectURL(url),
      );
      return null;
    }
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:')) {
      await launchUrl(Uri.parse(path), mode: LaunchMode.platformDefault);
      return null;
    }
    return 'Unsupported file preview on web';
  } catch (e) {
    return e.toString();
  }
}
