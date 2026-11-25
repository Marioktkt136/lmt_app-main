import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'device_files/device_file_platform.dart';

/// Cross-device cloud blob storage backed by Cloud Firestore (`media_blobs`).
///
/// Stores real file bytes (avatars, post images, chat images/voice/files, and
/// shared documents) chunked safely under Firestore's 1 MiB document limit,
/// returning a short `cloud://blob/<id>?name=...&mime=...&chunks=N` URI that fits
/// within every `firestore.rules` path field constraint and downloads seamlessly
/// on Android, iOS, and Web browsers without needing Firebase Storage Blaze.
class CloudMediaStorage {
  CloudMediaStorage._();

  static const String _collection = 'media_blobs';
  static const int _rawChunkSize = 480 * 1024; // ~640 KB base64 per doc
  static const int _maxUploadBytes = 12 * 1024 * 1024; // 12 MB ceiling (~25 chunks)
  static const Duration _timeout = Duration(seconds: 20);

  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};
  static final Map<String, Future<Uint8List?>> _inflightDownloads =
      <String, Future<Uint8List?>>{};
  static int _seq = 0;

  /// Whether [path] is a `cloud://blob/...` URI managed by [CloudMediaStorage].
  static bool isCloudUri(String? path) =>
      path != null && path.trim().startsWith('cloud://blob/');

  /// Extracts the original filename stored in a `cloud://blob/...` URI,
  /// or returns the basename for normal file paths.
  static String displayFileName(String? path, {String fallback = 'File'}) {
    if (path == null || path.trim().isEmpty) return fallback;
    if (isCloudUri(path)) {
      final parsed = Uri.tryParse(path.trim());
      final encodedName = parsed?.queryParameters['name'];
      if (encodedName != null && encodedName.trim().isNotEmpty) {
        return encodedName.trim();
      }
    }
    if (path.startsWith('data:')) return fallback;
    final clean = path.split('?').first;
    final base = clean.split('/').last.split('\\').last.trim();
    return base.isEmpty ? fallback : base;
  }

  /// Extracts MIME type stored inside a `cloud://blob/...` URI when available.
  static String? mimeTypeFromUri(String? path) {
    if (!isCloudUri(path)) return null;
    final parsed = Uri.tryParse(path!.trim());
    final mime = parsed?.queryParameters['mime'];
    return (mime != null && mime.isNotEmpty) ? mime : null;
  }

  /// Caches raw bytes immediately for [cloudUri] so the local client renders
  /// without waiting on a redundant Firestore round-trip.
  static void primeMemoryCache(String cloudUri, Uint8List bytes) {
    _memoryCache[cloudUri] = bytes;
  }

  /// Compresses large images cleanly (`<= ~300 KB` when possible) while leaving
  /// documents, PDFs, audio, and compact images untouched.
  static Future<Uint8List> _compactIfLargeImage(
    Uint8List bytes,
    String fileName,
  ) async {
    final lower = fileName.toLowerCase();
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
    if (!isImage || bytes.lengthInBytes <= 320 * 1024) {
      return bytes;
    }

    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 900,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (byteData != null) {
        final compacted = byteData.buffer.asUint8List();
        if (compacted.isNotEmpty && compacted.lengthInBytes < bytes.lengthInBytes) {
          return compacted;
        }
      }
    } catch (_) {}
    return bytes;
  }

  static Future<bool> _ensureAuth() async {
    if (Firebase.apps.isEmpty) return false;
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) return true;
      await auth.signInAnonymously().timeout(const Duration(seconds: 6));
      return auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Uploads [bytes] to Firestore `media_blobs` and returns a compact
  /// `cloud://blob/...` URI, or `null` when Firebase is unavailable / too large.
  static Future<String?> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (bytes.isEmpty || Firebase.apps.isEmpty) return null;

    final prepared = await _compactIfLargeImage(bytes, fileName);
    if (prepared.lengthInBytes > _maxUploadBytes) return null;

    final authed = await _ensureAuth();
    if (!authed) return null;

    try {
      final db = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final safeName = fileName.replaceAll(RegExp(r'[\r\n]'), '_').trim();
      final shortName =
          safeName.length > 64 ? safeName.substring(safeName.length - 64) : safeName;
      final blobGroupId =
          'b_${DateTime.now().millisecondsSinceEpoch}_${++_seq}';

      final totalChunks =
          ((prepared.lengthInBytes + _rawChunkSize - 1) ~/ _rawChunkSize)
              .clamp(1, 50);
      final createdAt = DateTime.now().toIso8601String();

      final futures = <Future<void>>[];
      for (var i = 0; i < totalChunks; i++) {
        final start = i * _rawChunkSize;
        final end = ((i + 1) * _rawChunkSize).clamp(0, prepared.lengthInBytes);
        final slice = Uint8List.sublistView(prepared, start, end);
        final docId = '${blobGroupId}_c$i';
        futures.add(
          db.collection(_collection).doc(docId).set({
            'id': docId,
            'blobGroupId': blobGroupId,
            'chunkIndex': i,
            'totalChunks': totalChunks,
            'fileName': shortName.isEmpty ? 'file' : shortName,
            'mimeType': mimeType.isEmpty ? 'application/octet-stream' : mimeType,
            'dataBase64': base64Encode(slice),
            'createdAt': createdAt,
            'updatedByUid': uid,
          }).timeout(_timeout),
        );
        if (futures.length >= 4 || i == totalChunks - 1) {
          await Future.wait(futures);
          futures.clear();
        }
      }

      final uri = Uri(
        scheme: 'cloud',
        host: 'blob',
        pathSegments: [blobGroupId],
        queryParameters: {
          'name': shortName.isEmpty ? 'file' : shortName,
          'mime': mimeType.isEmpty ? 'application/octet-stream' : mimeType,
          'chunks': '$totalChunks',
        },
      ).toString();

      _memoryCache[uri] = prepared;
      await writeCloudDiskCache(blobGroupId, prepared);
      return uri;
    } catch (e) {
      debugPrint('CloudMediaStorage uploadBytes error: $e');
      return null;
    }
  }

  /// Downloads and reassembles the exact bytes for [cloudUri], using memory +
  /// local disk caches and deduplicating concurrent in-flight requests.
  static Future<Uint8List?> downloadBytes(String cloudUri) {
    final trimmed = cloudUri.trim();
    if (!isCloudUri(trimmed)) return Future.value(null);

    final cached = _memoryCache[trimmed];
    if (cached != null) return Future.value(cached);

    final existing = _inflightDownloads[trimmed];
    if (existing != null) return existing;

    final future = _downloadInternal(trimmed);
    _inflightDownloads[trimmed] = future;
    future.whenComplete(() => _inflightDownloads.remove(trimmed));
    return future;
  }

  static Future<Uint8List?> _downloadInternal(String cloudUri) async {
    final parsed = Uri.tryParse(cloudUri);
    final blobGroupId =
        parsed?.pathSegments.isNotEmpty == true ? parsed!.pathSegments.first : '';
    if (blobGroupId.isEmpty) return null;

    final diskCached = await readCloudDiskCache(blobGroupId);
    if (diskCached != null && diskCached.isNotEmpty) {
      _memoryCache[cloudUri] = diskCached;
      return diskCached;
    }

    if (Firebase.apps.isEmpty) return null;
    final authed = await _ensureAuth();
    if (!authed) return null;

    try {
      final db = FirebaseFirestore.instance;
      final chunkCount =
          int.tryParse(parsed?.queryParameters['chunks'] ?? '1') ?? 1;
      final safeCount = chunkCount.clamp(1, 50);

      final snaps = await Future.wait(
        List.generate(
          safeCount,
          (i) => db
              .collection(_collection)
              .doc('${blobGroupId}_c$i')
              .get()
              .timeout(_timeout),
        ),
      );

      final builder = BytesBuilder(copy: false);
      for (final snap in snaps) {
        final data = snap.data();
        if (data == null) return null;
        final b64 = data['dataBase64'] as String?;
        if (b64 == null || b64.isEmpty) return null;
        builder.add(base64Decode(b64));
      }

      final fullBytes = builder.takeBytes();
      _memoryCache[cloudUri] = fullBytes;
      await writeCloudDiskCache(blobGroupId, fullBytes);
      return fullBytes;
    } catch (e) {
      debugPrint('CloudMediaStorage downloadBytes error: $e');
      return null;
    }
  }
}

/// Custom [ImageProvider] that fetches & decodes `cloud://blob/...` images from
/// [CloudMediaStorage] and integrates seamlessly with Flutter's [ImageCache].
@immutable
class CloudBlobImageProvider extends ImageProvider<CloudBlobImageProvider> {
  final String cloudUri;
  final String? fallbackAsset;

  const CloudBlobImageProvider(this.cloudUri, {this.fallbackAsset});

  @override
  Future<CloudBlobImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<CloudBlobImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    CloudBlobImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: key.cloudUri,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<String>('Cloud URI', key.cloudUri),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    CloudBlobImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await CloudMediaStorage.downloadBytes(key.cloudUri);
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Unable to load cloud image: ${key.cloudUri}');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudBlobImageProvider && other.cloudUri == cloudUri;

  @override
  int get hashCode => cloudUri.hashCode;
}
