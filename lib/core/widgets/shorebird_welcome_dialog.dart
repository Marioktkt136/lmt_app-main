import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../services/shorebird_update_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Displays a welcome/update notification dialog whenever a new release or
/// Shorebird OTA patch has been installed or downloaded, including exact
/// version label and update timestamp.
class ShorebirdWelcomeDialog extends StatelessWidget {
  /// Metadata describing the new version and timestamp.
  final ShorebirdWelcomeMessage message;

  /// Creates a [ShorebirdWelcomeDialog].
  const ShorebirdWelcomeDialog({
    super.key,
    required this.message,
  });

  /// Shows the [ShorebirdWelcomeDialog] safely.
  static Future<void> show(
    BuildContext context,
    ShorebirdWelcomeMessage message,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ShorebirdWelcomeDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final formattedDate =
        DateFormat('dd/MM/yyyy • hh:mm a').format(message.updatedAt);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      contentPadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.r.clamp(48.0, 72.0).toDouble(),
              height: 56.r.clamp(48.0, 72.0).toDouble(),
              decoration: BoxDecoration(
                color: (message.restartRequired ? primary : accentGreen)
                    .withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.restartRequired
                    ? Icons.system_update_rounded
                    : Icons.celebration_rounded,
                color: message.restartRequired ? primary : accentGreen,
                size: 30.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              message.restartRequired
                  ? (isArabic
                      ? 'تحديث جديد جاهز للتطبيق 🚀'
                      : 'New Update Ready 🚀')
                  : (isArabic
                      ? 'أهلاً بك في التحديث الجديد! 🎉'
                      : 'Welcome to the New Update! 🎉'),
              textAlign: TextAlign.center,
              style: AppTypography.h5.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message.restartRequired
                  ? (isArabic
                      ? 'تم تنزيل أحدث تحديث لتطبيق فريق الرسالة الاخيرة (L.M.T) بنجاح وسيتم تفعيله تلقائياً عند إعادة فتح التطبيق.'
                      : 'The latest L.M.T update has been downloaded automatically and will take effect on next restart.')
                  : (isArabic
                      ? 'تم تحديث تطبيق فريق الرسالة الاخيرة (L.M.T) تلقائياً بنجاح إلى أحدث إصدار.'
                      : 'Your L.M.T app has been automatically updated to the latest version.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: textSecondary,
                height: 1.45,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.new_releases_rounded,
                        color: primary,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '${isArabic ? 'الإصدار:' : 'Version:'} ${message.versionLabel}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: accentGreen,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '${isArabic ? 'تاريخ التحديث:' : 'Updated on:'} $formattedDate',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              isArabic ? 'مرحباً! متابعة ✨' : 'Awesome, Continue ✨',
            ),
          ),
        ),
      ],
    );
  }
}
