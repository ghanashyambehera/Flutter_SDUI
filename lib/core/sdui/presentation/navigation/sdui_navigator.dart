import 'package:flutter/material.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/otp_route_args.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_navigation.dart';

class SduiNavigator {
  static const allowlist = {
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.otp,
    AppRoutes.home,
  };

  static String? routeFor({String? route, String? screenId}) {
    final candidate = route ?? screenId;
    if (candidate == null) return null;
    final mapped = candidate.startsWith('/') ? candidate : '/$candidate';
    if (mapped == '/forgot_password') return null;
    return allowlist.contains(mapped) ? mapped : null;
  }

  static Future<void> open(
    BuildContext context,
    SduiNavigation navigation,
  ) async {
    final path = routeFor(route: navigation.route, screenId: navigation.screenId);
    if (path == null) return;
    if (path == AppRoutes.login && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (navigation.type == 'replace_all') {
      await Navigator.of(context).pushNamedAndRemoveUntil(path, (_) => false);
      return;
    }
    if (navigation.type == 'replace') {
      await Navigator.of(context).pushReplacementNamed(
        path,
        arguments: _args(path, navigation.params),
      );
      return;
    }
    await Navigator.of(context).pushNamed(
      path,
      arguments: _args(path, navigation.params),
    );
  }

  static Object? _args(String path, Map<String, dynamic> params) {
    if (path == AppRoutes.otp) {
      return OtpRouteArgs(
        destination: '${params['destination'] ?? ''}',
        flow: '${params['flow'] ?? 'signup'}',
      );
    }
    return params;
  }
}
