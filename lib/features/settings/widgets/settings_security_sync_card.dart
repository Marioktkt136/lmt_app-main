import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../cubit/settings_cubit.dart';

/// Security, Biometric Login, and Offline/Online Sync section card.
class SettingsSecuritySyncCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                backgroundColor: accentGreen.withValues(alpha: 0.12),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: accentGreen,
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
                isArabic
                    ? 'تفعيل المصادقة البيومترية السريعة (Android / iOS)'
                    : 'Enable biometric authentication (Android / iOS)',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textSecondary,
                ),
              ),
              value: state.biometricEnabled,
              activeTrackColor: accentGreen,
              onChanged: (v) =>
                  context.read<LmtCubit>().setBiometricEnabled(v),
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
          ],
        ),
      ),
    );
  }
}
