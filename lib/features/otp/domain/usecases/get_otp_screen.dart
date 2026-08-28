import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/error/result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/otp_route_args.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/check_connectivity.dart';
import 'package:flutter_sdui/features/otp/domain/repositories/otp_repository.dart';

class GetOtpScreen {
  GetOtpScreen(this._repository, this._checkConnectivity);

  final OtpRepository _repository;
  final CheckConnectivity _checkConnectivity;

  Future<Result<GetScreenOutcome>> call(OtpRouteArgs args) async {
    final online = await _checkConnectivity();
    if (!online) {
      final cached = _repository.readCache();
      if (cached == null) return const Err(CacheMissFailure());
      return Ok(
        GetScreenOutcome(
          screen: cached.copyWithParams({
            'destination': args.destination,
            'flow': args.flow,
          }),
          fromCache: true,
          isOffline: true,
        ),
      );
    }
    final remote = await _repository.fetchRemote();
    return remote.fold(
      (failure) {
        final cached = _repository.readCache();
        if (cached != null) {
          return Ok(
            GetScreenOutcome(
              screen: cached.copyWithParams({
                'destination': args.destination,
                'flow': args.flow,
              }),
              fromCache: true,
              isOffline: false,
            ),
          );
        }
        return Err(failure);
      },
      (screen) => Ok(
        GetScreenOutcome(
          screen: screen.copyWithParams({
            'destination': args.destination,
            'flow': args.flow,
          }),
          fromCache: false,
          isOffline: false,
        ),
      ),
    );
  }
}
