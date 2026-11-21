import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cubit/posts_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays an individual timeline post card supporting Simple text, Poll voting
/// (with toggle-to-unvote), and Image/Video media attachments.
class TimelinePostCard extends StatelessWidget {
  /// The post model to render.
  final PostModel post;

  /// The currently authenticated user.
  final MemberModel currentUser;

  /// Callback invoked when the comments button is pressed.
  final VoidCallback onShowComments;

  /// Creates a [TimelinePostCard].
  const TimelinePostCard({
    super.key,
    required this.post,
    required this.currentUser,
    required this.onShowComments,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);
    final isLiked = post.likedByIds.contains(currentUser.id);
    final canDelete = post.creatorId == currentUser.id ||
        currentUser.role == UserRole.admin ||
        currentUser.role == UserRole.editor;
    final hasVotedAny = post.pollOptions
        .any((opt) => opt.voterIds.contains(currentUser.id));

    return LmtCard(
      padding: EdgeInsets.all(15.w),
      borderRadius: 22.r,
      accentColor: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Creator Header & Publish Time
          Row(
            children: [
              LmtAvatar(
                imagePath: post.creatorAvatar,
                radius: 21,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.creatorName,
                            style: AppTypography.h6.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(post.creatorRole.badgeEmoji),
                      ],
                    ),
                    Text(
                      '${DateFormat('EEE, dd MMM yyyy • hh:mm a').format(post.publishTime)} • ${post.creatorCommittee}',
                      style: TextStyle(fontSize: 10.5.sp, color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19.sp,
                    color: textSecondary,
                  ),
                  onPressed: () =>
                      context.read<LmtCubit>().deletePost(post.id),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // Post Text Content
          Text(
            post.content,
            style: AppTypography.bodyMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),

          // Poll Section (Supports voting and unvoting on second tap)
          if (post.type == PostCategoryType.poll &&
              post.pollOptions.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ...post.pollOptions.map((option) {
              final totalVotes = post.totalPollVotes;
              final optionVotes = option.voterIds.length;
              final ratio =
                  totalVotes == 0 ? 0.0 : (optionVotes / totalVotes);
              final isSelectedByMe = option.voterIds.contains(currentUser.id);

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: LmtCard(
                  padding: EdgeInsets.all(11.w),
                  borderRadius: 14.r,
                  accentColor: isSelectedByMe ? accentGreen : primary,
                  isHighlighted: isSelectedByMe,
                  shadowIntensity: isSelectedByMe ? 0.85 : 0.45,
                  onTap: () => context.read<LmtCubit>().voteOnPoll(
                        postId: post.id,
                        optionId: option.id,
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelectedByMe
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18.sp,
                            color:
                                isSelectedByMe ? accentGreen : textSecondary,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              option.text,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: isSelectedByMe
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$optionVotes (${(ratio * 100).round()}%)',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelectedByMe
                                  ? accentGreen
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6.h,
                          color: isSelectedByMe ? accentGreen : primary,
                          backgroundColor: border,
                        ),
                      ),
                      if (isSelectedByMe) ...[
                        SizedBox(height: 5.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 12.sp,
                              color: accentGreen,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              isArabic
                                  ? 'تم التصويت • اضغط مرة أخرى لإلغاء صوتك'
                                  : 'Voted • Tap again to remove your vote',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            if (hasVotedAny)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  isArabic
                      ? 'إجمالي الأصوات: ${post.totalPollVotes}'
                      : 'Total votes: ${post.totalPollVotes}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],

          // Image / Video Section
          if (post.type == PostCategoryType.media) ...[
            SizedBox(height: 12.h),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: AppColors.cardShadows(
                  context,
                  accent: primary,
                  intensity: 0.7,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 175.h,
                      width: double.infinity,
                      color: primary.withValues(alpha: 0.08),
                      child: Image.asset(
                        post.mediaPath ?? AppAssets.actIcon,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (post.isVideo)
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: EdgeInsets.all(14.w),
                        ),
                        onPressed: () async {
                          if (post.videoUrl != null) {
                            final uri = Uri.parse(post.videoUrl!);
                            await launchUrl(uri);
                          }
                        },
                        icon: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 10.h),
          Divider(color: border, height: 1),
          SizedBox(height: 6.h),

          // Like Reactions & Comments Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () =>
                    context.read<LmtCubit>().toggleLikePost(post.id),
                icon: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked ? AppColors.error : textSecondary,
                  size: 20.sp,
                ),
                label: Text(
                  '${post.likedByIds.length} ${isArabic ? 'إعجاب' : 'Likes'}',
                  style: TextStyle(
                    color: isLiked ? AppColors.error : textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onShowComments,
                icon: Icon(
                  Icons.mode_comment_outlined,
                  color: primary,
                  size: 19.sp,
                ),
                label: Text(
                  '${post.comments.length} ${isArabic ? 'تعليق' : 'Comments'}',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
