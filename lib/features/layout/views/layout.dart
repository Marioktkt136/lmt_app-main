import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/layout_cubit.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/header_banner.dart';
import '../../calendar/views/calendar_screen.dart';
import '../../chatting_room/views/chatting_room.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../../home/views/home_screen.dart';
import '../../members/views/members_screen.dart';
import '../widgets/lmt_navigation_drawer.dart';

/// Primary application shell managing the 5 swipeable feature pages,
/// the top [CustomAppBar], the [LmtNavigationDrawer], and the [BottomNavBar].
class Layout extends StatefulWidget {
  /// The initial tab index to display (defaults to `0` for Posts Feed).
  final int initialIndex;

  /// Creates a [Layout].
  const Layout({super.key, this.initialIndex = 0});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  final List<Widget> _pages = const [
    HomeScreen(), // Index 0: Posts Feed (Timeline)
    ChattingRoom(), // Index 1: Chatting Room (Groups & Messages)
    DashboardScreen(), // Index 2: Shared Files & Documents
    CalendarScreen(), // Index 3: Calendar for Events 🗓️
    MembersScreen(), // Index 4: Member List View
  ];

  late int _selectedIndex;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LmtCubit>().setActiveLayoutTab(_selectedIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _pageController = null;
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (!mounted) return;
    if (index < 0 || index >= _pages.length) return;
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
    context.read<LmtCubit>().setActiveLayoutTab(index);

    final controller = _pageController;
    if (controller != null && controller.hasClients) {
      controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    if (index < 0 || index >= _pages.length) return;
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
    context.read<LmtCubit>().setActiveLayoutTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _pageController;
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);

    return BlocListener<LmtCubit, LmtState>(
      listenWhen: (prev, curr) => prev.activeLayoutTab != curr.activeLayoutTab,
      listener: (context, state) {
        final target = state.activeLayoutTab.clamp(0, _pages.length - 1);
        if (_selectedIndex != target) {
          setState(() => _selectedIndex = target);
          if (controller != null && controller.hasClients) {
            controller.jumpToPage(target);
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A2536) : AppColors.primary,
        drawer: const LmtNavigationDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: CustomAppBar(),
              ),

              // Offline / Online Connection Detector Banner
              BlocBuilder<LmtCubit, LmtState>(
                buildWhen: (p, c) => p.isOnline != c.isOnline,
                builder: (context, state) {
                  if (state.isOnline) return const SizedBox.shrink();
                  final isArabic =
                      Localizations.localeOf(context).languageCode == 'ar';
                  return Container(
                    width: double.infinity,
                    margin:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          isArabic
                              ? 'وضع عدم الاتصال: يتم العمل من الذاكرة المحلية وسيتم المزامنة تلقائياً'
                              : 'Offline Mode: Using local cached data, auto-sync enabled',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Main Surface Container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOf(context),
                    borderRadius: BorderRadius.circular(34.r),
                    border: Border.all(
                      color: isDark
                          ? primary.withValues(alpha: 0.25)
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const HeaderBanner(),
                          SizedBox(height: 6.h),
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
              ),

              // Bottom Navigation Bar (5 Tabs)
              BottomNavBar(
                selectedIndex: _selectedIndex,
                onTap: _onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
