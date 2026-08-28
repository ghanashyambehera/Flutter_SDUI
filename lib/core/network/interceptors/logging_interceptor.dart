import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  static const _secrets = {'password', 'confirmPassword', 'otp'};

  dynamic _redact(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        final k = key.toString();
        if (_secrets.contains(k)) return MapEntry(key, '***');
        if (k == 'values' && value is Map) {
          return MapEntry(key, _redact(value));
        }
        return MapEntry(key, _redact(value));
      });
    }
    return data;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[Dio] ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('[Dio] body ${_redact(options.data)}');
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[Dio] error ${err.type} ${err.message}');
    }
    handler.next(err);
  }
}
