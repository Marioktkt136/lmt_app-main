/// Human readable file size formatting.
class FileSizeFormatter {
  FileSizeFormatter._();

  /// Formats [bytes] into KB / MB (e.g. `12.5 KB`, `1.20 MB`).
  static String format(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
