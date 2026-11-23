import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../api/api_interceptors.dart';
import '../config/app_config.dart';
import '../cubit/lmt_cubit.dart';
import '../network/network_info.dart';
import '../repositories/lmt_firestore_repository.dart';
import '../repositories/lmt_repository.dart';
import '../utils/app_preferences.dart';

final sl = GetIt.instance;

/// Initializes Dependency Injection following SOLID & Clean Architecture principles.
Future<void> init() async {
  //! Repositories (Temp Cloud Firestore DB; swap cleanly with ASP.NET Core API later)
  if (!sl.isRegistered<LmtRepository>()) {
    sl.registerLazySingleton<LmtRepository>(
      () => LmtFirestoreRepositoryImpl(),
    );
  }

  //! Application Cubit (Singleton State Management)
  if (!sl.isRegistered<LmtCubit>()) {
    sl.registerLazySingleton<LmtCubit>(
      () => LmtCubit(repository: sl<LmtRepository>()),
    );
  }

  //! Core
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  }

  //! External
  if (!sl.isRegistered<InternetConnectionChecker>()) {
    sl.registerLazySingleton(
      () => InternetConnectionChecker.createInstance(),
    );
  }

  if (!sl.isRegistered<Dio>()) {
    sl.registerLazySingleton(() {
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      dio.interceptors.add(
        AuthInterceptor(getToken: AppPreferences.getAccessToken),
      );
      dio.interceptors.add(ApiInterceptor());

      if (AppConfig.enableLogging) {
        dio.interceptors.add(
          PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseHeader: true,
          ),
        );
      }

      return dio;
    });
  }
}
