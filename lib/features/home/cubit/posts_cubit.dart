import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/utils/app_preferences.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Posts Feed (Timeline) feature module.
typedef PostsCubit = LmtCubit;

/// Encapsulates Posts Feed (Timeline), Polls, Likes, Comments, and Year Verse Branding logic.
mixin PostsCubitMixin on LmtBaseCubit {
  /// Updates the team's annual Slogan and Verse banner.
  Future<void> updateYearBranding({
    required String slogan,
    required String verse,
  }) async {
    await AppPreferences.setSloganOfYear(slogan);
    await AppPreferences.setVerseOfYear(verse);
    emit(state.copyWith(sloganOfYear: slogan, verseOfYear: verse));
  }

  /// Creates and publishes a new post (Simple, Poll, or Media).
  Future<void> createPost({
    required PostCategoryType type,
    required String content,
    String? mediaPath,
    bool isVideo = false,
    String? videoUrl,
    List<String> pollOptionsText = const [],
    bool allowMultiplePollChoices = false,
  }) async {
    final now = DateTime.now();
    final pollOptions = pollOptionsText
        .where((t) => t.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => PollOptionModel(
            id: 'opt_${now.millisecondsSinceEpoch}_${entry.key}',
            text: entry.value.trim(),
            voterIds: const [],
          ),
        )
        .toList();

    final newPost = PostModel(
      id: 'post_${now.millisecondsSinceEpoch}',
      creatorId: state.currentUser.id,
      creatorName: state.currentUser.name,
      creatorAvatar: state.currentUser.avatarPath,
      creatorRole: state.currentUser.role,
      creatorCommittee: state.currentUser.committee,
      publishTime: now,
      type: type,
      content: content.trim(),
      mediaPath: mediaPath,
      isVideo: isVideo,
      videoUrl: videoUrl,
      pollOptions: pollOptions,
      allowMultiplePollChoices: allowMultiplePollChoices,
      likedByIds: const [],
      comments: const [],
    );

    pushNotification(
      title: 'منشور جديد من ${state.currentUser.name} 📢',
      description: newPost.content,
      category: NotificationCategory.posts,
      targetTabIndex: 0,
    );

    emit(state.copyWith(posts: [newPost, ...state.posts]));
    await persistState();
  }

  /// Deletes a post (allowed by creator, Editor, or Admin).
  Future<void> deletePost(String postId) async {
    final post = state.posts.where((p) => p.id == postId).firstOrNull;
    if (post == null) return;

    final canDelete = post.creatorId == state.currentUser.id ||
        state.currentUser.role == UserRole.admin ||
        state.currentUser.role == UserRole.editor;
    if (!canDelete) return;

    emit(
      state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      ),
    );
    await persistState();
  }

  /// Toggles the current user's Like on a post.
  Future<void> toggleLikePost(String postId) async {
    final userId = state.currentUser.id;
    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) return post;
      final liked = List<String>.from(post.likedByIds);
      if (liked.contains(userId)) {
        liked.remove(userId);
      } else {
        liked.add(userId);
      }
      return post.copyWith(likedByIds: liked);
    }).toList();

    emit(state.copyWith(posts: updatedPosts));
    await persistState();
  }

  /// Casts, toggles, or removes a user's vote on a poll option, respecting
  /// [PostModel.allowMultiplePollChoices] (single-choice vs multi-choice).
  Future<void> voteOnPoll({
    required String postId,
    required String optionId,
  }) async {
    final userId = state.currentUser.id;
    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) return post;

      if (post.allowMultiplePollChoices) {
        final updatedOptions = post.pollOptions.map((opt) {
          if (opt.id != optionId) return opt;
          final voters = List<String>.from(opt.voterIds);
          if (voters.contains(userId)) {
            voters.remove(userId);
          } else {
            voters.add(userId);
          }
          return opt.copyWith(voterIds: voters);
        }).toList();
        return post.copyWith(pollOptions: updatedOptions);
      }

      final targetOption =
          post.pollOptions.where((o) => o.id == optionId).firstOrNull;
      final alreadyVotedThis =
          targetOption != null && targetOption.voterIds.contains(userId);

      final updatedOptions = post.pollOptions.map((opt) {
        final voters = List<String>.from(opt.voterIds)..remove(userId);
        if (opt.id == optionId && !alreadyVotedThis) {
          voters.add(userId);
        }
        return opt.copyWith(voterIds: voters);
      }).toList();

      return post.copyWith(pollOptions: updatedOptions);
    }).toList();

    emit(state.copyWith(posts: updatedPosts));
    await persistState();
  }

  /// Adds a comment to a post.
  Future<void> addPostComment({
    required String postId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    final newComment = PostCommentModel(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      authorId: state.currentUser.id,
      authorName: state.currentUser.name,
      authorAvatar: state.currentUser.avatarPath,
      authorRole: state.currentUser.role,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) return post;
      return post.copyWith(comments: [...post.comments, newComment]);
    }).toList();

    emit(state.copyWith(posts: updatedPosts));
    await persistState();
  }
}
