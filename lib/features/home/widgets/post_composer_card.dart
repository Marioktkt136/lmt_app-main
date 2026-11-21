import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';
import '../sheets/create_post_sheet.dart';
import 'composer_type_button.dart';

export '../sheets/create_post_sheet.dart' show showCreatePostModal;

/// Post creation prompt card at the top of the timeline feed.
///
/// Tapping the prompt or one of the quick buttons opens the create-post sheet
/// ([showCreatePostModal]) preselected with the matching [PostCategoryType].
class PostComposerCard extends StatelessWidget {
  /// The currently authenticated user.
  final MemberModel currentUser;

  /// Creates a [PostComposerCard].
  const PostComposerCard({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final firstName = currentUser.name.split(' ').first;
    void open(PostCategoryType type) =>
        showCreatePostModal(context, initialType: type);

    return LmtCard(
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(bottom: 12.h),
      borderRadius: 20.r,
      accentColor: primary,
      child: Column(
        children: [
          Row(
            children: [
              LmtAvatar(imagePath: currentUser.avatarPath, radius: 20),
              SizedBox(width: 10.w),
              Expanded(
                child: Semantics(
                  button: true,
                  label: isArabic ? 'إنشاء منشور' : 'Create a post',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24.r),
                    onTap: () => open(PostCategoryType.simple),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      alignment: AlignmentDirectional.centerStart,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
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
                            ? 'شارك إعلاناً أو منشوراً مع الفريق يا $firstName...'
                            : 'Share an announcement, poll, or media, $firstName...',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(color: AppColors.borderOf(context), height: 1),
          SizedBox(height: 4.h),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: [
              ComposerTypeButton(
                icon: Icons.article_outlined,
                color: primary,
                label: isArabic ? 'منشور نصي' : 'Simple Post',
                onTap: () => open(PostCategoryType.simple),
              ),
              ComposerTypeButton(
                icon: Icons.poll_outlined,
                color: AppColors.accentGreenOf(context),
                label: isArabic ? 'استطلاع رأي' : 'Poll Post',
                onTap: () => open(PostCategoryType.poll),
              ),
              ComposerTypeButton(
                icon: Icons.perm_media_outlined,
                color: const Color(0xFFF59E0B),
                label: isArabic ? 'صورة / فيديو' : 'Image / Video',
                onTap: () => open(PostCategoryType.media),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
