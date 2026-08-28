import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/error/result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action_result.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/check_connectivity.dart';
import 'package:flutter_sdui/features/signup/domain/repositories/signup_repository.dart';

class SubmitSignup {
  SubmitSignup(this._repository, this._checkConnectivity);

  final SignupRepository _repository;
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
