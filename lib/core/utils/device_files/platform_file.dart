import 'package:flutter/foundation.dart';

/// Represents a file picked from the user's device storage or Web browser.
///
/// Immutable value object returned by the file pickers.
class PlatformFile {
  /// Creates a picked-file descriptor.
  const PlatformFile({
    required this.name,
    required this.path,
    required this.size,
    this.bytes,
  });

  /// File name including extension.
  final String name;

  /// Absolute path on disk, `data:` URL, or null when only [bytes] is present.
  final String? path;

  /// Size in bytes (0 when unknown).
  final int size;

  /// Optional raw file bytes (always populated on Web browser picks).
  final Uint8List? bytes;

  /// Extension without the dot, or null if the name has none.
  String? get extension {
    final dotIdx = name.lastIndexOf('.');
    if (dotIdx == -1 || dotIdx == name.length - 1) return null;
    return name.substring(dotIdx + 1);
  }
}
