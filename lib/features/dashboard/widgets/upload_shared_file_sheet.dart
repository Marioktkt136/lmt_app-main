import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/shared_files_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';

/// Displays a modal bottom sheet for uploading a real file from the phone's
/// storage via [FilePicker] or adding an external hyperlink card.
void showUploadSharedFileSheet(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  SharedFileType selectedCategory = SharedFileType.pdf;
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final urlCtrl = TextEditingController();

  String? pickedLocalPath;
  String? pickedFileName;
  String pickedFileSize = '1.2 MB';
  String pickedExtension = 'PDF';

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

          Future<void> pickFileFromPhone() async {
            FileType pickerType = FileType.any;
            List<String>? allowedExtensions;

            if (selectedCategory == SharedFileType.image) {
              pickerType = FileType.image;
            } else if (selectedCategory == SharedFileType.pdf) {
              pickerType = FileType.custom;
              allowedExtensions = ['pdf'];
            } else if (selectedCategory == SharedFileType.wordExcel) {
              pickerType = FileType.custom;
              allowedExtensions = ['doc', 'docx', 'xls', 'xlsx', 'csv'];
            }

            final f = await DeviceFileHelper.pickFileSafely(
              ctx,
              type: pickerType,
              allowedExtensions: allowedExtensions,
            );

            if (f != null && f.path != null) {
              final persistedPath = await DeviceFileHelper.persistPickedFile(
                f.path!,
                f.name,
              );
              setModalState(() {
                pickedLocalPath = persistedPath;
                pickedFileName = f.name;
                pickedFileSize = DeviceFileHelper.formatBytes(f.size);
                pickedExtension =
                    (f.extension ?? selectedCategory.name).toUpperCase();
                if (titleCtrl.text.trim().isEmpty) {
                  titleCtrl.text = f.name;
                }
              });
            }
          }

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
                        ? 'رفع ملف مشترك من الهاتف أو بطاقة رابط 📁'
                        : 'Upload Shared File from Phone or Add Link 📁',
                    style: AppTypography.h4.copyWith(color: textPrimary),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: SharedFileType.values.map((cat) {
                      return ChoiceChip(
                        selected: selectedCategory == cat,
                        onSelected: (_) =>
                            setModalState(() => selectedCategory = cat),
                        label: Text(cat.label(isArabic)),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 14.h),

                  // Native File Picker Zone (for all file types except Hyperlink Card)
                  if (selectedCategory != SharedFileType.card) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(18.r),
                      onTap: pickFileFromPhone,
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
                                selectedCategory == SharedFileType.image)
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
                                      ? 'اضغط هنا لاختيار ورفع ملف من هاتفك 📱'
                                      : 'Tap here to choose a file from your phone 📱'),
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
                                      ? 'يدعم ملفات PDF، Word، Excel، الصور، والمستندات من الموبايل'
                                      : 'Supports PDF, Word, Excel, Images & Documents from device'),
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
                      labelText:
                          isArabic ? 'عنوان الملف أو البطاقة' : 'Title',
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
                  if (selectedCategory == SharedFileType.card) ...[
                    SizedBox(height: 10.h),
                    TextField(
                      controller: urlCtrl,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'الرابط الخارجي (Hyperlink URL 🔗)'
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
                        if (selectedCategory != SharedFileType.card &&
                            pickedLocalPath == null &&
                            titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? 'يرجى اختيار ملف من هاتفك أولاً 📱'
                                    : 'Please pick a file from your device first 📱',
                              ),
                              backgroundColor: AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (titleCtrl.text.trim().isEmpty &&
                            pickedFileName != null) {
                          titleCtrl.text = pickedFileName!;
                        }
                        if (titleCtrl.text.trim().isEmpty) return;

                        final ext = pickedLocalPath != null
                            ? pickedExtension
                            : switch (selectedCategory) {
                                SharedFileType.pdf => 'PDF',
                                SharedFileType.wordExcel => 'DOCX/XLSX',
                                SharedFileType.paperwork => 'PAPERWORK',
                                SharedFileType.image => 'PNG',
                                SharedFileType.card => 'LINK 🔗',
                              };
                        final iconAsset = switch (selectedCategory) {
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
                              category: selectedCategory,
                              imagePath: iconAsset,
                              fileExtension: ext,
                              fileSize: pickedLocalPath != null
                                  ? pickedFileSize
                                  : '1.5 MB',
                              externalUrl: urlCtrl.text,
                              localFilePath: pickedLocalPath,
                            );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        isArabic ? 'رفع وحفظ الملف' : 'Upload & Save',
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
