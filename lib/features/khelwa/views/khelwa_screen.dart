import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../cubit/khelwa_cubit.dart';
import '../data/khelwa_repository.dart';
import '../widgets/khelwa_attendees_card.dart';
import '../widgets/khelwa_counter_circle.dart';
import '../widgets/khelwa_snackbars.dart';
import '../widgets/khelwa_take_button.dart';

/// Daily Spiritual Khelwa Tracker Screen.
///
/// Composes the counter, the "I took Khelwa" button and today's attendees.
/// Persistence lives in [KhelwaRepository]; publishing to the `grp_khelwa`
/// chat group goes through [LmtCubit.publishDailyKhelwaSummaryToGroup].
class KhelwaScreen extends StatefulWidget {
  /// Creates a [KhelwaScreen].
  const KhelwaScreen({super.key});

  @override
  State<KhelwaScreen> createState() => _KhelwaScreenState();
}

class _KhelwaScreenState extends State<KhelwaScreen> {
  static const KhelwaRepository _repo = KhelwaRepository();

  int _daysDifference = 1;
  List<String> _attendees = const [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<LmtCubit>().state.currentUser;
    try {
      final snap = await _repo.load(userId: user.id, userName: user.name);
      if (!mounted) return;
      setState(() {
        _daysDifference = snap.daysDifference;
        _attendees = snap.todayAttendees;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _daysDifference = 1;
        _isLoading = false;
      });
    }
  }

  Future<void> _record() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final cubit = context.read<LmtCubit>();
    final user = cubit.state.currentUser;
    try {
      final snap = await _repo.record(userId: user.id, userName: user.name);
      await cubit.publishDailyKhelwaSummaryToGroup(
        attendeesNames: snap.todayAttendees,
        forDate: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _daysDifference = 0;
        _attendees = snap.todayAttendees;
        _isSaving = false;
      });
      KhelwaSnackbars.showRecorded(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      KhelwaSnackbars.showError(context);
    }
  }

  void _openKhelwaGroup() {
    context.read<LmtCubit>().setActiveLayoutTab(1, openGroupId: 'grp_khelwa');
    Navigator.pop(context);
  }

  Future<void> _publishThenOpenGroup() async {
    await context
        .read<LmtCubit>()
        .publishDailyKhelwaSummaryToGroup(attendeesNames: _attendees);
    if (!mounted) return;
    _openKhelwaGroup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الخلوة اليومية 🙏',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'جروب الخلوة اليومية',
            onPressed: _openKhelwaGroup,
            icon: Icon(Icons.chat_rounded, color: AppColors.primaryOf(context)),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4285F4)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    KhelwaCounterCircle(daysDifference: _daysDifference),
                    SizedBox(height: 36.h),
                    KhelwaTakeButton(
                      canTakeToday: _daysDifference > 0,
                      isSaving: _isSaving,
                      onPressed: _record,
                    ),
                    SizedBox(height: 32.h),
                    KhelwaAttendeesCard(
                      attendees: _attendees,
                      onOpenGroup: _publishThenOpenGroup,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
      ),
    );
  }
}
