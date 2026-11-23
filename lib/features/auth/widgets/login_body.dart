import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/app_assets.dart';
import '../helpers/login_validators.dart';
import 'login_biometric_button.dart';
import 'login_header.dart';
import 'login_submit_button.dart';
import 'login_text_field.dart';
import 'login_top_bar.dart';
import 'remember_me_tile.dart';

/// Composes the login screen body: top bar, brand header, credentials form,
/// remember-me toggle, submit button, and biometric login button.
class LoginBody extends StatelessWidget {
  /// Whether the dark theme is active.
  final bool isDark;

  /// Toggles between Light and Dark themes.
  final VoidCallback toggleTheme;

  /// Toggles between Arabic and English locales.
  final VoidCallback toggleLanguage;

  /// Controller for the username input field.
  final TextEditingController usernameController;

  /// Controller for the password input field.
  final TextEditingController passwordController;

  /// Whether the password input is obscured.
  final bool obscurePassword;

  /// Toggles password visibility.
  final VoidCallback toggleObscurePassword;

  /// Form key used to validate credentials before submission.
  final GlobalKey<FormState> formKey;

  /// Whether the "Remember me" option is checked.
  final bool rememberMe;

  /// Callback invoked when "Remember me" changes.
  final ValueChanged<bool?> onRememberMeChanged;

  /// Submits the login form.
  final VoidCallback submit;

  /// Whether biometric authentication is enabled (true only after first login
  /// AND enabled in Settings).
  final bool isBiometricEnabled;

  /// True when the user previously logged in, but disabled biometrics in
  /// Settings.
  final bool isBiometricDisabledBySettings;

  /// Triggers the biometric authentication prompt.
  final VoidCallback onBiometricLogin;

  /// Whether a login submission is currently in progress.
  final bool isLoading;

  /// Creates a [LoginBody].
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
    this.isBiometricDisabledBySettings = false,
    required this.onBiometricLogin,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoginTopBar(
          isDark: isDark,
          onToggleTheme: toggleTheme,
          onToggleLanguage: toggleLanguage,
          themeTooltip: isArabic ? 'تبديل المظهر' : 'Toggle Theme',
          languageTooltip: isArabic ? 'تغيير اللغة' : 'Switch Language',
        ),
        SizedBox(height: 10.h),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const LoginHeader(),
                  SizedBox(height: 28.h),
                  LoginTextField(
                    label: 'username_label'.tr(),
                    hint: 'username_hint'.tr(),
                    controller: usernameController,
                    prefixIcon: AppAssets.accountIcon,
                    validator: LoginValidators.username,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                  ),
                  SizedBox(height: 16.h),
                  LoginTextField(
                    label: 'password_label'.tr(),
                    hint: 'password_hint'.tr(),
                    controller: passwordController,
                    prefixIcon: AppAssets.passowrdIcon,
                    obscureText: obscurePassword,
                    suffixIcon: obscurePassword
                        ? AppAssets.viewPasswordIcon
                        : AppAssets.hidePasswordIcon,
                    suffixTooltip: obscurePassword
                        ? (isArabic ? 'إظهار كلمة المرور' : 'Show password')
                        : (isArabic ? 'إخفاء كلمة المرور' : 'Hide password'),
                    onSuffixTap: toggleObscurePassword,
                    validator: LoginValidators.password,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    autofillHints: const [AutofillHints.password],
                  ),
                  SizedBox(height: 12.h),
                  RememberMeTile(
                    isDark: isDark,
                    value: rememberMe,
                    onChanged: onRememberMeChanged,
                  ),
                  SizedBox(height: 18.h),
                  LoginSubmitButton(
                    onPressed: submit,
                    isDark: isDark,
                    isLoading: isLoading,
                  ),
                  SizedBox(height: 14.h),
                  LoginBiometricButton(
                    isEnabled: isBiometricEnabled,
                    isDisabledBySettings: isBiometricDisabledBySettings,
                    onPressed: onBiometricLogin,
                  ),
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
