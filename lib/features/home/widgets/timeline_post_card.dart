import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/expandable_text.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';
import '../cubit/posts_cubit.dart';
import '../sheets/post_interactions_sheet.dart';
import '../views/post_image_viewer_page.dart';

/// Displays an individual timeline post card supporting Simple text, Poll voting
/// (with toggle-to-unvote, fade/expand for long option lists, and "Who Voted"
/// inspection), collapsible long post text (>200 chars), Image/Video media
/// uploaded from the device gallery, and "Who Liked" inspection.
class TimelinePostCard extends StatefulWidget {
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
  State<TimelinePostCard> createState() => _TimelinePostCardState();
}

class _TimelinePostCardState extends State<TimelinePostCard> {
  static const int _collapsedPollOptionsLimit = 3;
  bool _isPollExpanded = false;

  Future<void> _confirmDeletePost(BuildContext context, bool isArabic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'حذف المنشور' : 'Delete Post'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من رغبتك في حذف هذا المنشور؟'
              : 'Are you sure you want to delete this post?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<LmtCubit>().deletePost(widget.post.id);
    }
  }

  Future<void> _showEditPostDialog(BuildContext context, bool isArabic) async {
    final editCtrl = TextEditingController(text: widget.post.content);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تعديل المنشور' : 'Edit Post'),
        content: TextField(
          controller: editCtrl,
          maxLines: 5,
          minLines: 2,
          decoration: InputDecoration(
            labelText: isArabic ? 'محتوى المنشور' : 'Post Content',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = editCtrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
    editCtrl.dispose();
    if (saved != null && context.mounted) {
      await context.read<LmtCubit>().editPost(
            postId: widget.post.id,
            content: saved,
          );
    }
  }

  String _categoryBadgeLabel(bool isArabic) {
    return switch (widget.post.type) {
      PostCategoryType.simple => isArabic ? '📢 منشور' : '📢 Post',
      PostCategoryType.poll => isArabic ? '📊 استطلاع رأي' : '📊 Poll',
      PostCategoryType.media => isArabic ? '🎬 وسائط' : '🎬 Media',
    };
  }

  String _memberNameById(String id, List<MemberModel> members) {
    return members.where((m) => m.id == id).map((m) => m.name).firstOrNull ??
        id;
  }

  Future<void> _handleOpenVideo(BuildContext context, bool isArabic) async {
    final post = widget.post;
    if (post.mediaPath != null &&
        post.mediaPath!.isNotEmpty &&
        !DeviceFileHelper.isAssetPath(post.mediaPath!)) {
      final err = await DeviceFileHelper.openPath(post.mediaPath!);
      if (err == null) return;
    }
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      final uri = Uri.parse(post.videoUrl!);
      await launchUrl(uri);
    }
  }

  Widget _buildPollOptionCard({
    required BuildContext context,
    required PostModel post,
    required PollOptionModel option,
    required List<MemberModel> allMembers,
    required bool isArabic,
    required Color primary,
    required Color accentGreen,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final totalVotes = post.totalPollVotes;
    final optionVotes = option.voterIds.length;
    final ratio = totalVotes == 0 ? 0.0 : (optionVotes / totalVotes);
    final isSelectedByMe = option.voterIds.contains(widget.currentUser.id);
    final voterNames = option.voterIds
        .map((id) => _memberNameById(id, allMembers))
        .join('، ');

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
                  post.allowMultiplePollChoices
                      ? (isSelectedByMe
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded)
                      : (isSelectedByMe
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded),
                  size: 18.sp,
                  color: isSelectedByMe ? accentGreen : textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight:
                          isSelectedByMe ? FontWeight.bold : FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$optionVotes (${(ratio * 100).round()}%)',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelectedByMe ? accentGreen : textSecondary,
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
            if (option.voterIds.isNotEmpty) ...[
              SizedBox(height: 6.h),
              InkWell(
                onTap: () => showPollVotersSheet(
                  context,
                  post: post,
                  allMembers: allMembers,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 13.sp,
                      color: primary,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        '${isArabic ? 'المصوتون:' : 'Voters:'} $voterNames',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isSelectedByMe) ...[
              SizedBox(height: 4.h),
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
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUser = widget.currentUser;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);
    final allMembers = context.read<LmtCubit>().state.members;
    final isLiked = post.likedByIds.contains(currentUser.id);
    final canEdit = currentUser.role.canEditPosts;
    final canDelete = currentUser.role.canDeletePosts;

    return LmtCard(
      padding: EdgeInsets.all(15.w),
      borderRadius: 22.r,
      accentColor: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Creator Header, Category Badge & Publish Time
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h6.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(post.creatorRole.badgeEmoji),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            _categoryBadgeLabel(isArabic),
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${DateFormat('EEE, dd MMM yyyy • hh:mm a').format(post.publishTime)} • ${post.creatorCommittee}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 10.5.sp, color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                IconButton(
                  tooltip: isArabic ? 'تعديل المنشور' : 'Edit Post',
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 19.sp,
                    color: primary,
                  ),
                  onPressed: () => _showEditPostDialog(context, isArabic),
                ),
              if (canDelete)
                IconButton(
                  tooltip: isArabic ? 'حذف المنشور' : 'Delete Post',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19.sp,
                    color: AppColors.error,
                  ),
                  onPressed: () => _confirmDeletePost(context, isArabic),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // Post Text Content (Collapses automatically with Read more if >200 chars)
          LmtExpandableText(
            text: post.content,
            style: AppTypography.bodyMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),

          // Poll Section (Single-choice or Multi-choice, with Fade & More when >3 options)
          if (post.type == PostCategoryType.poll &&
              post.pollOptions.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              post.allowMultiplePollChoices
                  ? (isArabic
                      ? 'يمكنك اختيار أكثر من إجابة في هذا الاستطلاع ✓'
                      : 'Multi-choice poll • You can select multiple options ✓')
                  : (isArabic
                      ? 'اختر إجابة واحدة فقط'
                      : 'Single-choice poll'),
              style: TextStyle(
                fontSize: 10.5.sp,
                color: post.allowMultiplePollChoices ? primary : textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Builder(
              builder: (context) {
                final hasExtraOptions =
                    post.pollOptions.length > _collapsedPollOptionsLimit;
                final visibleOptions = (!hasExtraOptions || _isPollExpanded)
                    ? post.pollOptions
                    : post.pollOptions.take(_collapsedPollOptionsLimit).toList();
                final hiddenOptions = hasExtraOptions
                    ? post.pollOptions.skip(_collapsedPollOptionsLimit).toList()
                    : const <PollOptionModel>[];

                return AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      ...visibleOptions.map(
                        (option) => _buildPollOptionCard(
                          context: context,
                          post: post,
                          option: option,
                          allMembers: allMembers,
                          isArabic: isArabic,
                          primary: primary,
                          accentGreen: accentGreen,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          border: border,
                        ),
                      ),
                      if (hasExtraOptions && !_isPollExpanded)
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            ClipRect(
                              child: Align(
                                alignment: Alignment.topCenter,
                                heightFactor: 0.72,
                                child: IgnorePointer(
                                  child: ShaderMask(
                                    blendMode: BlendMode.dstIn,
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: [0.0, 0.55, 1.0],
                                      colors: [
                                        Colors.white,
                                        Color(0x55FFFFFF),
                                        Colors.transparent,
                                      ],
                                    ).createShader(bounds),
                                    child: _buildPollOptionCard(
                                      context: context,
                                      post: post,
                                      option: hiddenOptions.first,
                                      allMembers: allMembers,
                                      isArabic: isArabic,
                                      primary: primary,
                                      accentGreen: accentGreen,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                      border: border,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      primary.withValues(alpha: 0.16),
                                  foregroundColor: primary,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 6.h,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    setState(() => _isPollExpanded = true),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18.sp,
                                ),
                                label: Text(
                                  isArabic
                                      ? 'عرض باقي الاختيارات (+${hiddenOptions.length})'
                                      : 'More options (+${hiddenOptions.length})',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (hasExtraOptions && _isPollExpanded)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                setState(() => _isPollExpanded = false),
                            icon: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 18.sp,
                              color: primary,
                            ),
                            label: Text(
                              isArabic ? 'عرض خيارات أقل' : 'Show less options',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Button to view full "Who Voted" breakdown sheet
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => showPollVotersSheet(
                  context,
                  post: post,
                  allMembers: allMembers,
                ),
                icon: Icon(
                  Icons.how_to_vote_rounded,
                  size: 15.sp,
                  color: primary,
                ),
                label: Text(
                  isArabic
                      ? 'عرض من صوّت في الاستطلاع (${post.totalPollVotes}) 👥'
                      : 'View Who Voted (${post.totalPollVotes}) 👥',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          // Image / Video Section (Supports real gallery images and videos)
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
                child: post.isVideo
                    ? InkWell(
                        onTap: () => _handleOpenVideo(context, isArabic),
                        child: Container(
                          height: 175.h,
                          width: double.infinity,
                          color: Colors.black87,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(14.w),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14.w),
                                child: Text(
                                  post.mediaPath?.split('/').last ??
                                      (isArabic
                                          ? 'تشغيل الفيديو المرفق 🎬'
                                          : 'Play Attached Video 🎬'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => PostImageViewerPage(post: post),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              height: 185.h,
                              width: double.infinity,
                              color: primary.withValues(alpha: 0.08),
                              child: DeviceFileHelper.buildImage(
                                post.mediaPath ?? AppAssets.actIcon,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              bottom: 8.h,
                              right: 8.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fullscreen_rounded,
                                      size: 15.sp,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      isArabic ? 'تكبير' : 'Fullscreen',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],

          // Who Liked Summary Strip (Tappable to open full Likers Sheet)
          if (post.likedByIds.isNotEmpty) ...[
            SizedBox(height: 10.h),
            InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: () => showPostLikersSheet(
                context,
                post: post,
                allMembers: allMembers,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 14.sp,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        '${isArabic ? 'أعجب به:' : 'Liked by:'} ${post.likedByIds.map((id) => _memberNameById(id, allMembers)).join('، ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isArabic ? 'عرض الكل 👥' : 'See all 👥',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 8.h),
          Divider(color: border, height: 1),
          SizedBox(height: 10.h),

          // Tactile Like, Who Liked, & Comment Action Pills
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () => context.read<LmtCubit>().toggleLikePost(post.id),
                  onLongPress: () => showPostLikersSheet(
                    context,
                    post: post,
                    allMembers: allMembers,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 9.h),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? AppColors.error.withValues(alpha: 0.12)
                          : AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isLiked
                            ? AppColors.error.withValues(alpha: 0.35)
                            : border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isLiked ? AppColors.error : textSecondary,
                          size: 19.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${post.likedByIds.length} ${isArabic ? 'إعجاب' : 'Likes'}',
                          style: TextStyle(
                            color: isLiked ? AppColors.error : textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              IconButton(
                tooltip: isArabic ? 'من أعجب بالمنشور' : 'Who liked this post',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                ),
                onPressed: () => showPostLikersSheet(
                  context,
                  post: post,
                  allMembers: allMembers,
                ),
                icon: Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.error,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: widget.onShowComments,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 9.h),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mode_comment_outlined,
                          color: primary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${post.comments.length} ${isArabic ? 'تعليق' : 'Comments'}',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
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
