import 'package:dio/dio.dart';
import 'package:flutter_sdui/core/connectivity/network_info.dart';
import 'package:flutter_sdui/core/network/no_network_exception.dart';

class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final online = await _networkInfo.isOnline;
    if (!online) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: const NoNetworkException(),
          message: 'No internet connection',
        ),
      );
      return;
    }
    handler.next(options);
  }
}
