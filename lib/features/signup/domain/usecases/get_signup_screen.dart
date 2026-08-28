import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/error/result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/check_connectivity.dart';
import 'package:flutter_sdui/features/signup/domain/repositories/signup_repository.dart';

class GetSignupScreen {
  GetSignupScreen(this._repository, this._checkConnectivity);

  final SignupRepository _repository;
  final CheckConnectivity _checkConnectivity;

  Future<Result<GetScreenOutcome>> call() async {
    final online = await _checkConnectivity();
    if (!online) {
      final cached = _repository.readCache();
      if (cached == null) return const Err(CacheMissFailure());
      return Ok(
        GetScreenOutcome(screen: cached, fromCache: true, isOffline: true),
      );
    }
    final remote = await _repository.fetchRemote();
    return remote.fold(
      (failure) {
        final cached = _repository.readCache();
        if (cached != null) {
          return Ok(
            GetScreenOutcome(screen: cached, fromCache: true, isOffline: false),
          );
        }
        return Err(failure);
      },
      (screen) => Ok(
        GetScreenOutcome(screen: screen, fromCache: false, isOffline: false),
      ),
    );
  }
}
