import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sdui/app.dart';
import 'package:flutter_sdui/core/connectivity/network_info.dart';
import 'package:flutter_sdui/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OnlineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isOnline async => true;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    sl.registerLazySingleton<NetworkInfo>(_OnlineNetworkInfo.new);
    await configureDependencies();
  });

  testWidgets('login screen renders from SDUI JSON', (tester) async {
    await tester.pumpWidget(const SduiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
