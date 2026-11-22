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
///
/// When creating a **new** group, only the creator (`state.currentUser`) is
/// automatically included (pinned as creator), and all other members start
/// **unselected** with a live member search bar so admins/editors can quickly
/// search and pick exactly who joins the group.
void showChatGroupFormSheet(
  BuildContext context,
  LmtState state, {
  ChatGroupModel? existingGroup,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final nameCtrl = TextEditingController(text: existingGroup?.name ?? '');
  final descCtrl =
      TextEditingController(text: existingGroup?.description ?? '');
  final searchMembersCtrl = TextEditingController();
  String selectedImage = existingGroup?.imagePath ?? AppAssets.actIcon;

  final creatorId = existingGroup?.adminId ?? state.currentUser.id;
  final selectedMembers = Set<String>.from(
    existingGroup?.memberIds ?? <String>{creatorId},
  )..add(creatorId);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      String memberQuery = '';
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final primary = AppColors.primaryOf(ctx);
          final accentGreen = AppColors.accentGreenOf(ctx);
          final textPrimary = AppColors.textPrimaryOf(ctx);
          final textSecondary = AppColors.textSecondaryOf(ctx);

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

          final otherMembers =
              state.members.where((m) => m.id != creatorId).toList();
          final filteredOtherMembers = otherMembers.where((m) {
            if (memberQuery.trim().isEmpty) return true;
            final q = memberQuery.trim().toLowerCase();
            return m.name.toLowerCase().contains(q) ||
                m.id.toLowerCase().contains(q) ||
                m.specialistAt.toLowerCase().contains(q) ||
                m.committee.toLowerCase().contains(q);
          }).toList();

          final creatorMember =
              state.members.where((m) => m.id == creatorId).firstOrNull ??
                  state.currentUser;

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
                        ? 'صورة المجموعة (من هاتفك):'
                        : 'Group Image (From Your Phone):',
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
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'أعضاء المجموعة:' : 'Group Members:',
                        style: AppTypography.labelLarge.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isArabic
                            ? 'المختارون: ${selectedMembers.length}'
                            : 'Selected: ${selectedMembers.length}',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  // Creator (Automatically included — no manual selection needed)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: accentGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16.sp,
                          color: accentGreen,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            '${creatorMember.name} (${creatorMember.role.badgeEmoji}) — ${isArabic ? 'منشئ المجموعة (مضاف تلقائياً)' : 'Group Creator (Included automatically)'}',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Member Search Bar
                  TextField(
                    controller: searchMembersCtrl,
                    onChanged: (v) => setModalState(() => memberQuery = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: isArabic
                          ? 'ابحث عن عضو بالاسم، الكود، القسم، أو اللجنة...'
                          : 'Search members by name, ID, dept, committee...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: memberQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                searchMembersCtrl.clear();
                                setModalState(() => memberQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  if (filteredOtherMembers.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        isArabic
                            ? 'لا يوجد أعضاء مطابقون لبحثك'
                            : 'No matching members found',
                        style: TextStyle(fontSize: 12.sp, color: textSecondary),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: filteredOtherMembers.map((m) {
                        final isSelected = selectedMembers.contains(m.id);
                        return FilterChip(
                          selected: isSelected,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedMembers.add(m.id);
                              } else {
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
                        final finalMemberIds = <String>{
                          creatorId,
                          ...selectedMembers,
                        }.toList();

                        if (existingGroup == null) {
                          context.read<LmtCubit>().createChatGroup(
                                name: nameCtrl.text,
                                description: descCtrl.text.trim().isEmpty
                                    ? 'مجموعة تابعة لفريق الرسالة الاخيرة'
                                    : descCtrl.text,
                                imagePath: selectedImage,
                                memberIds: finalMemberIds,
                              );
                        } else {
                          context.read<LmtCubit>().updateChatGroup(
                                existingGroup.copyWith(
                                  name: nameCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  imagePath: selectedImage,
                                  memberIds: finalMemberIds,
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
