import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'features/auth/services/biometric_session_lock_controller.dart';
import 'features/auth/widgets/biometric_lock_overlay.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await LocalNotificationService.init();

  // Initialize temporary Firebase backend (non-blocking if offline).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  // Set system UI overlay style (do not lock orientation so phones, foldables,
  // and tablets adapt smoothly across portrait and landscape windows).
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

class LMTAppState extends State<LMTApp> with WidgetsBindingObserver {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeMode = widget.initialThemeMode;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockController = BiometricSessionLockController.instance;
    lockController.handleAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      di.sl<LmtCubit>().reconcileBackgroundNotifications();
    }
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 375.0;
          final height =
              constraints.hasBoundedHeight && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : 812.0;
          final isWideOrLandscape = width >= 540 || width > height;
          final designSize = isWideOrLandscape
              ? Size(
                  width / (width / 390).clamp(0.92, 1.16),
                  height / (height / 812).clamp(0.90, 1.12),
                )
              : const Size(375, 812);

          return ScreenUtilInit(
            designSize: designSize,
            minTextAdapt: true,
            splitScreenMode: true,
            rebuildFactor: RebuildFactors.size,
            builder: (context, child) {
              return MaterialApp(
                navigatorKey: AppRouter.navigatorKey,
                title: 'L.M.T - The Last Message Team',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: _themeMode,
                initialRoute: Routes.splash,
                onGenerateRoute: AppRouter.generateRoute,
                builder: (context, child) {
                  return Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      ValueListenableBuilder<bool>(
                        valueListenable:
                            BiometricSessionLockController.instance.isLocked,
                        builder: (context, locked, _) {
                          if (!locked ||
                              !BiometricSessionLockController
                                  .instance.isInAuthenticatedShell) {
                            return const SizedBox.shrink();
                          }
                          return const Positioned.fill(
                            child: BiometricLockOverlay(),
                          );
                        },
                      ),
                    ],
                  );
                },
                localizationsDelegates: [
                  ...GlobalMaterialLocalizations.delegates,
                  ...context.localizationDelegates,
                ],
                supportedLocales: context.supportedLocales,
                locale: context.locale,
              );
            },
          );
        },
      ),
    );
  }
}
