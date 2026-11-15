import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/widgets/app_bar.dart';
import 'package:lmt/core/widgets/bottom_nav_bar.dart';
import 'package:lmt/core/widgets/header_banner.dart';
import 'package:lmt/features/chatting_room/views/chatting_room.dart';
import 'package:lmt/features/dashboard/views/dashboard_screen.dart';
import 'package:lmt/features/home/views/home_screen.dart';

class Layout extends StatefulWidget {
  final int initialIndex;

  const Layout({super.key, this.initialIndex = 1});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  // ------------------------------------------------------------
  // Pages
  // ------------------------------------------------------------

  final List<Widget> _pages = const [
    DashboardScreen(), // Index 0
    HomeScreen(), // Index 1
    ChattingRoom(), // Index 2
  ];

  // ------------------------------------------------------------
  // State
  // ------------------------------------------------------------

  late int _selectedIndex;

  PageController? _pageController;

  // ------------------------------------------------------------
  // Init
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Make sure initialIndex is valid.
    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);

    _pageController = PageController(initialPage: _selectedIndex);
  }

  // ------------------------------------------------------------
  // Dispose
  // ------------------------------------------------------------

  @override
  void dispose() {
    _pageController?.dispose();
    _pageController = null;

    super.dispose();
  }

  // ------------------------------------------------------------
  // Bottom Navigation
  // ------------------------------------------------------------

  void _onTabChanged(int index) {
    if (!mounted) return;

    if (index < 0 || index >= _pages.length) {
      return;
    }

    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    final controller = _pageController;

    if (controller == null || !controller.hasClients) {
      return;
    }

    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ------------------------------------------------------------
  // PageView Changed
  // ------------------------------------------------------------

  void _onPageChanged(int index) {
    if (!mounted) return;

    if (index < 0 || index >= _pages.length) {
      return;
    }

    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // ------------------------------------------------------------
  // Build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final controller = _pageController;

    return Scaffold(
      backgroundColor: AppColors.primaryLight,

      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------------------------
            // Custom App Bar
            // --------------------------------------------------
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6.0), child: CustomAppBar()),

            // --------------------------------------------------
            // Main Container
            // --------------------------------------------------
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(40.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ----------------------------------------
                      // Header Banner
                      // ----------------------------------------
                      const HeaderBanner(),

                      SizedBox(height: 8.h),

                      // ----------------------------------------
                      // Swipeable Pages
                      // ----------------------------------------
                      Expanded(
                        child: controller == null
                            ? const SizedBox.shrink()
                            : PageView(
                                controller: controller,
                                scrollDirection: Axis.horizontal,
                                physics: const PageScrollPhysics(),
                                onPageChanged: _onPageChanged,
                                children: _pages,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // Bottom Navigation Bar
            // --------------------------------------------------
            BottomNavBar(selectedIndex: _selectedIndex, onTap: _onTabChanged),
          ],
        ),
      ),
    );
  }
}
