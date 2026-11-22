import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';

MemberModel _resolveMember(String memberId, List<MemberModel> allMembers) {
  final found = allMembers.where((m) => m.id == memberId).firstOrNull;
  if (found != null) return found;
  return MemberModel(
    id: memberId,
    username: memberId,
    password: '',
    name: memberId,
    role: UserRole.member,
    avatarPath: AppAssets.accountIcon,
    groups: const [],
    departments: const ['ديكور'],
    committees: const ['اللجنة العامة'],
  );
}

/// Opens a modal bottom sheet displaying all members who liked [post].
void showPostLikersSheet(
  BuildContext context, {
  required PostModel post,
  required List<MemberModel> allMembers,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final likers =
      post.likedByIds.map((id) => _resolveMember(id, allMembers)).toList();

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      final textPrimary = AppColors.textPrimaryOf(ctx);
      final textSecondary = AppColors.textSecondaryOf(ctx);

      return Padding(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'من أعجب بالمنشور (${likers.length}) ❤️'
                        : 'Liked By (${likers.length}) ❤️',
                    style: AppTypography.h5.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (likers.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: Text(
                    isArabic
                        ? 'لا توجد إعجابات على هذا المنشور حتى الآن'
                        : 'No likes on this post yet',
                    style: TextStyle(color: textSecondary, fontSize: 13.sp),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 360.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: likers.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8.h),
                  itemBuilder: (_, idx) {
                    final m = likers[idx];
                    return LmtCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      borderRadius: 14.r,
                      shadowIntensity: 0.4,
                      child: Row(
                        children: [
                          LmtAvatar(
                            imagePath: m.avatarPath,
                            radius: 19,
                            showShadow: false,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.name} ${m.role.badgeEmoji}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '${m.role.shortLabel(isArabic)} • ${m.committee}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.favorite_rounded,
                            color: AppColors.error,
                            size: 18.sp,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// Opens a modal bottom sheet displaying the breakdown of who voted on each
/// option in a poll [post].
void showPollVotersSheet(
  BuildContext context, {
  required PostModel post,
  required List<MemberModel> allMembers,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      final primary = AppColors.primaryOf(ctx);
      final accentGreen = AppColors.accentGreenOf(ctx);
      final textPrimary = AppColors.textPrimaryOf(ctx);
      final textSecondary = AppColors.textSecondaryOf(ctx);
      final totalVotes = post.totalPollVotes;

      return Padding(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 460.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.poll_rounded, color: primary, size: 24.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'من صوّت في استطلاع الرأي ($totalVotes صوت) 📊'
                          : 'Who Voted in Poll ($totalVotes votes) 📊',
                      style: AppTypography.h5.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: post.pollOptions.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (_, idx) {
                    final opt = post.pollOptions[idx];
                    final voters = opt.voterIds
                        .map((id) => _resolveMember(id, allMembers))
                        .toList();
                    final ratio =
                        totalVotes == 0 ? 0.0 : (voters.length / totalVotes);

                    return LmtCard(
                      padding: EdgeInsets.all(12.w),
                      borderRadius: 16.r,
                      accentColor:
                          voters.isNotEmpty ? accentGreen : primary,
                      isHighlighted: voters.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opt.text,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: accentGreen.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  '${voters.length} (${(ratio * 100).round()}%)',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: accentGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 14),
                          if (voters.isEmpty)
                            Text(
                              isArabic
                                  ? 'لم يصوّت أحد لهذا الخيار بعد'
                                  : 'No votes for this option yet',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: textSecondary,
                              ),
                            )
                          else
                            ...voters.map(
                              (m) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Row(
                                  children: [
                                    LmtAvatar(
                                      imagePath: m.avatarPath,
                                      radius: 15,
                                      showShadow: false,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        '${m.name} ${m.role.badgeEmoji}',
                                        style: TextStyle(
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: accentGreen,
                                      size: 16.sp,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
