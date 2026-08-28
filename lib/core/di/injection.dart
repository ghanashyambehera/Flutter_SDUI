import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sdui/core/cache/sdui_screen_cache.dart';
import 'package:flutter_sdui/core/connectivity/connectivity_repository_impl.dart';
import 'package:flutter_sdui/core/connectivity/network_info.dart';
import 'package:flutter_sdui/core/connectivity/network_info_impl.dart';
import 'package:flutter_sdui/core/network/dio_client.dart';
import 'package:flutter_sdui/core/sdui/data/parsers/sdui_screen_parser.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/otp_route_args.dart';
import 'package:flutter_sdui/core/sdui/domain/repositories/connectivity_repository.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/check_connectivity.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/watch_connectivity.dart';
import 'package:flutter_sdui/features/login/data/datasources/login_remote_data_source.dart';
import 'package:flutter_sdui/features/login/data/repositories/login_repository_impl.dart';
import 'package:flutter_sdui/features/login/domain/repositories/login_repository.dart';
import 'package:flutter_sdui/features/login/domain/usecases/get_login_screen.dart';
import 'package:flutter_sdui/features/login/domain/usecases/submit_login.dart';
import 'package:flutter_sdui/features/login/presentation/cubit/login_cubit.dart';
import 'package:flutter_sdui/features/otp/data/datasources/otp_remote_data_source.dart';
import 'package:flutter_sdui/features/otp/data/repositories/otp_repository_impl.dart';
import 'package:flutter_sdui/features/otp/domain/repositories/otp_repository.dart';
import 'package:flutter_sdui/features/otp/domain/usecases/get_otp_screen.dart';
import 'package:flutter_sdui/features/otp/domain/usecases/otp_actions.dart';
import 'package:flutter_sdui/features/otp/presentation/cubit/otp_cubit.dart';
import 'package:flutter_sdui/features/signup/data/datasources/signup_remote_data_source.dart';
import 'package:flutter_sdui/features/signup/data/repositories/signup_repository_impl.dart';
import 'package:flutter_sdui/features/signup/domain/repositories/signup_repository.dart';
import 'package:flutter_sdui/features/signup/domain/usecases/get_signup_screen.dart';
import 'package:flutter_sdui/features/signup/domain/usecases/submit_signup.dart';
import 'package:flutter_sdui/features/signup/presentation/cubit/signup_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<Dio>()) return;

  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => SduiScreenCache(prefs));
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  }
  sl.registerLazySingleton<ConnectivityRepository>(
    () => ConnectivityRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => CheckConnectivity(sl()));
  sl.registerLazySingleton(() => WatchConnectivity(sl()));
  sl.registerLazySingleton(SduiScreenParser.new);
  sl.registerLazySingleton<Dio>(
    () => createDio(networkInfo: sl(), cache: sl()),
  );

  sl.registerLazySingleton(() => LoginRemoteDataSource(sl()));
  sl.registerLazySingleton<LoginRepository>(
    () => LoginRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => GetLoginScreen(sl(), sl()));
  sl.registerLazySingleton(() => SubmitLogin(sl(), sl()));
  sl.registerFactory(
    () => LoginCubit(
      getLoginScreen: sl(),
      submitLogin: sl(),
      watchConnectivity: sl(),
    ),
  );

  sl.registerLazySingleton(() => SignupRemoteDataSource(sl()));
  sl.registerLazySingleton<SignupRepository>(
    () => SignupRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => GetSignupScreen(sl(), sl()));
  sl.registerLazySingleton(() => SubmitSignup(sl(), sl()));
  sl.registerFactory(
    () => SignupCubit(
      getSignupScreen: sl(),
      submitSignup: sl(),
      watchConnectivity: sl(),
    ),
  );

  sl.registerLazySingleton(() => OtpRemoteDataSource(sl()));
  sl.registerLazySingleton<OtpRepository>(
    () => OtpRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => GetOtpScreen(sl(), sl()));
  sl.registerLazySingleton(() => SubmitOtp(sl(), sl()));
  sl.registerLazySingleton(() => ResendOtp(sl(), sl()));
  sl.registerFactoryParam<OtpCubit, OtpRouteArgs, void>(
    (args, _) => OtpCubit(
      getOtpScreen: sl(),
      submitOtp: sl(),
      resendOtp: sl(),
      watchConnectivity: sl(),
      args: args,
    ),
  );
}
