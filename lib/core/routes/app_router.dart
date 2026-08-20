import 'package:flutter/material.dart';

import 'package:lmt/features/khelwa/views/khelwa_screen.dart';
import 'package:lmt/features/layout/views/layout.dart';
import 'package:lmt/features/notification_screen/notification_screen.dart';
import 'package:lmt/features/youtube/views/youtube_screen.dart';

import 'routes.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/views/login_screen.dart';

enum SlideDirection { fromLeft, fromRight }

/// Application Router
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return _buildRoute(const SplashScreen(), settings);

      case Routes.home:
        return _buildRoute(const Layout(initialIndex: 1), settings);

      case Routes.dashboard:
        return _buildRoute(const Layout(initialIndex: 0), settings);

      case Routes.chattingRoom:
        return _buildRoute(const Layout(initialIndex: 2), settings);

      case Routes.login:
        return _buildRoute(const LoginScreen(), settings);

      case Routes.khelwa:
        return _buildRoute(const KhelwaScreen(), settings);

      case Routes.youtube:
        return _buildRoute(const YoutubeScreen(), settings);

      case Routes.notification:
        return _buildRoute(const NotificationScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(body: Center(child: Text('No route defined for ${settings.name}'))),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    final arguments = settings.arguments;

    SlideDirection direction = SlideDirection.fromRight;

    if (arguments is Map<String, dynamic>) {
      direction = arguments['direction'] ?? SlideDirection.fromRight;
    }

    Offset begin;

    if (direction == SlideDirection.fromRight) {
      begin = const Offset(1.0, 0.0);
    } else {
      begin = const Offset(-1.0, 0.0);
    }

    return PageRouteBuilder(
      settings: settings,

      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },

      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(position: animation.drive(tween), child: child);
      },

      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false, arguments: arguments);
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
