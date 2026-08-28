import 'package:dio/dio.dart';
import 'package:flutter_sdui/core/cache/sdui_screen_cache.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';

class EtagInterceptor extends Interceptor {
  EtagInterceptor(this._cache);

  final SduiScreenCache _cache;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET' &&
        options.path.contains(ApiPaths.sduiScreens)) {
      final screenId = options.path.split('/').last;
      final etag = _cache.readEtag(
        screenId: screenId,
        locale: 'en',
        appVersion: AppConfig.appVersion,
      );
      if (etag != null) {
        options.headers['If-None-Match'] = etag;
      }
    }
    handler.next(options);
  }
}
