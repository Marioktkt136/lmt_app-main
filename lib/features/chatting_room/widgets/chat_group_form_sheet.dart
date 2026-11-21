import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/chat_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';

/// Displays a modal bottom sheet for creating or editing a chatting group,
/// supporting custom group image selection from the user's phone storage.
void showChatGroupFormSheet(
  BuildContext context,
  LmtState state, {
  ChatGroupModel? existingGroup,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final nameCtrl = TextEditingController(text: existingGroup?.name ?? '');
  final descCtrl =
      TextEditingController(text: existingGroup?.description ?? '');
  String selectedImage = existingGroup?.imagePath ?? AppAssets.actIcon;
  final selectedMembers = Set<String>.from(
    existingGroup?.memberIds ?? state.members.map((m) => m.id),
  );

  final availableIcons = [
    AppAssets.appLogo,
    AppAssets.actIcon,
    AppAssets.postIcon,
    AppAssets.videoIcon,
    AppAssets.calendarIcon,
    AppAssets.prayIcon,
  ];

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
          final textPrimary = AppColors.textPrimaryOf(ctx);

          Future<void> pickGroupImageFromPhone() async {
            final file = await DeviceFileHelper.pickFileSafely(
              ctx,
              type: FileType.image,
            );
            if (file != null && file.path != null) {
              final savedPath = await DeviceFileHelper.persistPickedFile(
                file.path!,
                file.name,
              );
              setModalState(() => selectedImage = savedPath);
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
                    existingGroup == null
                        ? (isArabic
                            ? 'إنشاء مجموعة محادثة جديدة 💬'
                            : 'Create New Chatting Group 💬')
                        : (isArabic
                            ? 'تعديل مجموعة المحادثة ✏️'
                            : 'Update Chatting Group ✏️'),
                    style: AppTypography.h4.copyWith(color: textPrimary),
                  ),
                  SizedBox(height: 14.h),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'اسم المجموعة' : 'Group Name',
                      prefixIcon: const Icon(Icons.groups_rounded),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText:
                          isArabic ? 'وصف المجموعة' : 'Group Description',
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    isArabic
                        ? 'صورة المجموعة (من هاتفك أو الأيقونات):'
                        : 'Group Image (From Phone or Presets):',
                    style: AppTypography.labelLarge.copyWith(
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: pickGroupImageFromPhone,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 30.r,
                              backgroundColor: primary.withValues(alpha: 0.15),
                              backgroundImage:
                                  DeviceFileHelper.imageProviderFor(
                                selectedImage,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_a_photo_rounded,
                                size: 13.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickGroupImageFromPhone,
                          icon: const Icon(Icons.photo_library_rounded),
                          label: Text(
                            isArabic
                                ? 'اختيار صورة من الموبايل 📱'
                                : 'Pick Image from Phone 📱',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 48.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableIcons.length,
                      separatorBuilder: (_, _) => SizedBox(width: 10.w),
                      itemBuilder: (_, idx) {
                        final img = availableIcons[idx];
                        final isSelected = selectedImage == img;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedImage = img),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected ? primary : Colors.transparent,
                                width: 2.2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 19.r,
                              backgroundImage: AssetImage(img),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    isArabic ? 'أعضاء المجموعة:' : 'Group Members:',
                    style: AppTypography.labelLarge.copyWith(
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: state.members.map((m) {
                      final isSelected = selectedMembers.contains(m.id);
                      return FilterChip(
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              selectedMembers.add(m.id);
                            } else if (selectedMembers.length > 1) {
                              selectedMembers.remove(m.id);
                            }
                          });
                        },
                        label: Text('${m.name} (${m.role.badgeEmoji})'),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        if (existingGroup == null) {
                          context.read<LmtCubit>().createChatGroup(
                                name: nameCtrl.text,
                                description: descCtrl.text.trim().isEmpty
                                    ? 'مجموعة تابعة لفريق الرسالة الاخيرة'
                                    : descCtrl.text,
                                imagePath: selectedImage,
                                memberIds: selectedMembers.toList(),
                              );
                        } else {
                          context.read<LmtCubit>().updateChatGroup(
                                existingGroup.copyWith(
                                  name: nameCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  imagePath: selectedImage,
                                  memberIds: selectedMembers.toList(),
                                ),
                              );
                        }
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        existingGroup == null
                            ? (isArabic ? 'إنشاء المجموعة' : 'Create Group')
                            : (isArabic ? 'حفظ التعديلات' : 'Save Changes'),
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
