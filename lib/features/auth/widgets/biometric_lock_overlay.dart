import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../services/biometric_auth_service.dart';
import '../services/biometric_session_lock_controller.dart';
import 'biometric_fallback_dialog.dart';

/// Full-screen Biometric / Face ID unlock shield displayed when opening or
/// unlocking an active session with Biometric Lock enabled in Settings.
class BiometricLockOverlay extends StatefulWidget {
  /// Creates a [BiometricLockOverlay].
  const BiometricLockOverlay({super.key, this.biometricService});

  /// Optional injected service used primarily for deterministic tests.
  final BiometricAuthService? biometricService;

  @override
  State<BiometricLockOverlay> createState() => _BiometricLockOverlayState();
}

class _BiometricLockOverlayState extends State<BiometricLockOverlay>
    with WidgetsBindingObserver {
  late final BiometricAuthService _biometricService =
      widget.biometricService ?? BiometricAuthService();
  bool _isAuthenticating = false;
  bool _didAutoPrompt = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _biometricService.warmUp();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didAutoPrompt) return;
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        if (lifecycle != AppLifecycleState.paused &&
            lifecycle != AppLifecycleState.hidden) {
          _didAutoPrompt = true;
          _unlockWithBiometrics();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb &&
        state == AppLifecycleState.resumed &&
        mounted &&
        !_didAutoPrompt &&
        !_isAuthenticating) {
      _didAutoPrompt = true;
      _unlockWithBiometrics();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _unlockWithBiometrics() async {
    if (_isAuthenticating || !mounted) return;
    final cubit = context.read<LmtCubit>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final user = cubit.state.currentUser;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = null;
    });

    try {
      final status =
          await BiometricSessionLockController.instance.attemptUnlock(
        userId: user.id,
        username: user.username,
        localizedReason: isArabic
            ? 'تحقق ببصمة الإصبع أو Face ID لفتح تطبيق L.M.T'
            : 'Verify with Fingerprint or Face ID to open L.M.T App',
        service: _biometricService,
        onPluginMissingFallback: () => BiometricFallbackDialog.show(
          context,
          isArabic: isArabic,
        ),
      );
      if (!mounted) return;

      switch (status) {
        case BiometricStatus.success:
          return;
        case BiometricStatus.notEnrolled:
          setState(() {
            _statusMessage = isArabic
                ? 'لا توجد بصمة أو Face ID مسجل على هذا الجهاز.'
                : 'No Fingerprint or Face ID enrolled on this device.';
          });
        case BiometricStatus.cancelled:
          setState(() {
            _statusMessage = isArabic
                ? 'يرجى تأكيد البصمة أو Face ID للمتابعة.'
                : 'Please verify your Biometrics or Face ID to continue.';
          });
        case BiometricStatus.error:
          setState(() {
            _statusMessage = isArabic
                ? 'تعذر تشغيل البصمة، حاول مرة أخرى.'
                : 'Unable to verify biometrics, please try again.';
          });
        case BiometricStatus.pluginMissing:
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _signOut() async {
    final cubit = context.read<LmtCubit>();
    await cubit.logout();
    final nav = AppRouter.navigatorKey.currentState;
    if (nav != null && nav.mounted) {
      nav.pushNamedAndRemoveUntil(Routes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final cubit = context.watch<LmtCubit>();
    final userName = cubit.state.currentUser.name;

    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.backgroundOf(context),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 20.h),
              child: AdaptiveContentBox(
                maxWidth: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Image.asset(
                        AppAssets.appLogo,
                        width: 72.w,
                        height: 72.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      isArabic
                          ? 'التطبيق مقفول بالبصمة / Face ID 🔐'
                          : 'Locked with Biometrics / Face ID 🔐',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      isArabic
                          ? 'مرحباً $userName — جلستك محفوظة، تحقق بالبصمة أو الوجه للمتابعة'
                          : 'Welcome back, $userName — your session stays signed in. Verify Biometrics or Face ID to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: textSecondary,
                        height: 1.45,
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      SizedBox(height: 14.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed:
                            _isAuthenticating ? null : _unlockWithBiometrics,
                        icon: _isAuthenticating
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          isArabic
                              ? 'فتح بالبصمة / Face ID'
                              : 'Unlock with Biometrics / Face ID',
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton.icon(
                      onPressed: _isAuthenticating ? null : _signOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        isArabic
                            ? 'تسجيل الخروج / تبديل الحساب'
                            : 'Sign Out / Switch Account',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
