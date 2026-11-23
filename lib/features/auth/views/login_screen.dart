import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../main.dart';
import '../cubit/auth_cubit.dart';
import '../services/biometric_auth_service.dart';
import '../widgets/biometric_fallback_dialog.dart';
import '../widgets/login_body.dart';

/// Primary Login Screen for "The Last Message Team" (L.M.T).
///
/// - Always opened after [SplashScreen] to verify user identity.
/// - Biometrics (Fingerprint / Face ID) are only enabled if the user has
///   previously logged in (`_hasPreviousLogin == true`), and are triggered
///   automatically upon screen load when enabled.
class LoginScreen extends StatefulWidget {
  /// Creates a [LoginScreen].
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

/// State for [LoginScreen].
class LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final BiometricAuthService _biometricService = BiometricAuthService();

  bool obscurePassword = true;
  bool rememberMe = true;
  bool _isSubmitting = false;
  bool _isBiometricAuthenticating = false;
  bool _hasPreviousLogin = false;
  bool _isBiometricPrefEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentialsAndAutoPromptBiometrics();
  }

  Future<void> _loadSavedCredentialsAndAutoPromptBiometrics() async {
    final hasLoggedInBefore = await AppPreferences.isLoggedIn();
    final savedUser = await AppPreferences.getSavedUsername();
    final biometricPrefEnabled = await AppPreferences.isBiometricEnabled();
    final hasValidPrevious =
        hasLoggedInBefore && savedUser != null && savedUser.trim().isNotEmpty;
    final canAutoPromptBiometrics = hasValidPrevious && biometricPrefEnabled;

    if (!mounted) return;
    setState(() {
      _hasPreviousLogin = hasValidPrevious;
      _isBiometricPrefEnabled = biometricPrefEnabled;
      if (hasValidPrevious) {
        usernameController.text = savedUser;
      }
    });

    if (canAutoPromptBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          authenticateWithBiometrics();
        }
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Toggles between Light and Dark theme modes.
  Future<void> toggleTheme() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    await LMTApp.of(context).setThemeMode(newMode);
    if (!mounted) return;
    setState(() {});
  }

  /// Toggles between Arabic (`ar`) and English (`en`) locales.
  Future<void> toggleLanguage() async {
    final current = context.locale;
    final next =
        current.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    await AppPreferences.setLocale(next);
    if (!mounted) return;
    await context.setLocale(next);
    if (!mounted) return;
    setState(() {});
  }

  /// Validates and submits the username/password form.
  Future<void> submit() async {
    if (_isSubmitting || !formKey.currentState!.validate()) return;

    final isArabic = context.locale.languageCode == 'ar';
    setState(() => _isSubmitting = true);
    try {
      await context.read<LmtCubit>().login(
            username: usernameController.text.trim(),
            password: passwordController.text.trim(),
            rememberMe: rememberMe,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.home);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.localized(isArabic), AppColors.error);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        isArabic
            ? 'تعذر تسجيل الدخول. يرجى المحاولة مرة أخرى.'
            : 'Unable to sign in. Please try again.',
        AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Runs hardware biometric authentication via [BiometricAuthService].
  Future<void> authenticateWithBiometrics() async {
    final isArabic = context.locale.languageCode == 'ar';
    if (!_hasPreviousLogin) {
      _showSnackBar(
        isArabic
            ? 'يرجى تسجيل الدخول باسم المستخدم وكلمة المرور أولاً لتفعيل الدخول بالبصمة أو الوجه.'
            : 'Please log in with your username and password first to enable Fingerprint / Face ID.',
        AppColors.warning,
      );
      return;
    }
    if (!_isBiometricPrefEnabled) {
      _showSnackBar(
        isArabic
            ? 'الدخول بالبصمة والوجه معطل حالياً من الإعدادات.'
            : 'Fingerprint / Face ID login is currently disabled in Settings.',
        AppColors.warning,
      );
      return;
    }
    if (_isBiometricAuthenticating) return;

    setState(() => _isBiometricAuthenticating = true);
    try {
      final result = await _biometricService.authenticate(
        localizedReason: isArabic
            ? 'قم بمسح بصمة الإصبع أو الوجه لتسجيل الدخول إلى تطبيق فريق الرسالة الاخيرة (L.M.T)'
            : 'Authenticate with your Fingerprint or Face ID to log in to L.M.T',
      );
      if (!mounted) return;

      switch (result.status) {
        case BiometricStatus.success:
          await _completeBiometricLogin();
        case BiometricStatus.pluginMissing:
          final confirmed = await BiometricFallbackDialog.show(
            context,
            isArabic: isArabic,
          );
          if (confirmed == true && mounted) {
            await _completeBiometricLogin();
          }
        case BiometricStatus.notEnrolled:
          _showSnackBar(
            isArabic
                ? 'جهازك غير مفعل به بصمة إصبع أو وجه حالياً. يرجى إعداد البصمة في إعدادات الهاتف أولاً.'
                : 'No Fingerprint or Face ID enrolled on this device. Please set up biometrics in device settings first.',
            AppColors.error,
          );
        case BiometricStatus.cancelled:
          _showSnackBar(
            isArabic
                ? 'لم يكتمل التحقق من البصمة، حاول مرة أخرى'
                : 'Biometric authentication cancelled or failed',
            AppColors.warning,
          );
        case BiometricStatus.error:
          _showSnackBar(
            isArabic
                ? 'تعذر تشغيل مستشعر البصمة: ${result.message ?? ''}'
                : 'Biometric error: ${result.message ?? ''}',
            AppColors.error,
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isBiometricAuthenticating = false);
      }
    }
  }

  Future<void> _completeBiometricLogin() async {
    final isArabic = context.locale.languageCode == 'ar';
    final accentGreen = AppColors.accentGreenOf(context);
    final savedUsername = await AppPreferences.getSavedUsername();
    if (!mounted) return;

    final enteredUsername = usernameController.text.trim();
    if (enteredUsername.isNotEmpty &&
        savedUsername != null &&
        enteredUsername.toLowerCase() != savedUsername.trim().toLowerCase()) {
      _showSnackBar(
        isArabic
            ? 'البصمة مرتبطة بالحساب المسجل ($savedUsername) فقط. أدخل كلمة المرور للدخول بحساب آخر.'
            : 'Biometrics are bound to ($savedUsername). Enter password to sign in with another account.',
        AppColors.error,
      );
      return;
    }

    try {
      await context.read<LmtCubit>().loginWithBiometrics();
      if (!mounted) return;
      _showSnackBar('biometric_success'.tr(), accentGreen);
      Navigator.pushReplacementNamed(context, Routes.home);
    } on AuthException catch (e) {
      final stillLoggedIn = await AppPreferences.isLoggedIn();
      if (!mounted) return;
      setState(() {
        _hasPreviousLogin = stillLoggedIn;
        if (!stillLoggedIn) {
          usernameController.clear();
          passwordController.clear();
        }
      });
      _showSnackBar(e.localized(isArabic), AppColors.error);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Toggles password field visibility.
  void toggleObscurePassword() {
    setState(() => obscurePassword = !obscurePassword);
  }

  /// Updates the "Remember me" flag.
  void setRememberMe(bool? value) {
    setState(() => rememberMe = value ?? true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: AdaptiveContentBox(
          maxWidth: 480,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: LoginBody(
              isDark: isDark,
              toggleTheme: toggleTheme,
              toggleLanguage: toggleLanguage,
              usernameController: usernameController,
              passwordController: passwordController,
              obscurePassword: obscurePassword,
              toggleObscurePassword: toggleObscurePassword,
              formKey: formKey,
              rememberMe: rememberMe,
              onRememberMeChanged: setRememberMe,
              submit: submit,
              isBiometricEnabled: _hasPreviousLogin && _isBiometricPrefEnabled,
              isBiometricDisabledBySettings:
                  _hasPreviousLogin && !_isBiometricPrefEnabled,
              onBiometricLogin: authenticateWithBiometrics,
              isLoading: _isSubmitting,
            ),
          ),
        ),
      ),
    );
  }
}
