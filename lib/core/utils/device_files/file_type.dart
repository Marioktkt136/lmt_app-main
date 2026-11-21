/// File filter category for picking files from device storage.
///
/// Passed to `DeviceFileHelper.pickFileSafely`; `name` is forwarded to the
/// native picker so do not rename values.
enum FileType {
  /// Any file.
  any,

  /// Images only (png, jpg, jpeg, webp, gif).
  image,

  /// Restrict to the `allowedExtensions` supplied by the caller.
  custom,
}
