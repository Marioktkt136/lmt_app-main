import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/posts_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays the post creation prompt card at the top of the timeline feed.
class PostComposerCard extends StatelessWidget {
  /// The currently authenticated user.
  final MemberModel currentUser;

  /// Creates a [PostComposerCard].
  const PostComposerCard({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    return LmtCard(
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(bottom: 12.h),
      borderRadius: 20.r,
      accentColor: primary,
      child: Column(
        children: [
          Row(
            children: [
              LmtAvatar(
                imagePath: currentUser.avatarPath,
                radius: 20,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24.r),
                  onTap: () => showCreatePostModal(
                    context,
                    initialType: PostCategoryType.simple,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.25),
                      ),
                      boxShadow: AppColors.cardShadows(
                        context,
                        accent: primary,
                        intensity: 0.35,
                      ),
                    ),
                    child: Text(
                      isArabic
                          ? 'شارك إعلاناً أو منشوراً مع الفريق يا ${currentUser.name.split(' ').first}...'
                          : 'Share an announcement, poll, or media, ${currentUser.name.split(' ').first}...',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(color: border, height: 1),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ComposerTypeButton(
                icon: Icons.article_outlined,
                color: primary,
                label: isArabic ? 'منشور نصي' : 'Simple Post',
                onTap: () => showCreatePostModal(
                  context,
                  initialType: PostCategoryType.simple,
                ),
              ),
              _ComposerTypeButton(
                icon: Icons.poll_outlined,
                color: accentGreen,
                label: isArabic ? 'استطلاع رأي' : 'Poll Post',
                onTap: () => showCreatePostModal(
                  context,
                  initialType: PostCategoryType.poll,
                ),
              ),
              _ComposerTypeButton(
                icon: Icons.perm_media_outlined,
                color: const Color(0xFFF59E0B),
                label: isArabic ? 'صورة / فيديو' : 'Image / Video',
                onTap: () => showCreatePostModal(
                  context,
                  initialType: PostCategoryType.media,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerTypeButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ComposerTypeButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a modal bottom sheet for creating a Simple, Poll, or Media post.
void showCreatePostModal(
  BuildContext context, {
  required PostCategoryType initialType,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  PostCategoryType selectedType = initialType;
  final contentCtrl = TextEditingController();
  final option1Ctrl =
      TextEditingController(text: isArabic ? 'جاي أكيد 🎭' : 'Attending 🎭');
  final option2Ctrl = TextEditingController(
    text: isArabic ? 'مش جاي للأسف' : 'Cannot attend',
  );
  final option3Ctrl = TextEditingController();
  String selectedMediaAsset = AppAssets.actIcon;
  bool isVideoMedia = false;

  final availableMedia = [
    AppAssets.actIcon,
    AppAssets.appLogo,
    AppAssets.picturesIcon,
    AppAssets.youtubeIcon,
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

          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 18.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            ),
            child: SingleChildScrollView(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'إنشاء منشور جديد في التايم لاين 📢'
                          : 'Create New Timeline Post 📢',
                      style: AppTypography.h4.copyWith(color: textPrimary),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            selected: selectedType == PostCategoryType.simple,
                            onSelected: (_) => setModalState(
                              () => selectedType = PostCategoryType.simple,
                            ),
                            label: Text(isArabic ? 'نصي' : 'Simple'),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: ChoiceChip(
                            selected: selectedType == PostCategoryType.poll,
                            onSelected: (_) => setModalState(
                              () => selectedType = PostCategoryType.poll,
                            ),
                            label: Text(isArabic ? 'استطلاع' : 'Poll'),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: ChoiceChip(
                            selected: selectedType == PostCategoryType.media,
                            onSelected: (_) => setModalState(
                              () => selectedType = PostCategoryType.media,
                            ),
                            label: Text(isArabic ? 'صورة/فيديو' : 'Media'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText:
                            isArabic ? 'محتوى المنشور' : 'Post Content',
                        hintText: isArabic
                            ? 'اكتب تفاصيل الإعلان أو موعد البروفة...'
                            : 'Write your announcement or post details...',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (selectedType == PostCategoryType.poll) ...[
                      Text(
                        isArabic
                            ? 'خيارات التصويت (Poll Options):'
                            : 'Poll Options:',
                        style: AppTypography.labelLarge.copyWith(
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: option1Ctrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الخيار الأول' : 'Option 1',
                          prefixIcon: const Icon(Icons.looks_one_outlined),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: option2Ctrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الخيار الثاني' : 'Option 2',
                          prefixIcon: const Icon(Icons.looks_two_outlined),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: option3Ctrl,
                        decoration: InputDecoration(
                          labelText: isArabic
                              ? 'الخيار الثالث (اختياري)'
                              : 'Option 3 (Optional)',
                          prefixIcon: const Icon(Icons.looks_3_outlined),
                        ),
                      ),
                    ],
                    if (selectedType == PostCategoryType.media) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          isArabic
                              ? 'منشور فيديو (Video Post)'
                              : 'Video Post',
                          style:
                              TextStyle(color: textPrimary, fontSize: 13.sp),
                        ),
                        value: isVideoMedia,
                        onChanged: (v) =>
                            setModalState(() => isVideoMedia = v),
                      ),
                      Text(
                        isArabic
                            ? 'اختر الصورة أو المصغرة المرفقة:'
                            : 'Select Attached Media:',
                        style: AppTypography.labelLarge.copyWith(
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 80.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: availableMedia.length,
                          separatorBuilder: (_, _) => SizedBox(width: 10.w),
                          itemBuilder: (_, idx) {
                            final img = availableMedia[idx];
                            final selected = selectedMediaAsset == img;
                            return GestureDetector(
                              onTap: () => setModalState(
                                () => selectedMediaAsset = img,
                              ),
                              child: Container(
                                width: 80.w,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: selected
                                        ? primary
                                        : AppColors.borderOf(ctx),
                                    width: selected ? 2.5 : 1,
                                  ),
                                ),
                                child: Image.asset(img, fit: BoxFit.contain),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (contentCtrl.text.trim().isEmpty) return;
                          context.read<LmtCubit>().createPost(
                                type: selectedType,
                                content: contentCtrl.text,
                                mediaPath:
                                    selectedType == PostCategoryType.media
                                        ? selectedMediaAsset
                                        : null,
                                isVideo: isVideoMedia,
                                videoUrl: isVideoMedia
                                    ? 'https://www.youtube.com'
                                    : null,
                                pollOptionsText:
                                    selectedType == PostCategoryType.poll
                                        ? [
                                            option1Ctrl.text,
                                            option2Ctrl.text,
                                            option3Ctrl.text,
                                          ]
                                        : const [],
                              );
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.publish_rounded),
                        label: Text(
                          isArabic ? 'نشر في التايم لاين' : 'Publish Post',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
