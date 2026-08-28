import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isOnline;
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}
