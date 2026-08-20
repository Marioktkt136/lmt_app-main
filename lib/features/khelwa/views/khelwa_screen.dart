import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KhelwaScreen extends StatefulWidget {
  const KhelwaScreen({super.key});

  @override
  State<KhelwaScreen> createState() => KhelwaScreenState();
}

class KhelwaScreenState extends State<KhelwaScreen> {
  static const String khelwaKey = 'last_khelwa_date';

  int daysDifference = 0;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadKhelwaData();
  }

  // ============================================================
  // Load Last Khelwa Date
  // ============================================================

  Future<void> loadKhelwaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? savedDateString = prefs.getString(khelwaKey);

      if (savedDateString == null) {
        if (!mounted) return;

        setState(() {
          daysDifference = 0;
          isLoading = false;
        });

        return;
      }

      final DateTime lastKhelwaDate = DateTime.parse(savedDateString);

      final DateTime lastDate = DateTime(
        lastKhelwaDate.year,
        lastKhelwaDate.month,
        lastKhelwaDate.day,
      );

      final DateTime now = DateTime.now();

      final DateTime today = DateTime(now.year, now.month, now.day);

      final int difference = today.difference(lastDate).inDays;

      if (!mounted) return;

      setState(() {
        daysDifference = difference < 0 ? 0 : difference;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        daysDifference = 0;
        isLoading = false;
      });
    }
  }

  // ============================================================
  // Record Khelwa
  // ============================================================

  Future<void> recordKhelwa() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final DateTime now = DateTime.now();

      await prefs.setString(khelwaKey, now.toIso8601String());

      if (!mounted) return;

      setState(() {
        daysDifference = 0;
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
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, color: const Color(0xFF00C853), size: 19.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'تم تسجيل الخلوة بنجاح',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14.sp,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء تسجيل الخلوة', textAlign: TextAlign.center),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          ),
        );
    }
  }

  // ============================================================
  // Counter Circle
  // ============================================================

  Widget buildCounterCircle() {
    return Container(
      width: 260.w,
      height: 260.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4285F4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 7),
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
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                  height: 1.3,
                ),
              ),

              SizedBox(height: 12.h),

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
                      fontSize: 50.sp,
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
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
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
    return SizedBox(
      width: 220.w,
      height: 56.h,
      child: ElevatedButton(
        onPressed: (daysDifference > 0 ? (isSaving ? null : recordKhelwa) : null),

        style: daysDifference > 0
            ? ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                disabledBackgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.20),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
              )
            : null,
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
                      width: 23.w,
                      height: 23.w,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.check_rounded, color: const Color(0xFF00C853), size: 17.sp),
                    ),

                    SizedBox(width: 9.w),

                    Text(
                      'أخدت الخلوة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
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
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4285F4)))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),

                    child: SizedBox(
                      height: constraints.maxHeight,

                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 60.w),

                        child: Column(
                          children: [
                            // ==================================
                            // Top Space
                            // ==================================
                            SizedBox(height: 200.h),

                            // ==================================
                            // Blue Circle
                            // ==================================
                            buildCounterCircle(),

                            // ==================================
                            // Space Between Circle & Button
                            // ==================================
                            SizedBox(height: 80.h),

                            // ==================================
                            // Green Button
                            // ==================================
                            buildKhelwaButton(),

                            // ==================================
                            // Bottom Space
                            // ==================================
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
