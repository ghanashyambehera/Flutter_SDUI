import 'dart:async';

import 'package:flutter_sdui/core/connectivity/network_info.dart';
import 'package:flutter_sdui/core/sdui/domain/repositories/connectivity_repository.dart';

class ConnectivityRepositoryImpl implements ConnectivityRepository {
  ConnectivityRepositoryImpl(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  Future<bool> isOnline() => _networkInfo.isOnline;

  @override
  Stream<bool> onStatusChange() async* {
    yield await _networkInfo.isOnline;
    await for (final _ in _networkInfo.onConnectivityChanged) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      yield await _networkInfo.isOnline;
    }
  }
}
