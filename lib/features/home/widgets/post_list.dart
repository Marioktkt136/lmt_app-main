import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../cubit/posts_cubit.dart';
import 'post_comments_sheet.dart';
import 'post_composer_card.dart';
import 'timeline_post_card.dart';

/// Displays the scrollable Posts Feed (Timeline) with pull-to-refresh support.
class PostsList extends StatelessWidget {
  /// Creates a [PostsList].
  const PostsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);

    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        return RefreshIndicator(
          color: primary,
          onRefresh: () => context.read<LmtCubit>().syncNow(),
          child: ListView(
            padding: EdgeInsets.only(
              bottom: 18.h,
              left: 2.w,
              right: 2.w,
              top: 4.h,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // 1. Create Post Composer Card
              PostComposerCard(currentUser: state.currentUser),

              // 3. Posts Feed Cards (or friendly empty state)
              if (state.posts.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 32.h),
                  child: LmtEmptyState(
                    icon: Icons.dynamic_feed_rounded,
                    message: isArabic
                        ? 'لا توجد منشورات حالياً.. شارك أول منشور مع الفريق!'
                        : 'No posts yet.. Share the first announcement with the team!',
                  ),
                )
              else
                ...state.posts.map(
                  (post) => Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: TimelinePostCard(
                      post: post,
                      currentUser: state.currentUser,
                      onShowComments: () => showPostCommentsSheet(context, post),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
