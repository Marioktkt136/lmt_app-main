import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../data/khelwa_repository.dart';
import 'khelwa_attendee_chip.dart';

/// Card listing today's Khelwa attendees only.
///
/// The daily summary message is sent automatically at 12:00 AM midnight to the
/// Khelwa group without any manual user trigger. Only Administrators can reset
/// today's list via [onResetToday].
class KhelwaAttendeesCard extends StatelessWidget {
  /// Names of attendees who took Khelwa today.
  final List<String> attendees;

  /// Whether the active user is an Administrator (`UserRole.admin`).
  final bool isAdmin;

  /// Callback invoked when the Administrator taps Reset Today's List.
  final VoidCallback? onResetToday;

  /// Creates a [KhelwaAttendeesCard].
  const KhelwaAttendeesCard({
    super.key,
    required this.attendees,
    this.isAdmin = false,
    this.onResetToday,
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
                if (isAdmin && onResetToday != null && attendees.isNotEmpty) ...[
                  SizedBox(width: 6.w),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'تصفير قائمة اليوم (للمسؤول فقط)',
                    onPressed: onResetToday,
                    icon: Icon(
                      Icons.restart_alt_rounded,
                      size: 20.sp,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'يتم إرسال قائمة من أخذوا الخلوة تلقائياً الساعة 12:00 منتصف الليل (12:00 AM) في نهاية كل يوم إلى (جروب الخلوة اليومية 🙏)',
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
          ],
        ),
      ),
    );
  }
}
