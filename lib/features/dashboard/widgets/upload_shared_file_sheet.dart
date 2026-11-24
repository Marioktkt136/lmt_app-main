import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';
import '../cubit/shared_files_cubit.dart';

enum _SharedUploadMode { file, hyperlink }

/// Displays a clean modal bottom sheet with **two options**:
/// 1. Upload ANY file format from the phone's file storage (`FileType.any`).
/// 2. Add an External Hyperlink URL (`SharedFileType.card`).
void showUploadSharedFileSheet(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  _SharedUploadMode mode = _SharedUploadMode.file;

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final urlCtrl = TextEditingController();

  String? pickedLocalPath;
  String? pickedFileName;
  String pickedFileSize = '1.2 MB';
  String pickedExtension = 'FILE';
  SharedFileType resolvedFileCategory = SharedFileType.paperwork;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final primary = AppColors.primaryOf(ctx);
          final accentGreen = AppColors.accentGreenOf(ctx);
          final textPrimary = AppColors.textPrimaryOf(ctx);
          final textSecondary = AppColors.textSecondaryOf(ctx);

          Future<void> pickAnyFileFromPhone() async {
            final f = await DeviceFileHelper.pickFileSafely(
              ctx,
              type: FileType.any,
            );
            if (f != null && f.path != null) {
              final persistedPath = await DeviceFileHelper.persistPickedFile(
                f.path!,
                f.name,
              );
              final ext = (f.extension ?? 'FILE').toLowerCase();
              final inferredCategory = switch (ext) {
                'pdf' => SharedFileType.pdf,
                'png' || 'jpg' || 'jpeg' || 'webp' || 'gif' =>
                  SharedFileType.image,
                'doc' || 'docx' || 'xls' || 'xlsx' || 'csv' || 'ppt' || 'pptx' =>
                  SharedFileType.wordExcel,
                _ => SharedFileType.paperwork,
              };

              setModalState(() {
                pickedLocalPath = persistedPath;
                pickedFileName = f.name;
                pickedFileSize = DeviceFileHelper.formatBytes(f.size);
                pickedExtension = ext.toUpperCase();
                resolvedFileCategory = inferredCategory;
                if (titleCtrl.text.trim().isEmpty) {
                  titleCtrl.text = f.name;
                }
              });
            }
          }

          final isFileMode = mode == _SharedUploadMode.file;

          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 18.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? 'رفع ملف من الهاتف أو إضافة رابط خارجي 📁'
                        : 'Upload Shared File or External Link 📁',
                    style: AppTypography.h4.copyWith(color: textPrimary),
                  ),
                  SizedBox(height: 12.h),

                  // Clean Two-Option Switch: Phone File (All Formats) vs External Hyperlink URL
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          selected: isFileMode,
                          onSelected: (_) => setModalState(
                            () => mode = _SharedUploadMode.file,
                          ),
                          avatar: Icon(
                            Icons.upload_file_rounded,
                            size: 17.sp,
                            color: isFileMode ? primary : textSecondary,
                          ),
                          label: Text(
                            isArabic ? 'رفع ملف (كل الصيغ)' : 'Upload File',
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ChoiceChip(
                          selected: !isFileMode,
                          onSelected: (_) => setModalState(
                            () => mode = _SharedUploadMode.hyperlink,
                          ),
                          avatar: Icon(
                            Icons.link_rounded,
                            size: 17.sp,
                            color: !isFileMode ? primary : textSecondary,
                          ),
                          label: Text(
                            isArabic ? 'رابط خارجي 🔗' : 'External URL 🔗',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  if (isFileMode) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(18.r),
                      onTap: pickAnyFileFromPhone,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 18.h,
                        ),
                        decoration: AppColors.cardDecoration(
                          ctx,
                          radius: 18.r,
                          accentColor:
                              pickedLocalPath != null ? accentGreen : primary,
                          isHighlighted: true,
                        ),
                        child: Column(
                          children: [
                            if (pickedLocalPath != null &&
                                resolvedFileCategory == SharedFileType.image)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: SizedBox(
                                  height: 110.h,
                                  child: DeviceFileHelper.buildImage(
                                    pickedLocalPath!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                pickedLocalPath != null
                                    ? Icons.check_circle_rounded
                                    : Icons.cloud_upload_rounded,
                                size: 40.sp,
                                color: pickedLocalPath != null
                                    ? accentGreen
                                    : primary,
                              ),
                            SizedBox(height: 8.h),
                            Text(
                              pickedFileName ??
                                  (isArabic
                                      ? 'اضغط لاختيار أي ملف من هاتفك 📱'
                                      : 'Tap here to choose any file from your phone 📱'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: pickedLocalPath != null
                                    ? accentGreen
                                    : textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              pickedLocalPath != null
                                  ? '$pickedExtension • $pickedFileSize • ${isArabic ? 'اضغط لتغيير الملف' : 'Tap to change file'}'
                                  : (isArabic
                                      ? 'يدعم رفع جميع الصيغ المتاحة من الموبايل (PDF, Word, Excel, Images, Videos, Audio...)'
                                      : 'Supports all file formats from your device'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: isFileMode
                          ? (isArabic ? 'عنوان الملف' : 'File Title')
                          : (isArabic ? 'عنوان الرابط' : 'Link Title'),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الوصف' : 'Description',
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                  if (!isFileMode) ...[
                    SizedBox(height: 10.h),
                    TextField(
                      controller: urlCtrl,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'الرابط الخارجي (External Hyperlink URL 🔗)'
                            : 'External Hyperlink URL 🔗',
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.link_rounded),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        void showValidationAlert(String message) {
                          showDialog<void>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isArabic ? 'تنبيه' : 'Notice'),
                                ],
                              ),
                              content: Text(message),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: Text(isArabic ? 'حسناً' : 'OK'),
                                ),
                              ],
                            ),
                          );
                        }

                        if (isFileMode && pickedLocalPath == null) {
                          showValidationAlert(
                            isArabic
                                ? 'يرجى اختيار ملف من هاتفك أولاً 📱'
                                : 'Please pick a file from your device first 📱',
                          );
                          return;
                        }
                        if (!isFileMode && urlCtrl.text.trim().isEmpty) {
                          showValidationAlert(
                            isArabic
                                ? 'يرجى إدخال الرابط الخارجي (URL) أولاً 🔗'
                                : 'Please enter an external URL first 🔗',
                          );
                          return;
                        }

                        if (titleCtrl.text.trim().isEmpty &&
                            pickedFileName != null) {
                          titleCtrl.text = pickedFileName!;
                        }
                        if (titleCtrl.text.trim().isEmpty) return;

                        final finalCategory = isFileMode
                            ? resolvedFileCategory
                            : SharedFileType.card;
                        final iconAsset = switch (finalCategory) {
                          SharedFileType.pdf => AppAssets.reviewIcon,
                          SharedFileType.wordExcel => AppAssets.formIcon,
                          SharedFileType.paperwork => AppAssets.postIcon,
                          SharedFileType.image =>
                            pickedLocalPath ?? AppAssets.picturesIcon,
                          SharedFileType.card => AppAssets.driveIcon,
                        };

                        context.read<LmtCubit>().addSharedFile(
                              title: titleCtrl.text,
                              description: descCtrl.text.trim().isEmpty
                                  ? 'ملف مرفوع لفريق الرسالة الاخيرة'
                                  : descCtrl.text,
                              category: finalCategory,
                              imagePath: iconAsset,
                              fileExtension: isFileMode ? pickedExtension : 'LINK 🔗',
                              fileSize: isFileMode ? pickedFileSize : 'Link',
                              externalUrl: isFileMode ? null : urlCtrl.text.trim(),
                              localFilePath: isFileMode ? pickedLocalPath : null,
                            );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        isArabic ? 'حفظ ونشر' : 'Upload & Save',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Displays a bottom sheet for Admin/Editor users to edit an existing shared
/// file or hyperlink card's title, description, or URL.
void showEditSharedFileSheet(
  BuildContext context,
  SharedFileModel existingFile,
) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final titleCtrl = TextEditingController(text: existingFile.title);
  final descCtrl = TextEditingController(text: existingFile.description);
  final urlCtrl = TextEditingController(text: existingFile.externalUrl ?? '');
  final isLinkCard = existingFile.category == SharedFileType.card;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 18.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'تعديل بيانات الملف / الرابط ✏️' : 'Edit Shared Item ✏️',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimaryOf(ctx),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: isArabic ? 'العنوان' : 'Title',
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الوصف' : 'Description',
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              if (isLinkCard) ...[
                SizedBox(height: 10.h),
                TextField(
                  controller: urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الرابط الخارجي' : 'External URL',
                    prefixIcon: const Icon(Icons.link_rounded),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    await context.read<LmtCubit>().updateSharedFile(
                          fileId: existingFile.id,
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          externalUrl: isLinkCard ? urlCtrl.text : null,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(isArabic ? 'حفظ التعديلات' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
