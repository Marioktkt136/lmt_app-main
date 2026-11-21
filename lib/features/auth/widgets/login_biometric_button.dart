import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';

/// Fingerprint / Face ID button shown below the login button.
///
/// Rule: biometrics are only usable after a previous successful login, so when
/// [isEnabled] is false the button is dimmed/disabled and a hint explains how
/// to activate it.
class LoginBiometricButton extends StatelessWidget {
  /// Creates the biometric button.
  const LoginBiometricButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  /// True once the user has logged in before on this device.
  final bool isEnabled;

  /// Starts the biometric prompt.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      children: [
        Opacity(
          opacity: isEnabled ? 1.0 : 0.48,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: isEnabled
                  ? AppColors.cardShadows(context,
                      accent: primary, intensity: 0.65)
                  : const [],
            ),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(
                  color: isEnabled ? primary : AppColors.borderOf(context),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              onPressed: isEnabled ? onPressed : null,
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(
                'biometric_login'.tr(),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        if (!isEnabled) ...[
          SizedBox(height: 6.h),
          Text(
            isArabic
                ? '🔒 يتفعل الدخول بالبصمة / الوجه تلقائياً بعد تسجيل الدخول أول مرة باسم المستخدم وكلمة المرور'
                : '🔒 Biometric login activates automatically after your first login with username & password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ],
    );
  }
}
