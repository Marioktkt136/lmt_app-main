/// Maps file names to MIME types and sanitises names for the file system.
///
/// Add new extensions in [forFileName] when new document types are supported.
class MimeTypeUtil {
  MimeTypeUtil._();

  /// Pattern of characters that are illegal in file names.
  static final RegExp illegalFileNameChars = RegExp(r'[\\/:*?"<>|]');

  /// Replaces illegal characters in [name] with underscores.
  static String sanitizeFileName(String name) =>
      name.replaceAll(illegalFileNameChars, '_');

  /// Returns the MIME type for [fileName] based on its extension, defaulting
  /// to `application/octet-stream`.
  static String forFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }
}
