import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/constants.dart';
import 'login_submit_custom_button.dart';
import 'remember_me.dart';
import 'text_field.dart';
import 'top_bar.dart';

class LoginBody extends StatelessWidget {
  final bool isDark;
  final VoidCallback toggleTheme;
  final VoidCallback toggleLanguage;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback toggleObscurePassword;
  final GlobalKey<FormState> formKey;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback submit;
  final bool isBiometricEnabled;
  final VoidCallback onBiometricLogin;

  const LoginBody({
    super.key,
    required this.isDark,
    required this.toggleTheme,
    required this.toggleLanguage,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.toggleObscurePassword,
    required this.formKey,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.submit,
    required this.isBiometricEnabled,
    required this.onBiometricLogin,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTopBar(isDark, toggleTheme, toggleLanguage),
        SizedBox(height: 10.h),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 120.h,
                    child: Image.asset(
                      AppAssets.appLogo,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'login_title'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(color: textPrimary),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'login_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  buildTextField(
                    context: context,
                    isDark: isDark,
                    label: 'username_label'.tr(),
                    hint: 'username_hint'.tr(),
                    controller: usernameController,
                    prefixIcon: AppAssets.accountIcon,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'field_required'.tr();
                      }
                      if (value.trim().length <
                          AppConstants.minUsernameLength) {
                        return 'username_too_short'.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  buildTextField(
                    context: context,
                    isDark: isDark,
                    label: 'password_label'.tr(),
                    hint: 'password_hint'.tr(),
                    controller: passwordController,
                    prefixIcon: AppAssets.passowrdIcon,
                    obscureText: obscurePassword,
                    suffixIcon: obscurePassword
                        ? AppAssets.viewPasswordIcon
                        : AppAssets.hidePasswordIcon,
                    onSuffixTap: toggleObscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'field_required'.tr();
                      }
                      if (value.length < AppConstants.minPasswordLength) {
                        return 'password_too_short'.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                  RememberMe(
                    isDark: isDark,
                    rememberMe: rememberMe,
                    onRememberMeChanged: onRememberMeChanged,
                  ),
                  SizedBox(height: 18.h),
                  LoginSubmitCustomButtom(submit: submit, isDark: isDark),
                  SizedBox(height: 14.h),

                  // Biometric Login Button (Active only if the user has logged in before)
                  Opacity(
                    opacity: isBiometricEnabled ? 1.0 : 0.48,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: isBiometricEnabled
                            ? AppColors.cardShadows(
                                context,
                                accent: primary,
                                intensity: 0.65,
                              )
                            : const [],
                      ),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(
                            color: isBiometricEnabled
                                ? primary
                                : AppColors.borderOf(context),
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        onPressed:
                            isBiometricEnabled ? onBiometricLogin : null,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          'biometric_login'.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isBiometricEnabled) ...[
                    SizedBox(height: 6.h),
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? '🔒 يتفعل الدخول بالبصمة / الوجه تلقائياً بعد تسجيل الدخول أول مرة باسم المستخدم وكلمة المرور'
                          : '🔒 Biometric login activates automatically after your first login with username & password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
