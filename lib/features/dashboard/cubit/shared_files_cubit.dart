import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/services/local_notification_service.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Shared Files & Documents feature module.
typedef SharedFilesCubit = LmtCubit;

/// Encapsulates Shared Files, Documents, and Hyperlink Cards CRUD operations.
mixin SharedFilesCubitMixin on LmtBaseCubit {
  /// Adds a new shared file, document, or hyperlink card (Admin & Editor).
  Future<void> addSharedFile({
    required String title,
    required String description,
    required SharedFileType category,
    required String imagePath,
    required String fileExtension,
    required String fileSize,
    String? externalUrl,
    String? documentContent,
    String? localFilePath,
  }) async {
    if (!state.currentUser.role.canManageFiles) return;

    final newFile = SharedFileModel(
      id: 'file_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      category: category,
      imagePath: imagePath,
      fileExtension: fileExtension,
      fileSize: fileSize,
      externalUrl:
          externalUrl?.trim().isEmpty == true ? null : externalUrl?.trim(),
      documentContent: documentContent,
      localFilePath: localFilePath,
      uploadedBy: state.currentUser.name,
      uploadedAt: DateTime.now(),
    );

    pushNotification(
      title: 'ملف مشترك جديد 📁',
      description: 'قام ${state.currentUser.name} بإضافة "${newFile.title}".',
      category: NotificationCategory.files,
      tone: LmtNotificationTone.normal,
      targetTabIndex: 2,
      excludedMemberIds: [state.currentUser.id],
    );

    emit(state.copyWith(sharedFiles: [newFile, ...state.sharedFiles]));
    await persistState();
  }

  /// Updates an existing shared file or card metadata (Admin & Editor).
  Future<void> updateSharedFile({
    required String fileId,
    required String title,
    required String description,
    String? externalUrl,
  }) async {
    if (!state.currentUser.role.canManageFiles) return;
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;

    final updatedFiles = state.sharedFiles.map((file) {
      if (file.id != fileId) return file;
      final nextUrl = externalUrl == null
          ? file.externalUrl
          : (externalUrl.trim().isEmpty ? null : externalUrl.trim());
      return file.copyWith(
        title: cleanTitle,
        description: description.trim(),
        externalUrl: nextUrl,
      );
    }).toList();

    emit(state.copyWith(sharedFiles: updatedFiles));
    await persistState();
  }

  /// Deletes a shared file or card (Administrator ONLY).
  Future<void> deleteSharedFile(String fileId) async {
    if (!state.currentUser.role.canDeleteFiles) return;
    emit(
      state.copyWith(
        sharedFiles: state.sharedFiles.where((f) => f.id != fileId).toList(),
      ),
    );
    await persistState();
  }
}
