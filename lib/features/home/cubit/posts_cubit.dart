import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/services/local_notification_service.dart';
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
    await persistState();
  }

  /// Creates and publishes a new post (all team roles: Admin, Editor & Member).
  Future<void> createPost({
    required PostCategoryType type,
    required String content,
    String? mediaPath,
    bool isVideo = false,
    String? videoUrl,
    List<PostMediaItem> mediaItems = const [],
    List<String> pollOptionsText = const [],
    bool allowMultiplePollChoices = false,
  }) async {
    if (!state.currentUser.role.canCreatePosts) return;

    final now = DateTime.now();
    final pollOptions = pollOptionsText
        .where((t) => t.trim().isNotEmpty)
        .take(25)
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

    final resolvedItems = mediaItems.isNotEmpty
        ? mediaItems
        : ((mediaPath != null && mediaPath.trim().isNotEmpty)
            ? [
                PostMediaItem(
                  path: mediaPath.trim(),
                  isVideo: isVideo,
                  videoUrl: videoUrl,
                ),
              ]
            : ((videoUrl != null && videoUrl.trim().isNotEmpty)
                ? [
                    PostMediaItem(
                      path: videoUrl.trim(),
                      isVideo: true,
                      videoUrl: videoUrl.trim(),
                    ),
                  ]
                : const <PostMediaItem>[]));
    final primaryItem = resolvedItems.firstOrNull;

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
      mediaPath: primaryItem?.path ?? mediaPath,
      isVideo: primaryItem?.isVideo ?? isVideo,
      videoUrl: primaryItem?.videoUrl ?? videoUrl,
      mediaItems: resolvedItems,
      pollOptions: pollOptions,
      allowMultiplePollChoices: allowMultiplePollChoices,
      likedByIds: const [],
      comments: const [],
    );

    pushNotification(
      title: 'منشور جديد من ${state.currentUser.name} 📢',
      description: newPost.content,
      category: NotificationCategory.posts,
      tone: LmtNotificationTone.normal,
      targetTabIndex: 0,
      excludedMemberIds: [state.currentUser.id],
    );
    final sentNotification = state.notifications.firstOrNull;

    pendingOutgoingPosts[newPost.id] = newPost;
    if (sentNotification != null) {
      pendingOutgoingNotifications[newPost.id] = sentNotification;
    }

    emit(state.copyWith(posts: [newPost, ...state.posts]));
    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: state.currentUser.id,
    );
    await repository.savePostToCloud(
      post: newPost,
      notification: sentNotification,
    );
  }

  /// Edits an existing post's text content (Admin & Editor).
  Future<void> editPost({
    required String postId,
    required String content,
  }) async {
    if (!state.currentUser.role.canEditPosts) return;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) return post;
      final edited = post.copyWith(content: trimmed);
      if (pendingOutgoingPosts.containsKey(postId)) {
        pendingOutgoingPosts[postId] = edited;
      }
      return edited;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));
    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: state.currentUser.id,
    );
    await repository.updatePostContentInCloud(
      postId: postId,
      content: trimmed,
    );
  }

  /// Deletes a post (Administrator ONLY).
  Future<void> deletePost(String postId) async {
    if (!state.currentUser.role.canDeletePosts) return;
    if (!state.posts.any((p) => p.id == postId)) return;

    pendingOutgoingPosts.remove(postId);
    pendingOutgoingNotifications.remove(postId);
    emit(
      state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      ),
    );
    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: state.currentUser.id,
    );
    await repository.deletePostFromCloud(postId: postId);
  }

  /// Toggles the current user's Like on a post and notifies ONLY the post
  /// creator with `Post_Interactions` when liked by another member.
  Future<void> toggleLikePost(String postId) async {
    final userId = state.currentUser.id;
    PostModel? likedPost;
    var likeAdded = false;

    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) return post;
      final liked = List<String>.from(post.likedByIds);
      if (liked.contains(userId)) {
        liked.remove(userId);
      } else {
        liked.add(userId);
        likeAdded = true;
        likedPost = post;
      }
      return post.copyWith(likedByIds: liked);
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    AppNotificationModel? sentNotification;
    if (likeAdded && likedPost != null && likedPost!.creatorId != userId) {
      final post = likedPost!;
      final preview = post.content.length > 60
          ? '${post.content.substring(0, 60)}...'
          : post.content;
      pushNotification(
        title: 'إعجاب جديد بمنشورك ❤️',
        description: preview.isNotEmpty
            ? 'أعجب ${state.currentUser.name} بمنشورك: "$preview"'
            : 'أعجب ${state.currentUser.name} بمنشورك.',
        category: NotificationCategory.posts,
        tone: LmtNotificationTone.postInteractions,
        targetTabIndex: 0,
        targetMemberIds: [post.creatorId],
        excludedMemberIds: [userId],
      );
      sentNotification = state.notifications.firstOrNull;
    }

    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: userId,
    );
    await repository.togglePostLikeInCloud(
      postId: postId,
      memberId: userId,
      notification: sentNotification,
    );
  }

  /// Casts, toggles, or removes a user's vote on a poll option, respecting
  /// [PostModel.allowMultiplePollChoices] (single-choice vs multi-choice).
  Future<void> voteOnPoll({
    required String postId,
    required String optionId,
  }) async {
    final userId = state.currentUser.id;
    var allowMultiple = false;
    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) return post;
      allowMultiple = post.allowMultiplePollChoices;

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
    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: userId,
    );
    await repository.voteOnPollInCloud(
      postId: postId,
      optionId: optionId,
      memberId: userId,
      allowMultiple: allowMultiple,
    );
  }

  /// Adds a comment to a post and notifies ONLY the post creator with
  /// `Post_Interactions` when commented by another member.
  Future<void> addPostComment({
    required String postId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final actorId = state.currentUser.id;
    PostModel? commentedPost;

    final newComment = PostCommentModel(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      authorId: actorId,
      authorName: state.currentUser.name,
      authorAvatar: state.currentUser.avatarPath,
      authorRole: state.currentUser.role,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) return post;
      commentedPost = post;
      return post.copyWith(comments: [...post.comments, newComment]);
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    AppNotificationModel? sentNotification;
    if (commentedPost != null && commentedPost!.creatorId != actorId) {
      pushNotification(
        title: 'تعليق جديد على منشورك 💬',
        description: 'علّق ${state.currentUser.name} على منشورك: "$trimmed"',
        category: NotificationCategory.posts,
        tone: LmtNotificationTone.postInteractions,
        targetTabIndex: 0,
        targetMemberIds: [commentedPost!.creatorId],
        excludedMemberIds: [actorId],
      );
      sentNotification = state.notifications.firstOrNull;
    }

    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: actorId,
    );
    await repository.addPostCommentInCloud(
      postId: postId,
      comment: newComment,
      notification: sentNotification,
    );
  }
}
