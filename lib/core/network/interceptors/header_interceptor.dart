import 'package:dio/dio.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';

class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      'Accept': 'application/json',
      'X-App-Version': AppConfig.appVersion,
      'X-Schema-Max': '${AppConfig.schemaMax}',
    });
    handler.next(options);
  }
}
