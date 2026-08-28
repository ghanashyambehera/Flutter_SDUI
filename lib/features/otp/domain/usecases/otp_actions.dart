import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/error/result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action_result.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/check_connectivity.dart';
import 'package:flutter_sdui/features/otp/domain/repositories/otp_repository.dart';

class SubmitOtp {
  SubmitOtp(this._repository, this._checkConnectivity);

  final OtpRepository _repository;
  final CheckConnectivity _checkConnectivity;

  Future<Result<SduiActionResult>> call({
    required String formId,
    required Map<String, dynamic> values,
  }) async {
    if (!await _checkConnectivity()) {
      return const Err(NoConnectivityFailure());
    }
    return _repository.submit(formId: formId, values: values);
  }
}

class ResendOtp {
  ResendOtp(this._repository, this._checkConnectivity);

  final OtpRepository _repository;
  final CheckConnectivity _checkConnectivity;

  Future<Result<SduiActionResult>> call() async {
    if (!await _checkConnectivity()) {
      return const Err(NoConnectivityFailure());
    }
    return _repository.resend();
  }
}
