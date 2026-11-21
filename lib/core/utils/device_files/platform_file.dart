/// Represents a file picked from the user's device storage.
///
/// Immutable value object returned by the file pickers.
class PlatformFile {
  /// Creates a picked-file descriptor.
  const PlatformFile({
    required this.name,
    required this.path,
    required this.size,
  });

  /// File name including extension.
  final String name;

  /// Absolute path on disk, or null when unavailable.
  final String? path;

  /// Size in bytes (0 when unknown).
  final int size;

  /// Extension without the dot, or null if the name has none.
  String? get extension {
    final dotIdx = name.lastIndexOf('.');
    if (dotIdx == -1 || dotIdx == name.length - 1) return null;
    return name.substring(dotIdx + 1);
  }
}
