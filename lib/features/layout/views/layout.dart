import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/layout_cubit.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/shorebird_update_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/header_banner.dart';
import '../../../core/widgets/shorebird_welcome_dialog.dart';
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

class _LayoutState extends State<Layout> with WidgetsBindingObserver {
  final List<Widget> _pages = const [
    HomeScreen(), // Index 0: Posts Feed (Timeline)
    ChattingRoom(), // Index 1: Chatting Room (Groups & Messages)
    DashboardScreen(), // Index 2: Shared Files & Documents
    CalendarScreen(), // Index 3: Calendar for Events 🗓️
    MembersScreen(), // Index 4: Member List View
  ];

  late int _selectedIndex;
  PageController? _pageController;
  bool _hasShownUpdateWelcome = false;

  Future<void> _syncOsNotificationPermissions({bool requestIfMobile = false}) async {
    if (requestIfMobile && !kIsWeb) {
      await LocalNotificationService.requestOsPermissions();
    } else {
      await LocalNotificationService.areOsNotificationsEnabled();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<LmtCubit>();
        final pendingTab = cubit.state.selectedCalendarEventId != null
            ? 3
            : (cubit.state.selectedChatGroupId != null ? 1 : _selectedIndex);
        if (pendingTab != _selectedIndex) {
          setState(() => _selectedIndex = pendingTab);
          _pageController?.jumpToPage(pendingTab);
        }
        cubit.setActiveLayoutTab(
          pendingTab,
          openGroupId: cubit.state.selectedChatGroupId,
          openEventId: cubit.state.selectedCalendarEventId,
        );
        _syncOsNotificationPermissions(requestIfMobile: !kIsWeb);
        cubit.syncDueCalendarReminders();
        _checkOtaUpdatesAndWelcome();
      }
    });
  }

  void _checkOtaUpdatesAndWelcome() {
    ShorebirdUpdateService.instance.checkAndSyncUpdates().then((result) {
      final welcome = result.welcomeMessage;
      if (welcome != null && mounted && !_hasShownUpdateWelcome) {
        _hasShownUpdateWelcome = true;
        ShorebirdWelcomeDialog.show(context, welcome);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final cubit = context.read<LmtCubit>();
      _syncOsNotificationPermissions();
      cubit.syncDueCalendarReminders();
      if (!cubit.state.isSyncing) {
        cubit.syncNow();
      }
      _checkOtaUpdatesAndWelcome();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide =
                  constraints.maxWidth >= AdaptiveBreakpoints.navRailMinWidth;
              final isExtendedRail = constraints.maxWidth >=
                  AdaptiveBreakpoints.navRailExtendedMinWidth;
              final isArabic = Localizations.localeOf(context).languageCode == 'ar';

              final surfaceArea = Expanded(
                child: Container(
                  margin: isWide
                      ? EdgeInsetsDirectional.only(end: 10.w, bottom: 8.h)
                      : EdgeInsets.zero,
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
                      padding: EdgeInsets.only(
                        left: 14.w,
                        right: 14.w,
                        top: 5.h,
                        bottom: 6.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const HeaderBanner(),
                          SizedBox(height: 4.h),
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
              );

              final railDestinations = <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: const Icon(Icons.dynamic_feed_outlined),
                  selectedIcon: const Icon(Icons.dynamic_feed_rounded),
                  label: Text(isArabic ? 'المنشورات' : 'Posts'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.forum_outlined),
                  selectedIcon: const Icon(Icons.forum_rounded),
                  label: Text(isArabic ? 'المحادثات' : 'Chats'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.folder_copy_outlined),
                  selectedIcon: const Icon(Icons.folder_copy_rounded),
                  label: Text(isArabic ? 'الملفات' : 'Files'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(Icons.calendar_month_rounded),
                  label: Text(isArabic ? 'التقويم' : 'Calendar'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.people_alt_outlined),
                  selectedIcon: const Icon(Icons.people_alt_rounded),
                  label: Text(isArabic ? 'الأعضاء' : 'Members'),
                ),
              ];

              return Column(
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
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
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
                            Flexible(
                              child: Text(
                                isArabic
                                    ? 'وضع عدم الاتصال: يتم العمل من الذاكرة المحلية وسيتم المزامنة تلقائياً'
                                    : 'Offline Mode: Using local cached data, auto-sync enabled',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Main Adaptive Content Area
                  if (isWide)
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            margin: EdgeInsetsDirectional.only(
                              start: 10.w,
                              end: 8.w,
                              bottom: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(26.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26.r),
                              child: LayoutBuilder(
                                builder: (context, railConstraints) {
                                  return SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: railConstraints.maxHeight,
                                      ),
                                      child: IntrinsicHeight(
                                        child: NavigationRail(
                                          selectedIndex: _selectedIndex,
                                          onDestinationSelected: _onTabChanged,
                                          extended: isExtendedRail,
                                          backgroundColor: Colors.transparent,
                                          selectedIconTheme:
                                              IconThemeData(color: primary),
                                          selectedLabelTextStyle: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.sp,
                                          ),
                                          unselectedIconTheme: IconThemeData(
                                            color: AppColors.textSecondaryOf(
                                                context),
                                          ),
                                          unselectedLabelTextStyle: TextStyle(
                                            color: AppColors.textSecondaryOf(
                                                context),
                                            fontSize: 11.5.sp,
                                          ),
                                          indicatorColor:
                                              primary.withValues(alpha: 0.14),
                                          labelType: isExtendedRail
                                              ? NavigationRailLabelType.none
                                              : NavigationRailLabelType.all,
                                          destinations: railDestinations,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          surfaceArea,
                        ],
                      ),
                    )
                  else ...[
                    surfaceArea,
                    BottomNavBar(
                      selectedIndex: _selectedIndex,
                      onTap: _onTabChanged,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
