import 'package:flutter_sdui/core/sdui/domain/repositories/connectivity_repository.dart';

class CheckConnectivity {
  CheckConnectivity(this._repository);
  final ConnectivityRepository _repository;

  Future<bool> call() => _repository.isOnline();
}
