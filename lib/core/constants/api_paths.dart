class ApiPaths {
  static const sduiScreens = '/sdui/screens';
  static const sduiActions = '/sdui/actions';
}

class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';
  static const otp = '/otp';
  static const home = '/home';
}

class AppConfig {
  /// Serves [assets/sdui] through Dio so the app runs without a backend.
  static const useLocalSduiMock = true;
  static const baseUrl = 'https://sdui.local';
  static const appVersion = '1.0.0';
  static const schemaMax = 1;
  static const schemaMin = 1;
  static const demoOtp = '123456';
}
