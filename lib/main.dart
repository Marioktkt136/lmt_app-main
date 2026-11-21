import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import 'core/cubit/lmt_cubit.dart';
import 'core/di/injection_container.dart' as di;
import 'core/localization/localization_manager.dart';
import 'core/routes/app_router.dart';
import 'core/routes/routes.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await LocalNotificationService.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize dependency injection
  await di.init();

  // Load persisted preferences
  final themeMode = await AppPreferences.getThemeMode();
  final savedLocale = await AppPreferences.getSavedLocale();

  runApp(
    EasyLocalization(
      supportedLocales: LocalizationManager.supportedLocales,
      path: LocalizationManager.translationsPath,
      fallbackLocale: LocalizationManager.fallbackLocale,
      startLocale: savedLocale ?? const Locale('ar'),
      child: LMTApp(initialThemeMode: themeMode),
    ),
  );
}

class LMTApp extends StatefulWidget {
  const LMTApp({super.key, required this.initialThemeMode});

  final ThemeMode initialThemeMode;

  static LMTAppState of(BuildContext context) {
    return context.findAncestorStateOfType<LMTAppState>()!;
  }

  @override
  State<LMTApp> createState() => LMTAppState();
}

class LMTAppState extends State<LMTApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    await AppPreferences.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LmtCubit>.value(
      value: di.sl<LmtCubit>(),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'L.M.T - The Last Message Team',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeMode,
            initialRoute: Routes.splash,
            onGenerateRoute: AppRouter.generateRoute,
            localizationsDelegates: [
              ...GlobalMaterialLocalizations.delegates,
              ...context.localizationDelegates,
            ],
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          );
        },
      ),
    );
  }
}
