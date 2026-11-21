import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/posts_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays a modal bottom sheet for viewing and adding comments on a [PostModel].
void showPostCommentsSheet(BuildContext context, PostModel post) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final commentCtrl = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return BlocBuilder<LmtCubit, LmtState>(
        builder: (ctx, state) {
          final livePost =
              state.posts.where((p) => p.id == post.id).firstOrNull ?? post;
          final textPrimary = AppColors.textPrimaryOf(ctx);
          final textSecondary = AppColors.textSecondaryOf(ctx);
          final primary = AppColors.primaryOf(ctx);

          return Padding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 16.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'التعليقات (${livePost.comments.length}) 💬'
                      : 'Comments (${livePost.comments.length}) 💬',
                  style: AppTypography.h5.copyWith(color: textPrimary),
                ),
                SizedBox(height: 12.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 280.h),
                  child: livePost.comments.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              isArabic
                                  ? 'كن أول من يعلق على هذا المنشور!'
                                  : 'Be the first to comment on this post!',
                              style: TextStyle(color: textSecondary),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: livePost.comments.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 12),
                          itemBuilder: (_, idx) {
                            final c = livePost.comments[idx];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LmtAvatar(
                                  imagePath: c.authorAvatar,
                                  radius: 16,
                                  showShadow: false,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: LmtCard(
                                    padding: EdgeInsets.all(10.w),
                                    borderRadius: 12.r,
                                    shadowIntensity: 0.45,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${c.authorName} ${c.authorRole.badgeEmoji}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.sp,
                                                color: primary,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('dd/MM hh:mm a')
                                                  .format(c.createdAt),
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          c.content,
                                          style: TextStyle(
                                            fontSize: 12.5.sp,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        decoration: InputDecoration(
                          hintText: isArabic
                              ? 'اكتب تعليقاً...'
                              : 'Write a comment...',
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: primary),
                      onPressed: () {
                        if (commentCtrl.text.trim().isEmpty) return;
                        context.read<LmtCubit>().addPostComment(
                              postId: livePost.id,
                              content: commentCtrl.text,
                            );
                        commentCtrl.clear();
                      },
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
