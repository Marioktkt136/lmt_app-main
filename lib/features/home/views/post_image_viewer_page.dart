import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../cubit/posts_cubit.dart';
import '../sheets/post_interactions_sheet.dart';
import '../widgets/post_comments_sheet.dart';

/// Fullscreen interactive image viewer for media posts, featuring pinch-to-zoom,
/// double-tap zoom, and a persistent bottom Option Control bar (Like, Who Liked,
/// Comment, and Reset/Fit).
class PostImageViewerPage extends StatefulWidget {
  /// The post whose image is being viewed.
  final PostModel post;

  /// Creates a [PostImageViewerPage].
  const PostImageViewerPage({super.key, required this.post});

  @override
  State<PostImageViewerPage> createState() => _PostImageViewerPageState();
}

class _PostImageViewerPageState extends State<PostImageViewerPage> {
  final TransformationController _transformCtrl = TransformationController();
  bool _showControls = true;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final livePost =
            state.posts.where((p) => p.id == widget.post.id).firstOrNull ??
                widget.post;
        final isLiked = livePost.likedByIds.contains(state.currentUser.id);
        final imagePath = livePost.mediaPath ?? AppAssets.actIcon;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Fullscreen Zoomable Image
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showControls = !_showControls),
                    onDoubleTap: () {
                      if (_transformCtrl.value != Matrix4.identity()) {
                        _resetZoom();
                      } else {
                        _transformCtrl.value = Matrix4.diagonal3Values(
                          2.2,
                          2.2,
                          1.0,
                        );
                      }
                    },
                    child: InteractiveViewer(
                      transformationController: _transformCtrl,
                      minScale: 0.8,
                      maxScale: 4.5,
                      child: Center(
                        child: DeviceFileHelper.buildImage(
                          imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Bar (Back + Author Info + Reset Zoom)
                if (_showControls)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.78),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: isArabic ? 'رجوع' : 'Back',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                          LmtAvatar(
                            imagePath: livePost.creatorAvatar,
                            radius: 17,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  livePost.creatorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy • hh:mm a')
                                      .format(livePost.publishTime),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: isArabic ? 'إعادة ضبط التكبير' : 'Reset Zoom',
                            onPressed: _resetZoom,
                            icon: const Icon(
                              Icons.fit_screen_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Option Control Bar (Caption + Like, Who Liked, Comment, Save)
                if (_showControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.90),
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (livePost.content.trim().isNotEmpty) ...[
                            Text(
                              livePost.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5.sp,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: 10.h),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Like Toggle
                                _OptionControlButton(
                                  icon: isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  label:
                                      '${isArabic ? 'أعجبني' : 'Like'} (${livePost.likedByIds.length})',
                                  color: isLiked
                                      ? AppColors.error
                                      : Colors.white,
                                  onTap: () => context
                                      .read<LmtCubit>()
                                      .toggleLikePost(livePost.id),
                                ),

                                // Who Liked
                                _OptionControlButton(
                                  icon: Icons.people_alt_outlined,
                                  label: isArabic ? 'المعجبون' : 'Likers',
                                  color: Colors.white,
                                  onTap: () => showPostLikersSheet(
                                    context,
                                    post: livePost,
                                    allMembers: state.members,
                                  ),
                                ),

                                // Comments
                                _OptionControlButton(
                                  icon: Icons.mode_comment_outlined,
                                  label:
                                      '${isArabic ? 'تعليق' : 'Comment'} (${livePost.comments.length})',
                                  color: Colors.white,
                                  onTap: () =>
                                      showPostCommentsSheet(context, livePost),
                                ),

                                // Open / Save File
                                _OptionControlButton(
                                  icon: Icons.open_in_new_rounded,
                                  label: isArabic ? 'فتح / حفظ' : 'Open',
                                  color: Colors.white,
                                  onTap: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final savedPath = await DeviceFileHelper
                                        .downloadAndOpenRealFile(
                                      SharedFileModel(
                                        id: livePost.id,
                                        title: 'LMT_Post_${livePost.id}.png',
                                        description: livePost.content,
                                        category: SharedFileType.image,
                                        imagePath: imagePath,
                                        fileExtension: 'PNG',
                                        fileSize: 'Image',
                                        uploadedBy: livePost.creatorName,
                                        uploadedAt: livePost.publishTime,
                                      ),
                                    );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isArabic
                                              ? 'تم حفظ الصورة في: $savedPath'
                                              : 'Image saved to: $savedPath',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
