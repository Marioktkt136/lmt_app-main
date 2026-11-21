import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/posts_cubit.dart';
import 'post_comments_sheet.dart';
import 'post_composer_card.dart';
import 'timeline_post_card.dart';
import 'year_verse_banner.dart';

/// Displays the scrollable Posts Feed (Timeline).
class PostsList extends StatelessWidget {
  /// Creates a [PostsList].
  const PostsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.only(
            bottom: 18.h,
            left: 2.w,
            right: 2.w,
            top: 4.h,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            // 1. Year Slogan & Verse Banner
            YearVerseBanner(
              sloganOfYear: state.sloganOfYear,
              verseOfYear: state.verseOfYear,
            ),

            // 2. Create Post Composer Card
            PostComposerCard(currentUser: state.currentUser),

            // 3. Posts Feed Cards
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
        );
      },
    );
  }
}
