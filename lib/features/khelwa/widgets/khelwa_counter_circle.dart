import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// Big blue circle showing how many days passed since the last Khelwa.
class KhelwaCounterCircle extends StatelessWidget {
  /// Days since last Khelwa (0 = taken today).
  final int daysDifference;

  /// Creates a [KhelwaCounterCircle].
  const KhelwaCounterCircle({super.key, required this.daysDifference});

  static const Color _blue = Color(0xFF4285F4);

  @override
  Widget build(BuildContext context) {
    final statusText = daysDifference == 0
        ? 'أنت واخد خلوتك النهاردة ✨'
        : 'بقالك $daysDifference يوم مأخدتش خلوة';
    return Semantics(
      label: 'آخر مرة أخدت الخلوة: $daysDifference يوم. $statusText',
      excludeSemantics: true,
      child: Container(
        width: 240.w,
        height: 240.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _blue,
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.35),
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
                _text('آخر مرة أخدت الخلوة', 18.sp, FontWeight.w700, height: 1.3),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    _text('$daysDifference', 48.sp, FontWeight.w700,
                        height: 1, dir: TextDirection.ltr),
                    SizedBox(width: 7.w),
                    _text('يوم', 28.sp, FontWeight.w600),
                  ],
                ),
                SizedBox(height: 8.h),
                _text(statusText, 12.sp, FontWeight.w600, alpha: 0.9),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Text _text(
    String value,
    double size,
    FontWeight weight, {
    double? height,
    double alpha = 1,
    TextDirection dir = TextDirection.rtl,
  }) {
    return Text(
      value,
      textAlign: TextAlign.center,
      textDirection: dir,
      style: TextStyle(
        color: Colors.white.withValues(alpha: alpha),
        fontSize: size,
        fontWeight: weight,
        fontFamily: 'Cairo',
        height: height,
      ),
    );
  }
}
