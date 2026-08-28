import 'package:dio/dio.dart';
import 'package:flutter_sdui/core/cache/sdui_screen_cache.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';
import 'package:flutter_sdui/core/connectivity/network_info.dart';
import 'package:flutter_sdui/core/network/interceptors/connectivity_interceptor.dart';
import 'package:flutter_sdui/core/network/interceptors/etag_interceptor.dart';
import 'package:flutter_sdui/core/network/interceptors/header_interceptor.dart';
import 'package:flutter_sdui/core/network/interceptors/local_sdui_interceptor.dart';
import 'package:flutter_sdui/core/network/interceptors/logging_interceptor.dart';

Dio createDio({
  required NetworkInfo networkInfo,
  required SduiScreenCache cache,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    ConnectivityInterceptor(networkInfo),
    HeaderInterceptor(),
    EtagInterceptor(cache),
    if (AppConfig.useLocalSduiMock) LocalSduiInterceptor(),
    LoggingInterceptor(),
  ]);

  return dio;
}
