import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/background_sync_bridge.dart';
import '../../../core/services/shorebird_update_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/shorebird_welcome_dialog.dart';
import '../../auth/services/biometric_auth_service.dart';
import '../../auth/services/biometric_session_lock_controller.dart';
import '../../auth/widgets/biometric_fallback_dialog.dart';
import '../cubit/settings_cubit.dart';

/// Security, Biometric Login, and Offline/Online Sync section card.
class SettingsSecuritySyncCard extends StatefulWidget {
  /// The current application state.
  final LmtState state;

  /// Whether the active locale is Arabic.
  final bool isArabic;

  /// Creates a [SettingsSecuritySyncCard].
  const SettingsSecuritySyncCard({
    super.key,
    required this.state,
    required this.isArabic,
  });

  @override
  State<SettingsSecuritySyncCard> createState() =>
      _SettingsSecuritySyncCardState();
}

class _SettingsSecuritySyncCardState extends State<SettingsSecuritySyncCard> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isCheckingBiometric = false;
  bool _isCheckingUpdates = false;
  bool _ignoringBatteryOptimizations = true;
  String _versionLabel = 'v1.0.2+3';

  @override
  void initState() {
    super.initState();
    _biometricService.warmUp();
    _loadCurrentVersion();
    _loadBatteryOptimizationStatus();
  }

  Future<void> _loadBatteryOptimizationStatus() async {
    final ok = await BackgroundSyncBridge.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() => _ignoringBatteryOptimizations = ok);
  }

  Future<void> _loadCurrentVersion() async {
    final result = await ShorebirdUpdateService.instance.checkAndSyncUpdates();
    if (!mounted) return;
    setState(() => _versionLabel = result.versionLabel);
  }

  Future<void> _handleCheckForUpdates() async {
    if (_isCheckingUpdates) return;
    final isArabic = widget.isArabic;
    final accentGreen = AppColors.accentGreenOf(context);
    setState(() => _isCheckingUpdates = true);
    try {
      final result =
          await ShorebirdUpdateService.instance.checkAndSyncUpdates();
      if (!mounted) return;
      setState(() => _versionLabel = result.versionLabel);
      if (result.welcomeMessage != null) {
        await ShorebirdWelcomeDialog.show(context, result.welcomeMessage!);
      } else {
        _showFeedback(
          isArabic
              ? 'التطبيق على أحدث إصدار (${result.versionLabel}) ✅'
              : 'App is up to date (${result.versionLabel}) ✅',
          accentGreen,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdates = false);
      }
    }
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    final isArabic = widget.isArabic;
    final icon = color == AppColors.error
        ? Icons.error_outline_rounded
        : (color == AppColors.warning
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(isArabic ? 'تنبيه' : 'Notice'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isArabic ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometricToggle(bool enable) async {
    if (_isCheckingBiometric) return;
    final cubit = context.read<LmtCubit>();
    final accentGreen = AppColors.accentGreenOf(context);
    final isArabic = widget.isArabic;

    if (!enable) {
      await cubit.setBiometricEnabled(false);
      _showFeedback(
        isArabic
            ? 'تم إيقاف قفل البصمة والوجه — سيتم الدخول مباشرة بدون طلب البصمة 🔓'
            : 'Fingerprint & Face ID disabled 🔓',
        AppColors.warning,
      );
      return;
    }

    setState(() => _isCheckingBiometric = true);
    BiometricSessionLockController.instance.suppressNextResumeLock();
    try {
      final result = await _biometricService.authenticate(
        userId: cubit.state.currentUser.id,
        username: cubit.state.currentUser.username,
        localizedReason: isArabic
            ? 'تأكيد بصمة الإصبع أو الوجه لتفعيل الحماية البيومترية في L.M.T'
            : 'Verify your Fingerprint or Face ID to enable biometric login in L.M.T',
      );
      if (!mounted) return;

      switch (result.status) {
        case BiometricStatus.success:
          await cubit.setBiometricEnabled(true);
          _showFeedback(
            isArabic
                ? 'تم تفعيل الدخول بالبصمة والوجه بنجاح ✅'
                : 'Fingerprint & Face ID enabled ✅',
            accentGreen,
          );
        case BiometricStatus.pluginMissing:
          final confirmed = await BiometricFallbackDialog.show(
            context,
            isArabic: isArabic,
          );
          if (confirmed == true && mounted) {
            await cubit.setBiometricEnabled(true);
            _showFeedback(
              isArabic
                  ? 'تم تفعيل الدخول بالبصمة والوجه بنجاح ✅'
                  : 'Fingerprint & Face ID enabled ✅',
              accentGreen,
            );
          }
        case BiometricStatus.notEnrolled:
          await cubit.setBiometricEnabled(false);
          _showFeedback(
            isArabic
                ? 'لا توجد بصمة أو Face ID مسجل على هذا الجهاز. قم بإعدادها من إعدادات الهاتف أولاً.'
                : 'No Fingerprint or Face ID enrolled on this device.',
            AppColors.error,
          );
        case BiometricStatus.cancelled:
          await cubit.setBiometricEnabled(false);
          _showFeedback(
            isArabic
                ? 'لم يكتمل التحقق من البصمة لتفعيل الميزة'
                : 'Biometric verification cancelled',
            AppColors.warning,
          );
        case BiometricStatus.error:
          await cubit.setBiometricEnabled(false);
          _showFeedback(
            isArabic
                ? 'تعذر تشغيل البصمة: ${result.message ?? ''}'
                : 'Biometric error: ${result.message ?? ''}',
            AppColors.error,
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingBiometric = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    final state = widget.state;
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: AppColors.cardDecoration(
        context,
        radius: 22.r,
        accentColor: primary,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'الأمان والمزامنة (Security & Offline Sync)'
                  : 'Security & Offline/Online Sync',
              style: AppTypography.h6.copyWith(
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: CircleAvatar(
                backgroundColor: (state.biometricEnabled
                        ? accentGreen
                        : textSecondary)
                    .withValues(alpha: 0.14),
                child: _isCheckingBiometric
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentGreen,
                        ),
                      )
                    : Icon(
                        Icons.fingerprint_rounded,
                        color:
                            state.biometricEnabled ? accentGreen : textSecondary,
                      ),
              ),
              title: Text(
                isArabic
                    ? 'الدخول بالبصمة والوجه (Fingerprint & Face ID)'
                    : 'Fingerprint & Face Recognition Login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                state.biometricEnabled
                    ? (isArabic
                        ? 'مفعلة ✅ — يطلب البصمة أو Face ID تلقائياً عند فتح التطبيق والدخول'
                        : 'Active ✅ — Requires Fingerprint / Face ID when opening the app')
                    : (isArabic
                        ? 'متوقفة 🔓 — يدخل مباشرة للجلسة المحفوظة بدون طلب البصمة/الوجه'
                        : 'Off 🔓 — Opens remembered session directly without biometric prompt'),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: state.biometricEnabled ? accentGreen : textSecondary,
                ),
              ),
              value: state.biometricEnabled,
              activeTrackColor: accentGreen,
              onChanged: _isCheckingBiometric ? null : _handleBiometricToggle,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor:
                    (state.isOnline ? accentGreen : AppColors.warning)
                        .withValues(alpha: 0.14),
                child: Icon(
                  state.isOnline
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: state.isOnline ? accentGreen : AppColors.warning,
                ),
              ),
              title: Text(
                state.isOnline
                    ? (isArabic
                        ? 'متصل بالإنترنت (Online Sync)'
                        : 'Online • Real-Time Sync Connected')
                    : (isArabic
                        ? 'وضع عدم الاتصال (Offline Mode)'
                        : 'Offline • Local Cache Active'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                '${isArabic ? 'آخر مزامنة:' : 'Last synced:'} ${DateFormat('hh:mm:ss a').format(state.lastSyncedAt)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textSecondary,
                ),
              ),
              trailing: OutlinedButton.icon(
                onPressed: state.isSyncing
                    ? null
                    : () => context.read<LmtCubit>().syncNow(),
                icon: state.isSyncing
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: Text(isArabic ? 'مزامنة' : 'Sync'),
              ),
            ),
            if (!kIsWeb &&
                defaultTargetPlatform == TargetPlatform.android) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: (_ignoringBatteryOptimizations
                          ? accentGreen
                          : AppColors.warning)
                      .withValues(alpha: 0.14),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: _ignoringBatteryOptimizations
                        ? accentGreen
                        : AppColors.warning,
                  ),
                ),
                title: Text(
                  isArabic
                      ? 'استلام الإشعارات بالخلفية وشاشة القفل'
                      : 'Lock-Screen & Background Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: textPrimary,
                  ),
                ),
                subtitle: Text(
                  _ignoringBatteryOptimizations
                      ? (isArabic
                          ? 'مفعل ✅ — مستثنى من قيود توفير البطارية'
                          : 'Active ✅ — Unrestricted background alerts')
                      : (isArabic
                          ? 'اسمح بالعمل في الخلفية لضمان وصول التنبيهات والشاشة مقفولة'
                          : 'Allow unrestricted battery so alerts arrive while locked'),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _ignoringBatteryOptimizations
                        ? accentGreen
                        : AppColors.warning,
                  ),
                ),
                trailing: _ignoringBatteryOptimizations
                    ? Icon(Icons.verified_rounded, color: accentGreen)
                    : OutlinedButton(
                        onPressed: () async {
                          await BackgroundSyncBridge
                              .requestIgnoreBatteryOptimizations();
                          await Future<void>.delayed(
                            const Duration(milliseconds: 600),
                          );
                          await _loadBatteryOptimizationStatus();
                        },
                        child: Text(isArabic ? 'تفعيل' : 'Allow'),
                      ),
              ),
            ],
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: primary.withValues(alpha: 0.14),
                child: Icon(
                  Icons.system_update_alt_rounded,
                  color: primary,
                ),
              ),
              title: Text(
                isArabic
                    ? 'التحديث التلقائي (Shorebird OTA)'
                    : 'Auto Updates (Shorebird OTA)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                '${isArabic ? 'الإصدار الحالي:' : 'Current Version:'} $_versionLabel',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textSecondary,
                ),
              ),
              trailing: OutlinedButton.icon(
                onPressed: _isCheckingUpdates ? null : _handleCheckForUpdates,
                icon: _isCheckingUpdates
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined, size: 16),
                label: Text(isArabic ? 'تحديثات' : 'Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
