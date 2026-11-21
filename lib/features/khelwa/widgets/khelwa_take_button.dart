import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// Green "I took Khelwa" button. Disabled once today's Khelwa is recorded.
class KhelwaTakeButton extends StatelessWidget {
  /// Whether the user can still record Khelwa today.
  final bool canTakeToday;

  /// Whether a save is in progress (shows a spinner).
  final bool isSaving;

  /// Called when the user taps the enabled button.
  final VoidCallback onPressed;

  /// Creates a [KhelwaTakeButton].
  const KhelwaTakeButton({
    super.key,
    required this.canTakeToday,
    required this.isSaving,
    required this.onPressed,
  });

  static const Color _green = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240.w,
      height: 54.h,
      child: ElevatedButton(
        onPressed: canTakeToday && !isSaving ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: _green.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: canTakeToday ? 5 : 0,
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
                      child: Icon(Icons.check_rounded, color: _green, size: 17.sp),
                    ),
                    SizedBox(width: 9.w),
                    Text(
                      canTakeToday ? 'أخدت الخلوة' : 'تم تسجيل خلوة اليوم ✅',
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
}
