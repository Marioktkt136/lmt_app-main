import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/features/auth/widgets/login_body.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool rememberMe = true;

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
    setState(() {});
  }

  Future<void> toggleLanguage() async {
    final current = context.locale;
    final next = current.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
    await AppPreferences.setLocale(next);
    await context.setLocale(next);
    setState(() {});
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (rememberMe) {
      await AppPreferences.saveLogin(username: username, password: password);
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.home);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
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
          ),
        ),
      ),
    );
  }
}
