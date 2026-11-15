
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/theme/typography.dart';
import 'package:lmt/core/utils/app_assets.dart';
import 'package:lmt/core/utils/constants.dart';
import 'package:lmt/features/auth/widgets/login_submit_custom_button.dart';
import 'package:lmt/features/auth/widgets/remember_me.dart';
import 'package:lmt/features/auth/widgets/text_field.dart';
import 'package:lmt/features/auth/widgets/top_bar.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTopBar(isDark, toggleTheme, toggleLanguage),
        SizedBox(height: 10.h),
        Center(child: Center(child: Image.asset(AppAssets.appLogo))),
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 8.h),
                  Text(
                    'login_title'.tr(),
                    style: AppTypography.h1.copyWith(
                      color: isDark
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text('login_subtitle'.tr(), style: AppTypography.h3),
                  SizedBox(height: 32.h),
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
                  SizedBox(height: 16.h),
                  RememberMe(
                    isDark: isDark,
                    rememberMe: rememberMe,
                    onRememberMeChanged: onRememberMeChanged,
                  ),
                  SizedBox(height: 24.h),
                  LoginSubmitCustomButtom(submit: submit, isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
