import 'package:dio/dio.dart';
import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/network/no_network_exception.dart';

class DioErrorMapper {
  static Failure toFailure(DioException error) {
    if (error.error is NoNetworkException) {
      return const NoConnectivityFailure();
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NoConnectivityFailure();
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 0;
        if (code == 401) return const UnauthorizedFailure();
        if (code >= 500) return const ServerFailure();
        if (code >= 400) return const ClientFailure();
        return const ServerFailure();
      case DioExceptionType.cancel:
        return const UnknownFailure('Request cancelled');
      default:
        return UnknownFailure(error.message ?? 'Unknown error');
    }
  }
}
