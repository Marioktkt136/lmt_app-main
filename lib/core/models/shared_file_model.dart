import 'package:equatable/equatable.dart';

import '../utils/app_assets.dart';

/// Categories of shared files and documents in the L.M.T repository.
enum SharedFileType {
  paperwork,
  image,
  wordExcel,
  pdf,
  card;

  /// Returns the localized category label.
  String label(bool isArabic) {
    switch (this) {
      case SharedFileType.paperwork:
        return isArabic ? 'أوراق عمل ونصوص' : 'Paperwork';
      case SharedFileType.image:
        return isArabic ? 'صور وتصميمات' : 'Images';
      case SharedFileType.wordExcel:
        return isArabic ? 'ملفات Word / Excel' : 'Word / Excel';
      case SharedFileType.pdf:
        return isArabic ? 'ملفات PDF' : 'PDF Files';
      case SharedFileType.card:
        return isArabic ? 'بطاقات وروابط 🔗' : 'Cards & Links 🔗';
    }
  }

  /// Parses a [SharedFileType] from its string [value].
  static SharedFileType fromString(String value) {
    return SharedFileType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SharedFileType.paperwork,
    );
  }
}

/// Represents a shared file, document, or hyperlink card in the L.M.T app.
class SharedFileModel extends Equatable {
  /// The unique identifier of the file or card.
  final String id;

  /// The display title of the file or card.
  final String title;

  /// A summary description of the file's content.
  final String description;

  /// The classification category of the item.
  final SharedFileType category;

  /// The thumbnail or icon path for the item.
  final String imagePath;

  /// The uppercase extension badge (e.g., `PDF`, `DOCX`, `XLSX`, `LINK 🔗`).
  final String fileExtension;

  /// The formatted file size or link provider label.
  final String fileSize;

  /// Optional external URL launched when tapping a card.
  final String? externalUrl;

  /// Optional internal route name navigated to when tapping a card.
  final String? internalRoute;

  /// Optional text content for in-app document previewing.
  final String? documentContent;

  /// Optional absolute path to a real file uploaded from the user's device.
  final String? localFilePath;

  /// The name of the member who uploaded the file.
  final String uploadedBy;

  /// The date and time when the file was uploaded.
  final DateTime uploadedAt;

  /// Creates a [SharedFileModel].
  const SharedFileModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imagePath = AppAssets.postIcon,
    required this.fileExtension,
    required this.fileSize,
    this.externalUrl,
    this.internalRoute,
    this.documentContent,
    this.localFilePath,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  /// Creates a copy of this shared file with updated fields.
  SharedFileModel copyWith({
    String? id,
    String? title,
    String? description,
    SharedFileType? category,
    String? imagePath,
    String? fileExtension,
    String? fileSize,
    String? externalUrl,
    String? internalRoute,
    String? documentContent,
    String? localFilePath,
    String? uploadedBy,
    DateTime? uploadedAt,
  }) {
    return SharedFileModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      externalUrl: externalUrl ?? this.externalUrl,
      internalRoute: internalRoute ?? this.internalRoute,
      documentContent: documentContent ?? this.documentContent,
      localFilePath: localFilePath ?? this.localFilePath,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  /// Serializes this file item to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'imagePath': imagePath,
        'fileExtension': fileExtension,
        'fileSize': fileSize,
        'externalUrl': externalUrl,
        'internalRoute': internalRoute,
        'documentContent': documentContent,
        'localFilePath': localFilePath,
        'uploadedBy': uploadedBy,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  /// Deserializes a [SharedFileModel] from a JSON map.
  factory SharedFileModel.fromJson(Map<String, dynamic> json) =>
      SharedFileModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category:
            SharedFileType.fromString(json['category'] as String? ?? 'card'),
        imagePath: json['imagePath'] as String? ?? AppAssets.postIcon,
        fileExtension: json['fileExtension'] as String? ?? 'PDF',
        fileSize: json['fileSize'] as String? ?? '1.2 MB',
        externalUrl: json['externalUrl'] as String?,
        internalRoute: json['internalRoute'] as String?,
        documentContent: json['documentContent'] as String?,
        localFilePath: json['localFilePath'] as String?,
        uploadedBy: json['uploadedBy'] as String? ?? 'Mario Naiem',
        uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        imagePath,
        fileExtension,
        fileSize,
        externalUrl,
        internalRoute,
        documentContent,
        localFilePath,
        uploadedBy,
        uploadedAt,
      ];
}
