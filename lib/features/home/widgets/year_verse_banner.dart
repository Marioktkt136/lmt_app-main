import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';

/// Displays the annual team slogan and verse banner at the top of the timeline.
class YearVerseBanner extends StatelessWidget {
  /// The active slogan of the year.
  final String sloganOfYear;

  /// The active verse of the year.
  final String verseOfYear;

  /// Creates a [YearVerseBanner].
  const YearVerseBanner({
    super.key,
    required this.sloganOfYear,
    required this.verseOfYear,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Container(
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.16),
            accentGreen.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: AppColors.cardShadows(
          context,
          accent: primary,
          intensity: 0.85,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎭'),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  isArabic
                      ? 'آية وشعار السنة • $sloganOfYear'
                      : 'Verse & Slogan of the Year • $sloganOfYear',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            verseOfYear,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
