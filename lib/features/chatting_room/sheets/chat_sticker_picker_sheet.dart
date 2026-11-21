import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/utils/device_file_helper.dart';
import '../cubit/chat_cubit.dart';

/// Displays the WhatsApp-style Saved Stickers bottom sheet.
///
/// - Shows all user-saved stickers with tap-to-send and tap-close-to-delete.
/// - Shows a friendly empty state ("لا توجد أي ستيكرات محفوظة حالياً") when no
///   stickers are saved yet, with an "+ Add Sticker" button to save stickers
///   from the phone.
void showChatStickerPickerSheet({
  required BuildContext context,
  required String groupId,
  required List<String> initialSavedStickers,
  required ValueChanged<List<String>> onStickersUpdated,
  required ChatMessageModel? replyTo,
  required VoidCallback onStickerSent,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  List<String> currentStickers = List<String>.from(initialSavedStickers);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final primary = AppColors.primaryOf(ctx);
          final textPrimary = AppColors.textPrimaryOf(ctx);
          final textSecondary = AppColors.textSecondaryOf(ctx);

          return Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_emotions_rounded,
                      color: primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'الملصقات المحفوظة (Stickers)'
                            : 'Saved Stickers',
                        style: AppTypography.h5.copyWith(color: textPrimary),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await DeviceFileHelper.pickFileSafely(
                          ctx,
                          type: FileType.image,
                        );
                        if (picked != null && picked.path != null) {
                          final savedPath =
                              await DeviceFileHelper.persistPickedFile(
                            picked.path!,
                            picked.name,
                          );
                          currentStickers = [savedPath, ...currentStickers];
                          await AppPreferences.setSavedStickers(
                            currentStickers,
                          );
                          onStickersUpdated(currentStickers);
                          setModalState(() {});
                        }
                      },
                      icon: Icon(Icons.add_rounded, size: 18.sp),
                      label: Text(
                        isArabic ? 'حفظ ملصق' : 'Add Sticker',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                if (currentStickers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 28.h,
                      horizontal: 16.w,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: AppColors.borderOf(ctx)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 46.sp,
                          color: textSecondary,
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          isArabic
                              ? 'لا توجد أي ستيكرات محفوظة حالياً'
                              : 'No saved stickers found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isArabic
                              ? 'اضغط على "حفظ ملصق" لإضافة ستيكرات من هاتفك وإرسالها في المحادثة'
                              : 'Tap "Add Sticker" to save stickers from your phone and send them in chat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 260.h),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: currentStickers.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10.h,
                        crossAxisSpacing: 10.w,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (_, idx) {
                        final stickerPath = currentStickers[idx];
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14.r),
                                onTap: () {
                                  context.read<LmtCubit>().sendChatMessage(
                                        groupId: groupId,
                                        type: MessageType.sticker,
                                        content: 'ملصق',
                                        attachmentPath: stickerPath,
                                        replyTo: replyTo,
                                      );
                                  Navigator.pop(ctx);
                                  onStickerSent();
                                },
                                child: Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color: AppColors.borderOf(ctx),
                                    ),
                                  ),
                                  child: DeviceFileHelper.buildImage(
                                    stickerPath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () async {
                                  currentStickers = List<String>.from(
                                    currentStickers,
                                  )..removeAt(idx);
                                  await AppPreferences.setSavedStickers(
                                    currentStickers,
                                  );
                                  onStickersUpdated(currentStickers);
                                  setModalState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 12.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
