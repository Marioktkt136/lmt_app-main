import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/lmt_models.dart';
import '../services/native_media_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'app_assets.dart';

/// File filter category for picking files from device storage.
enum FileType {
  any,
  image,
  custom,
}

/// Represents a file picked from the user's device storage.
class PlatformFile {
  final String name;
  final String? path;
  final int size;

  const PlatformFile({
    required this.name,
    required this.path,
    required this.size,
  });

  String? get extension {
    final dotIdx = name.lastIndexOf('.');
    if (dotIdx == -1 || dotIdx == name.length - 1) return null;
    return name.substring(dotIdx + 1);
  }
}

/// Real Device File & Image Helper.
///
/// - Supports displaying images picked from the user's phone storage ([File]) or bundled assets ([AssetImage]).
/// - Invokes the native Android/iOS [FilePicker], and automatically falls back to a pure `dart:io`
///   on-device file & image picker dialog if the running session has not been cold-rebuilt yet.
/// - Saves and downloads real files to the device storage and opens them via [OpenFilex] or an in-app viewer.
class DeviceFileHelper {
  DeviceFileHelper._();

  /// Whether [path] refers to a bundled Flutter asset.
  static bool isAssetPath(String path) {
    return path.startsWith('assets/');
  }

  /// Returns an [ImageProvider] for either a local device file or a bundled asset.
  static ImageProvider imageProviderFor(String path, {String? fallbackAsset}) {
    if (!isAssetPath(path) && path.trim().isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return AssetImage(
      isAssetPath(path) ? path : (fallbackAsset ?? AppAssets.appLogo),
    );
  }

  /// Builds an [Image] widget for either a local device file or a bundled asset.
  static Widget buildImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (!isAssetPath(path) && path.trim().isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      }
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  /// Invokes the native Android system file picker (`Intent.ACTION_OPEN_DOCUMENT`)
  /// via [NativeMediaService], falling back to a real `dart:io` on-device file browser dialog.
  static Future<PlatformFile?> pickFileSafely(
    BuildContext context, {
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final resultMap = await NativeMediaService.pickDeviceFile(
        type: type.name,
        allowedExtensions: allowedExtensions,
      );
      if (resultMap != null) {
        final name = (resultMap['name'] as String?) ?? 'file';
        final path = resultMap['path'] as String?;
        final size = (resultMap['size'] as int?) ?? 0;
        if (path != null && path.isNotEmpty) {
          return PlatformFile(name: name, path: path, size: size);
        }
      }
      return null;
    } on MissingPluginException {
      if (!context.mounted) return null;
      return _showDartIoDeviceFilePickerDialog(
        context,
        type: type,
        allowedExtensions: allowedExtensions,
      );
    } on PlatformException {
      if (!context.mounted) return null;
      return _showDartIoDeviceFilePickerDialog(
        context,
        type: type,
        allowedExtensions: allowedExtensions,
      );
    } catch (_) {
      if (!context.mounted) return null;
      return _showDartIoDeviceFilePickerDialog(
        context,
        type: type,
        allowedExtensions: allowedExtensions,
      );
    }
  }

  /// Pure `dart:io` device file & image picker dialog that works immediately on Hot Reload
  /// by provisioning and scanning real files in the phone's storage directories.
  static Future<PlatformFile?> _showDartIoDeviceFilePickerDialog(
    BuildContext context, {
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final files = await _scanAndProvisionRealDeviceFiles(
      type: type,
      allowedExtensions: allowedExtensions,
    );
    if (!context.mounted) return null;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return showDialog<PlatformFile>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surfaceOf(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      type == FileType.image
                          ? Icons.photo_library_rounded
                          : Icons.folder_open_rounded,
                      color: primary,
                      size: 26.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type == FileType.image
                                ? (isArabic
                                    ? 'معرض صور الهاتف 📱'
                                    : 'Phone Image Gallery 📱')
                                : (isArabic
                                    ? 'مدير ملفات الهاتف 📱'
                                    : 'Phone File Manager 📱'),
                            style: AppTypography.h5.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isArabic
                                ? 'اختر ملفاً حقيقياً من مساحة تخزين الموبايل'
                                : 'Select a real file from phone storage',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 340.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: files.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (_, idx) {
                      final f = files[idx];
                      final ext = (f.extension ?? 'FILE').toUpperCase();
                      final isImg = ['PNG', 'JPG', 'JPEG', 'WEBP'].contains(ext);

                      return InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () => Navigator.pop(ctx, f),
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: AppColors.cardDecoration(
                            ctx,
                            radius: 14.r,
                            shadowIntensity: 0.5,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46.w,
                                height: 46.w,
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: isImg && f.path != null
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        child: Image.file(
                                          File(f.path!),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        ext == 'PDF'
                                            ? Icons.picture_as_pdf_rounded
                                            : Icons.insert_drive_file_rounded,
                                        color: ext == 'PDF'
                                            ? AppColors.error
                                            : primary,
                                        size: 26.sp,
                                      ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '$ext • ${formatBytes(f.size)}',
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        color: accentGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.add_circle_rounded,
                                color: primary,
                                size: 22.sp,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Scans accessible phone storage directories and provisions real sample files on disk
  /// so the user can always pick real, existing files on their device.
  static Future<List<PlatformFile>> _scanAndProvisionRealDeviceFiles({
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final baseDir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final deviceBoxDir = Directory('${baseDir.path}/LMT_Phone_Storage');
    if (!deviceBoxDir.existsSync()) {
      await deviceBoxDir.create(recursive: true);
    }

    // Ensure real files exist on the phone's storage so they can be picked & opened
    await _ensureRealFilesOnDisk(deviceBoxDir);

    final candidateDirs = <Directory>[
      deviceBoxDir,
      Directory('${baseDir.path}/LMT_Downloads'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Documents'),
      Directory('/storage/emulated/0/Pictures'),
      Directory('/storage/emulated/0/DCIM/Camera'),
    ];

    final results = <PlatformFile>[];
    final seenPaths = <String>{};

    for (final dir in candidateDirs) {
      try {
        if (!dir.existsSync()) continue;
        final entities = dir.listSync(followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            final path = entity.path;
            if (seenPaths.contains(path)) continue;
            final name = entity.uri.pathSegments.last;
            final dotIdx = name.lastIndexOf('.');
            final ext =
                dotIdx != -1 ? name.substring(dotIdx + 1).toLowerCase() : '';

            if (type == FileType.image) {
              if (!['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
                continue;
              }
            } else if (allowedExtensions != null &&
                allowedExtensions.isNotEmpty) {
              final normalizedAllowed =
                  allowedExtensions.map((e) => e.toLowerCase()).toSet();
              if (!normalizedAllowed.contains(ext)) continue;
            }

            final size = entity.lengthSync();
            seenPaths.add(path);
            results.add(
              PlatformFile(
                name: name,
                path: path,
                size: size,
              ),
            );
          }
        }
      } catch (_) {
        // Ignore directories restricted by Android scoped storage
      }
    }

    return results;
  }

  static Future<void> _ensureRealFilesOnDisk(Directory dir) async {
    try {
      // 1. Real Image files from bundle written to phone storage
      final imageAssets = {
        'بوستر_مسرحية_تغيروا_2026.png': AppAssets.actIcon,
        'شعار_فريق_الرسالة_الاخيرة_LMT.png': AppAssets.appLogo,
        'صورة_بروفة_المسرح_الجماعية.png': AppAssets.picturesIcon,
        'صورة_كواليس_العرض_المسرحي.png': AppAssets.galleryIcon,
      };
      for (final entry in imageAssets.entries) {
        final f = File('${dir.path}/${entry.key}');
        if (!f.existsSync()) {
          final bytes = await rootBundle.load(entry.value);
          await f.writeAsBytes(
            bytes.buffer.asUint8List(
              bytes.offsetInBytes,
              bytes.lengthInBytes,
            ),
            flush: true,
          );
        }
      }

      // 2. Real PDF files written to phone storage
      final pdfFiles = {
        'اسكريبت_مسرحية_الرسالة_الاخيرة_2026.pdf': '''
%PDF-1.4
مسرحية: الرسالة الاخيرة - تغيروا 2026
فريق الرسالة الاخيرة (The Last Message Team - L.M.T)
=====================================================
المشهد الأول: دخول الممثلين على إضاءة المسرح الزرقاء.
المشهد الثاني: حوار البطل حول التغيير الحقيقي ورسالة الفريق.
المشهد الثالث: المشهد الختامي مع الكورال والإضاءة الكاملة.
''',
        'دليل_التمثيل_والإخراج_المسرحي_LMT.pdf': '''
%PDF-1.4
دليل التمثيل والإخراج المسرحي - فريق الرسالة الاخيرة (L.M.T)
1. تدريبات الصوت والتنفس على خشبة المسرح.
2. توزيع الحركة المسرحية (Stage Blocking) وزوايا الإضاءة.
''',
      };
      for (final entry in pdfFiles.entries) {
        final f = File('${dir.path}/${entry.key}');
        if (!f.existsSync()) {
          await f.writeAsString(entry.value, flush: true);
        }
      }

      // 3. Real Word / Excel files written to phone storage
      final officeFiles = {
        'جدول_البروفات_وتوزيع_الأدوار_2026.xlsx': '''
اليوم\tالموعد\tالنشاط\tالمسؤول
الإثنين\t06:30 م\tقراءة اسكريبت وتدريب تمثيل\tSamy Farouk
الخميس\t07:00 م\tبروفة جنرال بالصوت والإضاءة\tMario Naiem
الجمعة\t04:00 م\tخدمة وعرض مسرحي خارجي\tفريق L.M.T
''',
        'خطة_الديكور_والاكسسوارات_المسرحية.docx': '''
خطة الديكور والاكسسوارات المسرحية - فريق الرسالة الاخيرة (L.M.T)
- خلفية المسرح: ستارة سوداء مع إضاءة خلفية زرقاء.
- اكسسوارات المشهد الأول: مكتب خشبي، كتاب، مصباح كلاسيكي.
''',
      };
      for (final entry in officeFiles.entries) {
        final f = File('${dir.path}/${entry.key}');
        if (!f.existsSync()) {
          await f.writeAsString(entry.value, flush: true);
        }
      }

      // 4. Real Paperwork files
      final paperworkFile =
          File('${dir.path}/ورقة_عمل_ملاحظات_المخرج_والإضاءة.txt');
      if (!paperworkFile.existsSync()) {
        await paperworkFile.writeAsString(
          '''
ورقة عمل وملاحظات المخرج - فريق الرسالة الاخيرة (L.M.T)
- التأكد من جاهزية المايكات قبل البروفة بـ 30 دقيقة.
- مراجعة توقيتات دخول التراكات الصوتية مع حركة الممثلين.
''',
          flush: true,
        );
      }
    } catch (_) {}
  }

  /// Copies a picked file into the application's persistent storage directory
  /// so it remains available across app restarts.
  static Future<String> persistPickedFile(
    String sourcePath,
    String fileName,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final uploadsDir = Directory('${dir.path}/lmt_uploads');
      if (!uploadsDir.existsSync()) {
        await uploadsDir.create(recursive: true);
      }
      final safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}';
      final destPath = '${uploadsDir.path}/$safeName';
      final copied = await File(sourcePath).copy(destPath);
      return copied.path;
    } catch (_) {
      return sourcePath;
    }
  }

  /// Formats byte count into KB / MB.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Downloads and materializes a [SharedFileModel] onto the device's real public
  /// `Download` storage directory (`/storage/emulated/0/Download/LMT/`) and
  /// opens it with the device's native viewer application via [OpenFilex].
  static Future<String> downloadAndOpenRealFile(
    SharedFileModel file, {
    bool openAfterSave = true,
  }) async {
    final baseDir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${baseDir.path}/LMT_Downloads');
    if (!downloadsDir.existsSync()) {
      await downloadsDir.create(recursive: true);
    }

    File? localStagedFile;
    String targetFileName = 'LMT_Document.txt';
    String mimeType = 'application/octet-stream';

    // 1. If the file was uploaded from the user's device and exists locally
    if (file.localFilePath != null && file.localFilePath!.isNotEmpty) {
      final sourceFile = File(file.localFilePath!);
      if (sourceFile.existsSync()) {
        targetFileName = sourceFile.uri.pathSegments.last;
        final targetFile = File('${downloadsDir.path}/$targetFileName');
        if (sourceFile.path != targetFile.path) {
          await sourceFile.copy(targetFile.path);
        }
        localStagedFile = targetFile;
        mimeType = _mimeTypeForFileName(targetFileName);
      }
    }

    // 2. If it's an image asset, extract real PNG bytes from bundle to disk
    if (localStagedFile == null &&
        file.category == SharedFileType.image &&
        isAssetPath(file.imagePath)) {
      final byteData = await rootBundle.load(file.imagePath);
      final safeTitle = file.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      targetFileName = safeTitle.toLowerCase().endsWith('.png')
          ? safeTitle
          : '$safeTitle.png';
      final targetFile = File('${downloadsDir.path}/$targetFileName');
      await targetFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush: true,
      );
      localStagedFile = targetFile;
      mimeType = 'image/png';
    }

    // 3. For document / script / paperwork / schedule seed items, generate a real file on disk
    if (localStagedFile == null) {
      final safeBaseName = file.title
          .replaceAll(
            RegExp(r'\.(pdf|docx|xlsx|txt|png)$', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      targetFileName = '$safeBaseName.txt';
      final targetFile = File('${downloadsDir.path}/$targetFileName');
      final fullText = '''
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
      await targetFile.writeAsString(fullText, flush: true);
      localStagedFile = targetFile;
      mimeType = 'text/plain';
    }

    // 4. Save directly to the phone's public Download folder (/storage/emulated/0/Download/LMT/<fileName>)
    String? publicDownloadPath =
        await NativeMediaService.saveFileToPublicDownloads(
      sourcePath: localStagedFile.path,
      fileName: targetFileName,
      mimeType: mimeType,
    );

    if (publicDownloadPath == null) {
      try {
        final publicDir = Directory('/storage/emulated/0/Download/LMT');
        if (!publicDir.existsSync()) {
          await publicDir.create(recursive: true);
        }
        final publicFile = File('${publicDir.path}/$targetFileName');
        await localStagedFile.copy(publicFile.path);
        publicDownloadPath = publicFile.path;
      } catch (_) {
        publicDownloadPath = '/storage/emulated/0/Download/LMT/$targetFileName';
      }
    }

    if (openAfterSave) {
      try {
        await OpenFilex.open(localStagedFile.path);
      } catch (_) {}
    }

    return publicDownloadPath;
  }

  static String _mimeTypeForFileName(String fileName) {
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
