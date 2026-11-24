import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/user_role.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../cubit/khelwa_cubit.dart';
import '../widgets/khelwa_attendees_card.dart';
import '../widgets/khelwa_counter_circle.dart';
import '../widgets/khelwa_take_button.dart';

/// Daily Spiritual Khelwa Tracker Screen.
///
/// Reads real-time cloud-synced check-in lists (`khelwa_days`) from [LmtCubit]
/// so today's attendees list stays accurate across all members and devices.
class KhelwaScreen extends StatefulWidget {
  /// Creates a [KhelwaScreen].
  const KhelwaScreen({super.key});

  @override
  State<KhelwaScreen> createState() => _KhelwaScreenState();
}

class _KhelwaScreenState extends State<KhelwaScreen> {
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _record() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await context.read<LmtCubit>().recordTodayKhelwa();
      if (!mounted) return;
      setState(() => _isSaving = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'حدث خطأ أثناء تسجيل الخلوة، يرجى المحاولة مرة أخرى.';
      });
    }
  }

  void _openKhelwaGroup() {
    context.read<LmtCubit>().setActiveLayoutTab(1, openGroupId: 'grp_khelwa');
    Navigator.pop(context);
  }

  Future<void> _confirmAndResetToday() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير قائمة اليوم 🔄'),
        content: const Text(
          'هل أنت متأكد من رغبتك في مسح وإعادة ضبط قائمة من أخذوا الخلوة اليوم للجميع؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تصفير القائمة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<LmtCubit>().resetTodayKhelwa();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);
    final appBarBg = isDark ? AppColors.surfaceDark : AppColors.primary;
    final appBarFg = isDark ? AppColors.textPrimaryDark : Colors.white;

    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final cubit = context.read<LmtCubit>();
        final daysDifference =
            cubit.khelwaDaysDifferenceForUser(state.currentUser.id);
        final attendees = cubit.todayKhelwaAttendees();

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            backgroundColor: appBarBg,
            foregroundColor: appBarFg,
            iconTheme: IconThemeData(color: appBarFg),
            actionsIconTheme:
                IconThemeData(color: isDark ? primary : Colors.white),
            elevation: isDark ? 0 : 2,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            centerTitle: true,
            shape: isDark
                ? Border(
                    bottom: BorderSide(
                      color: primary.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  )
                : null,
            title: Text(
              'الخلوة اليومية 🙏',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: appBarFg,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'جروب الخلوة اليومية',
                onPressed: _openKhelwaGroup,
                icon: Icon(
                  Icons.chat_rounded,
                  color: isDark ? primary : Colors.white,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: AdaptiveContentBox(
              maxWidth: 680,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    KhelwaCounterCircle(daysDifference: daysDifference),
                    SizedBox(height: 36.h),
                    KhelwaTakeButton(
                      canTakeToday: daysDifference > 0,
                      isSaving: _isSaving,
                      onPressed: _record,
                    ),
                    if (_errorMessage != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    SizedBox(height: 32.h),
                    KhelwaAttendeesCard(
                      attendees: attendees,
                      isAdmin: state.currentUser.role == UserRole.admin,
                      onResetToday: _confirmAndResetToday,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
