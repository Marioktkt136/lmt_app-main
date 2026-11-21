import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';

/// Interactive confirmation dialog used when the native biometric plugin is
/// unavailable (desktop, emulators without plugin support).
///
/// Use [BiometricFallbackDialog.show]; it resolves to `true` when the user
/// confirms, `false`/`null` otherwise.
class BiometricFallbackDialog extends StatelessWidget {
  /// Creates the dialog. Prefer [show].
  const BiometricFallbackDialog({super.key, required this.isArabic});

  /// Whether copy should be Arabic.
  final bool isArabic;

  /// Displays the dialog and returns the user's decision.
  static Future<bool?> show(BuildContext context, {required bool isArabic}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BiometricFallbackDialog(isArabic: isArabic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      title: Row(
        children: [
          Icon(Icons.fingerprint_rounded, color: primary, size: 30.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isArabic
                  ? 'التحقق من بصمة الإصبع / الوجه'
                  : 'Fingerprint / Face ID Verification',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.fingerprint_rounded, size: 56.sp, color: primary),
          ),
          SizedBox(height: 12.h),
          Text(
            isArabic
                ? 'اضغط على مستشعر البصمة أدناه لتأكيد هويتك والدخول إلى حساب L.M.T'
                : 'Touch the fingerprint sensor below to verify your identity and access L.M.T',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.pop(context, false),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.verified_user_rounded),
          label: Text(isArabic ? 'تأكيد البصمة والدخول' : 'Verify Biometrics'),
        ),
      ],
    );
  }
}
