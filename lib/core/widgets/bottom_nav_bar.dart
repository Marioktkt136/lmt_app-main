import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.selectedIndex, required this.onTap});

  final List<IconData> icons = const [
    Icons.grid_view_rounded, // Dashboard (Index 0)
    Icons.home_rounded, // Home (Index 1)
    Icons.chat, // ChattingRoom (Index 2)
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 5.h),
      child: Container(
        height: 45.h,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32.r)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                /// Active Circle
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: [
                    Alignment.centerLeft,
                    Alignment.center,
                    Alignment.centerRight,
                  ][selectedIndex],
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  ),
                ),

                /// Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    icons.length,
                    (index) => GestureDetector(
                      onTap: () => onTap(index),
                      child: SizedBox(
                        width: 40.w,
                        height: 40.w,
                        child: Icon(
                          icons[index],
                          color: selectedIndex == index ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
