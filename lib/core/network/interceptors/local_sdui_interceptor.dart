import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';

/// Serves [assets/sdui] JSON and demo action results through Dio (no backend).
class LocalSduiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.uri.path;
    try {
      if (options.method == 'GET' && path.contains(ApiPaths.sduiScreens)) {
        final screenId = path.split('/').last;
        final raw = await rootBundle.loadString('assets/sdui/$screenId.json');
        final json = jsonDecode(raw);
        handler.resolve(
          Response(
            requestOptions: options,
            data: json,
            statusCode: 200,
          ),
        );
        return;
      }

      if (options.method == 'POST' && path.contains(ApiPaths.sduiActions)) {
        final actionId = path.split('/').last;
        final body = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : <String, dynamic>{};
        handler.resolve(
          Response(
            requestOptions: options,
            data: _actionResult(actionId, body),
            statusCode: 200,
          ),
        );
        return;
      }
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          type: DioExceptionType.unknown,
          message: e.toString(),
        ),
      );
      return;
    }
    handler.next(options);
  }

  Map<String, dynamic> _actionResult(
    String actionId,
    Map<String, dynamic> body,
  ) {
    final values = Map<String, dynamic>.from(body['values'] as Map? ?? {});
    switch (actionId) {
      case 'submit_login':
        final password = '${values['password'] ?? ''}';
        if (password == 'wrongpass') {
          return {
            'status': 'field_errors',
            'fieldErrors': {'password': 'Incorrect email or password'},
          };
        }
        return {
          'status': 'navigate',
          'navigation': {
            'type': 'push',
            'route': 'otp',
            'params': {
              'destination': _maskEmail('${values['email'] ?? ''}'),
              'flow': 'login',
            },
          },
        };
      case 'submit_signup':
        return {
          'status': 'navigate',
          'navigation': {
            'type': 'push',
            'route': 'otp',
            'params': {
              'destination': _maskEmail('${values['email'] ?? ''}'),
              'flow': 'signup',
            },
          },
        };
      case 'submit_otp':
        final otp = '${values['otp'] ?? ''}';
        if (otp != AppConfig.demoOtp) {
          return {
            'status': 'field_errors',
            'fieldErrors': {'otp': 'Invalid code. Use ${AppConfig.demoOtp} in this demo.'},
          };
        }
        return {
          'status': 'navigate',
          'navigation': {
            'type': 'replace_all',
            'route': 'home',
          },
        };
      case 'resend_otp':
        return {
          'status': 'ok',
          'statePatch': {'resendSecondsLeft': 30},
        };
      default:
        return {'status': 'ok'};
    }
  }

  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email[0]}***${email.substring(at)}';
  }
}
