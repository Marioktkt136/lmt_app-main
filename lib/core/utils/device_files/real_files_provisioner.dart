import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../app_assets.dart';
import 'file_type.dart';
import 'platform_file.dart';

/// Scans phone storage for pickable files and provisions sample files so the
/// fallback picker always has real content to show.
class RealFilesProvisioner {
  RealFilesProvisioner._();

  static const _imageExts = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  /// Provisions sample files, then lists files from known storage folders,
  /// filtered by [type] and [allowedExtensions].
  static Future<List<PlatformFile>> scanAndProvision({
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final baseDir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final deviceBoxDir = Directory('${baseDir.path}/LMT_Phone_Storage');
    if (!deviceBoxDir.existsSync()) {
      await deviceBoxDir.create(recursive: true);
    }
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
    final allowed = allowedExtensions?.map((e) => e.toLowerCase()).toSet();

    for (final dir in candidateDirs) {
      try {
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(followLinks: false)) {
          if (entity is! File || seenPaths.contains(entity.path)) continue;
          final name = entity.uri.pathSegments.last;
          final dotIdx = name.lastIndexOf('.');
          final ext =
              dotIdx != -1 ? name.substring(dotIdx + 1).toLowerCase() : '';
          if (type == FileType.image) {
            if (!_imageExts.contains(ext)) continue;
          } else if (allowed != null && allowed.isNotEmpty) {
            if (!allowed.contains(ext)) continue;
          }
          seenPaths.add(entity.path);
          results.add(PlatformFile(
            name: name,
            path: entity.path,
            size: entity.lengthSync(),
          ));
        }
      } catch (_) {
        // Ignore directories restricted by Android scoped storage.
      }
    }
    return results;
  }

  static Future<void> _writeIfMissing(
    Directory dir,
    String name,
    Future<void> Function(File f) write,
  ) async {
    final f = File('${dir.path}/$name');
    if (!f.existsSync()) await write(f);
  }

  static Future<void> _ensureRealFilesOnDisk(Directory dir) async {
    try {
      final imageAssets = {
        'بوستر_مسرحية_تغيروا_2026.png': AppAssets.actIcon,
        'شعار_فريق_الرسالة_الاخيرة_LMT.png': AppAssets.appLogo,
        'صورة_بروفة_المسرح_الجماعية.png': AppAssets.picturesIcon,
        'صورة_كواليس_العرض_المسرحي.png': AppAssets.galleryIcon,
      };
      for (final entry in imageAssets.entries) {
        await _writeIfMissing(dir, entry.key, (f) async {
          final bytes = await rootBundle.load(entry.value);
          await f.writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
            flush: true,
          );
        });
      }
      for (final entry in _textFiles.entries) {
        await _writeIfMissing(
          dir,
          entry.key,
          (f) => f.writeAsString(entry.value, flush: true),
        );
      }
    } catch (_) {}
  }

  static const Map<String, String> _textFiles = {
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
    'ورقة_عمل_ملاحظات_المخرج_والإضاءة.txt': '''
ورقة عمل وملاحظات المخرج - فريق الرسالة الاخيرة (L.M.T)
- التأكد من جاهزية المايكات قبل البروفة بـ 30 دقيقة.
- مراجعة توقيتات دخول التراكات الصوتية مع حركة الممثلين.
''',
  };
}
