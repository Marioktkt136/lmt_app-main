import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

import '../../models/lmt_models.dart';
import '../cloud_media_storage.dart';
import 'file_type.dart';
import 'mime_type_util.dart';
import 'platform_file.dart';

final Map<String, Uint8List> _webPickedBytesCache = <String, Uint8List>{};
web.HTMLAudioElement? _activeWebAudioPlayer;

/// On Web, disk paths do not exist; `cloud://`, `data:`, and `http:` URLs
/// are handled directly in [DeviceFileHelper].
ImageProvider? localFileImageProvider(String path) => null;

/// On Web, disk paths do not exist; `cloud://`, `data:`, and `http:` URLs
/// are handled directly in [DeviceFileHelper].
Widget? buildLocalFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) =>
    null;

/// Web relies on [CloudMediaStorage] memory cache (browser HTTP cache).
Future<Uint8List?> readCloudDiskCache(String blobGroupId) async => null;

/// Web relies on [CloudMediaStorage] memory cache (browser HTTP cache).
Future<void> writeCloudDiskCache(String blobGroupId, Uint8List bytes) async {}

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
/// avatars and timeline images upload fast and sync cleanly via Firestore.
Future<Uint8List> _compactImageBytesIfLarge(
  web.File webFile,
  Uint8List rawBytes,
) async {
  const maxRawBytes = 240 * 1024;
  if (rawBytes.lengthInBytes <= maxRawBytes) return rawBytes;

  final objectUrl = web.URL.createObjectURL(webFile);
  final completer = Completer<Uint8List>();
  final img = web.HTMLImageElement();

  late JSFunction onLoad;
  late JSFunction onError;

  onLoad = ((web.Event _) {
    try {
      const maxDim = 960;
      var targetW = img.naturalWidth;
      var targetH = img.naturalHeight;
      if (targetW <= 0 || targetH <= 0) {
        completer.complete(rawBytes);
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
        completer.complete(rawBytes);
        return;
      }
      ctx.drawImage(img, 0, 0, targetW, targetH);
      final dataUrl = canvas.toDataURL('image/jpeg', 0.80.toJS);
      completer.complete(UriData.parse(dataUrl).contentAsBytes());
    } catch (_) {
      completer.complete(rawBytes);
    } finally {
      web.URL.revokeObjectURL(objectUrl);
    }
  }).toJS;

  onError = ((web.Event _) {
    web.URL.revokeObjectURL(objectUrl);
    completer.complete(rawBytes);
  }).toJS;

  img.addEventListener('load', onLoad);
  img.addEventListener('error', onError);
  img.src = objectUrl;

  return completer.future.timeout(
    const Duration(seconds: 6),
    onTimeout: () {
      web.URL.revokeObjectURL(objectUrl);
      return rawBytes;
    },
  );
}

Future<PlatformFile> _webFileToPlatformFile(web.File selected) async {
  final jsBuffer = await selected.arrayBuffer().toDart;
  var bytes = jsBuffer.toDart.asUint8List();
  final name = selected.name;
  var mime = selected.type.isNotEmpty
      ? selected.type
      : MimeTypeUtil.forFileName(name);

  if (mime.startsWith('image/')) {
    final compacted = await _compactImageBytesIfLarge(selected, bytes);
    if (compacted.lengthInBytes < bytes.lengthInBytes) {
      bytes = compacted;
      mime = 'image/jpeg';
    }
  }

  String resolvedPath;
  if (bytes.lengthInBytes <= 350 * 1024) {
    resolvedPath = 'data:$mime;base64,${base64Encode(bytes)}';
  } else {
    resolvedPath = web.URL.createObjectURL(selected);
  }
  _webPickedBytesCache[resolvedPath] = bytes;

  return PlatformFile(
    name: name,
    path: resolvedPath,
    size: bytes.lengthInBytes,
    bytes: bytes,
  );
}

/// Opens the browser native `<input type="file">` picker cleanly on Web.
Future<PlatformFile?> pickFallbackOrWebFile(
  BuildContext context, {
  required FileType type,
  List<String>? allowedExtensions,
}) async {
  final picked = await pickMultipleFallbackOrWebFiles(
    context,
    type: type,
    allowedExtensions: allowedExtensions,
    allowMultiple: false,
  );
  return picked.isEmpty ? null : picked.first;
}

/// Opens the browser native `<input type="file" multiple>` picker cleanly on Web
/// so users can pick multiple photos and/or videos simultaneously.
Future<List<PlatformFile>> pickMultipleFallbackOrWebFiles(
  BuildContext context, {
  required FileType type,
  List<String>? allowedExtensions,
  bool allowMultiple = true,
}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = allowMultiple
    ..accept = _acceptFilterFor(type, allowedExtensions)
    ..style.display = 'none';

  final completer = Completer<List<web.File>>();

  void finish(List<web.File> list) {
    if (!completer.isCompleted) {
      completer.complete(list);
    }
    input.remove();
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final files = input.files;
      final out = <web.File>[];
      if (files != null) {
        final limit = allowMultiple ? 20 : 1;
        for (var i = 0; i < files.length && i < limit; i++) {
          final f = files.item(i);
          if (f != null) out.add(f);
        }
      }
      finish(out);
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event _) => finish(const [])).toJS,
  );

  web.document.body?.append(input);
  input.click();

  final selectedFiles = await completer.future;
  if (selectedFiles.isEmpty) return const [];
  return Future.wait(selectedFiles.map(_webFileToPlatformFile));
}

