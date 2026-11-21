import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../data/khelwa_repository.dart';
import 'khelwa_attendee_chip.dart';

/// Card listing today's Khelwa attendees with a button that opens the group.
class KhelwaAttendeesCard extends StatelessWidget {
  /// Names of attendees today.
  final List<String> attendees;

  /// Called when the user taps "open group". Should publish then navigate.
  final VoidCallback onOpenGroup;

  /// Creates a [KhelwaAttendeesCard].
  const KhelwaAttendeesCard({
    super.key,
    required this.attendees,
    required this.onOpenGroup,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: AppColors.cardDecoration(
        context,
        radius: 20.r,
        accentColor: primary,
        isHighlighted: true,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, color: primary, size: 22.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'قائمة اللي أخدوا الخلوة انهاردة (${KhelwaRepository.todayDateKey()}) 🙏',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: accentGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${attendees.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: accentGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'يتم إرسال وتحديث هذه القائمة تلقائياً في نهاية كل يوم داخل (جروب الخلوة اليومية 🙏)',
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'Cairo',
                color: textSecondary,
              ),
            ),
            const Divider(height: 18),
            if (attendees.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  'لم يسجل أحد الخلوة اليوم حتى الآن.. كن أول من يأخذ خلوته اليوم! ✨',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'Cairo',
                    color: textSecondary,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (var i = 0; i < attendees.length; i++)
                    KhelwaAttendeeChip(index: i + 1, name: attendees[i]),
                ],
              ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary, width: 1.4),
                  minimumSize: Size.fromHeight(48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: onOpenGroup,
                icon: const Icon(Icons.forum_rounded),
                label: Text(
                  'فتح جروب الخلوة اليومية وعرض قائمة اليوم 💬',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
