import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubit/khelwa_cubit.dart';
import '../../../core/theme/colors.dart';

/// Daily Spiritual Khelwa Tracker Screen.
///
/// - Dynamically calculates every day from today (`DateTime.now()`) how many days
///   have elapsed since the user last took Khelwa.
/// - Records today's Khelwa for the active user and updates the daily attendance list.
/// - Automatically publishes the daily list of names of members who took Khelwa today
///   into the dedicated `grp_khelwa` ("جروب الخلوة اليومية 🙏") chat group.
class KhelwaScreen extends StatefulWidget {
  const KhelwaScreen({super.key});

  @override
  State<KhelwaScreen> createState() => KhelwaScreenState();
}

class KhelwaScreenState extends State<KhelwaScreen> {
  static const String khelwaKeyPrefix = 'last_khelwa_date';
  static const String attendeesKeyPrefix = 'khelwa_attendees_';

  int daysDifference = 1;
  DateTime? lastKhelwaDate;
  List<String> todayAttendees = const [];
  bool isLoading = true;
  bool isSaving = false;

  String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _userKhelwaKey(String userId) => '${khelwaKeyPrefix}_$userId';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadKhelwaData();
    });
  }

  // ============================================================
  // Load Last Khelwa Date & Today's Attendees List
  // ============================================================

  Future<void> loadKhelwaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final cubit = context.read<LmtCubit>();
      final currentUser = cubit.state.currentUser;
      final userKey = _userKhelwaKey(currentUser.id);
      final todayKey = _todayDateKey();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      String? savedDateString =
          prefs.getString(userKey) ?? prefs.getString(khelwaKeyPrefix);

      // Load today's attendees list
      final savedAttendees =
          prefs.getStringList('$attendeesKeyPrefix$todayKey') ?? <String>[];

      if (savedDateString == null) {
        // Initialize baseline to yesterday so the counter starts at 1 day and increments every day from today
        final yesterday = today.subtract(const Duration(days: 1));
        await prefs.setString(userKey, yesterday.toIso8601String());
        savedDateString = yesterday.toIso8601String();
      }

      final parsed = DateTime.parse(savedDateString);
      final lastDate = DateTime(parsed.year, parsed.month, parsed.day);
      final int difference = today.difference(lastDate).inDays;
      final int safeDiff = difference < 0 ? 0 : difference;

      // If user already took Khelwa today (safeDiff == 0), ensure their name is in today's list
      final attendees = List<String>.from(savedAttendees);
      if (safeDiff == 0 && !attendees.contains(currentUser.name)) {
        attendees.add(currentUser.name);
        await prefs.setStringList('$attendeesKeyPrefix$todayKey', attendees);
      }

      if (!mounted) return;
      setState(() {
        daysDifference = safeDiff;
        lastKhelwaDate = lastDate;
        todayAttendees = attendees;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        daysDifference = 1;
        isLoading = false;
      });
    }
  }

  // ============================================================
  // Record Today's Khelwa & Publish Names to Dedicated Khelwa Group
  // ============================================================

  Future<void> recordKhelwa() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final cubit = context.read<LmtCubit>();
      final currentUser = cubit.state.currentUser;
      final userKey = _userKhelwaKey(currentUser.id);
      final todayKey = _todayDateKey();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await prefs.setString(userKey, now.toIso8601String());
      await prefs.setString(khelwaKeyPrefix, now.toIso8601String());

      final currentList =
          prefs.getStringList('$attendeesKeyPrefix$todayKey') ?? <String>[];
      final updatedAttendees = List<String>.from(currentList);
      if (!updatedAttendees.contains(currentUser.name)) {
        updatedAttendees.add(currentUser.name);
      }
      await prefs.setStringList(
        '$attendeesKeyPrefix$todayKey',
        updatedAttendees,
      );

      // Publish / update today's Khelwa attendees list in the dedicated Khelwa group ('grp_khelwa')
      await cubit.publishDailyKhelwaSummaryToGroup(
        attendeesNames: updatedAttendees,
        forDate: now,
      );

      if (!mounted) return;

      setState(() {
        daysDifference = 0;
        lastKhelwaDate = today;
        todayAttendees = updatedAttendees;
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: const Color(0xFF00C853),
                      size: 19.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'تم تسجيل الخلوة وإضافة اسمك لقائمة اليوم في جروب الخلوة 🙏',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'حدث خطأ أثناء تسجيل الخلوة',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
        );
    }
  }

  void _openKhelwaGroup() {
    final cubit = context.read<LmtCubit>();
    cubit.setActiveLayoutTab(1, openGroupId: 'grp_khelwa');
    Navigator.pop(context);
  }

  // ============================================================
  // Counter Circle
  // ============================================================

  Widget buildCounterCircle() {
    return Container(
      width: 240.w,
      height: 240.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4285F4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'آخر مرة أخدت الخلوة',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                  height: 1.3,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$daysDifference',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    'يوم',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                daysDifference == 0
                    ? 'أنت واخد خلوتك النهاردة ✨'
                    : 'بقالك $daysDifference يوم مأخدتش خلوة',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Khelwa Button
  // ============================================================

  Widget buildKhelwaButton() {
    final bool canTakeKhelwaToday = daysDifference > 0;
    return SizedBox(
      width: 240.w,
      height: 54.h,
      child: ElevatedButton(
        onPressed: canTakeKhelwaToday ? (isSaving ? null : recordKhelwa) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          disabledBackgroundColor:
              const Color(0xFF00C853).withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: canTakeKhelwaToday ? 5 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.20),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
        ),
        child: isSaving
            ? SizedBox(
                width: 23.w,
                height: 23.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: const Color(0xFF00C853),
                        size: 17.sp,
                      ),
                    ),
                    SizedBox(width: 9.w),
                    Text(
                      canTakeKhelwaToday
                          ? 'أخدت الخلوة'
                          : 'تم تسجيل خلوة اليوم ✅',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.5.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ============================================================
  // Today's Khelwa Attendees Card & Group Link
  // ============================================================

  Widget buildTodayAttendeesCard(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final todayKey = _todayDateKey();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: AppColors.cardDecoration(
        context,
        radius: 20.r,
        accentColor: primary,
        isHighlighted: true,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, color: primary, size: 22.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'قائمة اللي أخدوا الخلوة انهاردة ($todayKey) 🙏',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: accentGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${todayAttendees.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: accentGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'يتم إرسال وتحديث هذه القائمة تلقائياً في نهاية كل يوم داخل (جروب الخلوة اليومية 🙏)',
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'Cairo',
                color: textSecondary,
              ),
            ),
            const Divider(height: 18),
            if (todayAttendees.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  'لم يسجل أحد الخلوة اليوم حتى الآن.. كن أول من يأخذ خلوته اليوم! ✨',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'Cairo',
                    color: textSecondary,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: todayAttendees.asMap().entries.map((entry) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: accentGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: accentGreen,
                          size: 15.sp,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          '${entry.key + 1}. ${entry.value}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary, width: 1.4),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: () async {
                  await context
                      .read<LmtCubit>()
                      .publishDailyKhelwaSummaryToGroup(
                        attendeesNames: todayAttendees,
                      );
                  if (!mounted) return;
                  _openKhelwaGroup();
                },
                icon: const Icon(Icons.forum_rounded),
                label: Text(
                  'فتح جروب الخلوة اليومية وعرض قائمة اليوم 💬',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
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
            icon: Icon(Icons.chat_rounded, color: primary),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4285F4)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    buildCounterCircle(),
                    SizedBox(height: 36.h),
                    buildKhelwaButton(),
                    SizedBox(height: 32.h),
                    buildTodayAttendeesCard(context),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
      ),
    );
  }
}
