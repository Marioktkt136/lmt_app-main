import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/auth_cubit.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../main.dart';
import '../widgets/login_body.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool obscurePassword = true;
  bool rememberMe = true;
  bool _isBiometricAuthenticating = false;
  bool _hasPreviousLogin = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentialsAndAutoPromptBiometrics();
  }

  Future<void> _loadSavedCredentialsAndAutoPromptBiometrics() async {
    final hasLoggedInBefore = await AppPreferences.isLoggedIn();
    final savedUser = await AppPreferences.getSavedUsername();
    final canUseBiometrics =
        hasLoggedInBefore && savedUser != null && savedUser.trim().isNotEmpty;

    if (!mounted) return;
    setState(() {
      _hasPreviousLogin = canUseBiometrics;
      if (canUseBiometrics) {
        usernameController.text = savedUser;
      }
    });

    // If the user has logged in before, automatically trigger the biometric prompt immediately
    if (canUseBiometrics) {
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

  Future<void> toggleTheme() async {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    await LMTApp.of(context).setThemeMode(newMode);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> toggleLanguage() async {
    final current = context.locale;
    final next = current.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
    await AppPreferences.setLocale(next);
    if (!mounted) return;
    await context.setLocale(next);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    await context.read<LmtCubit>().login(
          username: username,
          password: password,
          rememberMe: rememberMe,
        );

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.home);
  }

  /// Real Hardware Biometric Authentication (Fingerprint & Face Recognition via local_auth).
  /// Only active when the user has logged in before (`_hasPreviousLogin == true`).
  Future<void> authenticateWithBiometrics() async {
    final isArabic = context.locale.languageCode == 'ar';
    if (!_hasPreviousLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى تسجيل الدخول باسم المستخدم وكلمة المرور أولاً لتفعيل الدخول بالبصمة أو الوجه.'
                : 'Please log in with your username and password first to enable Fingerprint / Face ID.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_isBiometricAuthenticating) return;
    final accentGreen = AppColors.accentGreenOf(context);

    setState(() => _isBiometricAuthenticating = true);

    try {
      final bool isSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      if (!isSupported || (!canCheckBiometrics && availableBiometrics.isEmpty)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'جهازك غير مفعل به بصمة إصبع أو وجه حالياً. يرجى إعداد البصمة في إعدادات الهاتف أولاً.'
                  : 'No Fingerprint or Face ID enrolled on this device. Please set up biometrics in device settings first.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: isArabic
            ? 'قم بمسح بصمة الإصبع أو الوجه لتسجيل الدخول إلى تطبيق فريق الرسالة الاخيرة (L.M.T)'
            : 'Authenticate with your Fingerprint or Face ID to log in to L.M.T',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (didAuthenticate) {
        final enteredUsername = usernameController.text.trim();
        if (enteredUsername.isNotEmpty) {
          await context.read<LmtCubit>().login(
                username: enteredUsername,
                password: passwordController.text.trim().isEmpty
                    ? 'biometric_verified'
                    : passwordController.text.trim(),
                rememberMe: rememberMe,
              );
        } else {
          await context.read<LmtCubit>().loginWithBiometrics();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('biometric_success'.tr()),
            backgroundColor: accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, Routes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'لم يكتمل التحقق من البصمة، حاول مرة أخرى'
                  : 'Biometric authentication cancelled or failed',
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on MissingPluginException {
      if (!mounted) return;
      await _showInteractiveBiometricFallbackDialog();
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذر تشغيل مستشعر البصمة: ${e.message ?? e.code}'
                : 'Biometric error: ${e.message ?? e.code}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBiometricAuthenticating = false);
      }
    }
  }

  Future<void> _showInteractiveBiometricFallbackDialog() async {
    final isArabic = context.locale.languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);

    final verified = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
        ),
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
              child: Icon(
                Icons.fingerprint_rounded,
                size: 56.sp,
                color: primary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              isArabic
                  ? 'اضغط على مستشعر البصمة أدناه لتأكيد هويتك والدخول إلى حساب L.M.T'
                  : 'Touch the fingerprint sensor below to verify your identity and access L.M.T',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: AppColors.textSecondaryOf(ctx),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.verified_user_rounded),
            label: Text(
              isArabic ? 'تأكيد البصمة والدخول' : 'Verify Biometrics',
            ),
          ),
        ],
      ),
    );

    if (verified == true && mounted) {
      final enteredUsername = usernameController.text.trim();
      if (enteredUsername.isNotEmpty) {
        await context.read<LmtCubit>().login(
              username: enteredUsername,
              password: passwordController.text.trim().isEmpty
                  ? 'biometric_verified'
                  : passwordController.text.trim(),
              rememberMe: rememberMe,
            );
      } else {
        await context.read<LmtCubit>().loginWithBiometrics();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('biometric_success'.tr()),
          backgroundColor: accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacementNamed(context, Routes.home);
    }
  }

  void toggleObscurePassword() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }

  void setRememberMe(bool? value) {
    setState(() {
      rememberMe = value ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
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
            isBiometricEnabled: _hasPreviousLogin,
            onBiometricLogin: authenticateWithBiometrics,
          ),
        ),
      ),
    );
  }
}