/// Uploads Web-picked file/image bytes to [CloudMediaStorage] and returns a
/// compact `cloud://blob/...` URI synced across all Web and Mobile clients.
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

  var rawBytes = bytes ?? _webPickedBytesCache.remove(sourcePath);
  if (rawBytes == null && sourcePath.startsWith('data:')) {
    try {
      rawBytes = UriData.parse(sourcePath).contentAsBytes();
    } catch (_) {}
  }

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

  return sourcePath;
}

void _triggerWebBlobDownload(Uint8List bytes, String mime, String fileName) {
  final blobParts = <JSUint8Array>[bytes.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mime));
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(
    const Duration(seconds: 15),
    () => web.URL.revokeObjectURL(objectUrl),
  );
}

/// Triggers a real browser download (`<a download="...">`) using the real
/// cloud blob bytes, inline data URI, or bundled asset.
Future<String> downloadAndOpenRealFilePlatform(
  SharedFileModel file, {
  bool openAfterSave = true,
}) async {
  final localPath = file.localFilePath;
  String? downloadName;
  Uint8List? bytes;
  String mime = 'application/octet-stream';

  if (localPath != null && localPath.isNotEmpty) {
    if (CloudMediaStorage.isCloudUri(localPath)) {
      bytes = await CloudMediaStorage.downloadBytes(localPath);
      if (bytes != null && bytes.isNotEmpty) {
        downloadName = CloudMediaStorage.displayFileName(
          localPath,
          fallback: MimeTypeUtil.sanitizeFileName(file.title),
        );
        mime = CloudMediaStorage.mimeTypeFromUri(localPath) ??
            MimeTypeUtil.forFileName(downloadName);
      }
    } else if (localPath.startsWith('http://') ||
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
    } else if (localPath.startsWith('data:')) {
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

  final finalName = downloadName ?? 'lmt_download';
  _triggerWebBlobDownload(bytes, mime, finalName);
  return finalName;
}

/// Creates a browser Blob URL for `cloud://blob/...` playback or download.
Future<String?> materializeCloudFilePlatform(String path) async {
  if (!CloudMediaStorage.isCloudUri(path)) return path;
  final bytes = await CloudMediaStorage.downloadBytes(path);
  if (bytes == null || bytes.isEmpty) return null;
  final mime = CloudMediaStorage.mimeTypeFromUri(path) ??
      MimeTypeUtil.forFileName(CloudMediaStorage.displayFileName(path));
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  return web.URL.createObjectURL(blob);
}

/// Opens a `cloud://`, `data:`, `blob:`, or `http(s):` resource in a browser tab
/// or downloads non-inline formats.
Future<String?> openLocalOrExternalPathPlatform(String path) async {
  try {
    if (CloudMediaStorage.isCloudUri(path)) {
      final bytes = await CloudMediaStorage.downloadBytes(path);
      if (bytes == null || bytes.isEmpty) {
        return 'Unable to download cloud file';
      }
      final name = CloudMediaStorage.displayFileName(path, fallback: 'file');
      final mime = CloudMediaStorage.mimeTypeFromUri(path) ??
          MimeTypeUtil.forFileName(name);
      final isInlinePreviewable = mime.startsWith('image/') ||
          mime.startsWith('video/') ||
          mime.startsWith('audio/') ||
          mime == 'application/pdf' ||
          mime.startsWith('text/');

      if (isInlinePreviewable) {
        final blob = web.Blob(
          <JSUint8Array>[bytes.toJS].toJS,
          web.BlobPropertyBag(type: mime),
        );
        final url = web.URL.createObjectURL(blob);
        web.window.open(url, '_blank');
        Future<void>.delayed(
          const Duration(seconds: 20),
          () => web.URL.revokeObjectURL(url),
        );
      } else {
        _triggerWebBlobDownload(bytes, mime, name);
      }
      return null;
    }

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
    return 'File is stored locally on another device';
  } catch (e) {
    return e.toString();
  }
}

/// Plays a cloud/URL audio voice note directly in the Web browser via `<audio>`.
Future<bool> playAudioUrlWebPlatform(String path, {double speed = 1.0}) async {
  try {
    final resolved = await materializeCloudFilePlatform(path);
    if (resolved == null) return false;
    _activeWebAudioPlayer?.pause();
    final audio = web.HTMLAudioElement()
      ..src = resolved
      ..playbackRate = speed;
    _activeWebAudioPlayer = audio;
    await audio.play().toDart;
    return true;
  } catch (_) {
    return false;
  }
}

/// Pauses any active HTMLAudioElement voice note on Web.
Future<void> pauseAudioWebPlatform() async {
  try {
    _activeWebAudioPlayer?.pause();
  } catch (_) {}
}
