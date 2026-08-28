import 'package:flutter_sdui/core/sdui/domain/repositories/connectivity_repository.dart';

class WatchConnectivity {
  WatchConnectivity(this._repository);
  final ConnectivityRepository _repository;

  Stream<bool> call() => _repository.onStatusChange();
}
