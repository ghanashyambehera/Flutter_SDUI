import 'package:flutter/material.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/otp_route_args.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_token_resolver.dart';
import 'package:flutter_sdui/features/home/presentation/pages/home_page.dart';
import 'package:flutter_sdui/features/login/presentation/pages/login_page.dart';
import 'package:flutter_sdui/features/otp/presentation/pages/otp_page.dart';
import 'package:flutter_sdui/features/signup/presentation/pages/signup_page.dart';

class SduiApp extends StatelessWidget {
  const SduiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SDUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: SduiTokenResolver.primary),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case AppRoutes.signup:
            return MaterialPageRoute(builder: (_) => const SignupPage());
          case AppRoutes.otp:
            final args = settings.arguments is OtpRouteArgs
                ? settings.arguments as OtpRouteArgs
                : const OtpRouteArgs(destination: '');
            return MaterialPageRoute(builder: (_) => OtpPage(args: args));
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const HomePage());
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}
