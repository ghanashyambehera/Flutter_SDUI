import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';
import 'package:flutter_sdui/core/connectivity/network_info.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internet = internetConnection ?? InternetConnection();

  final Connectivity _connectivity;
  final InternetConnection _internet;

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasInterface) return false;
    if (AppConfig.useLocalSduiMock) return true;
    return _internet.hasInternetAccess;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
