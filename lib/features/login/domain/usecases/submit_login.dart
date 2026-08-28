import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/error/result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action_result.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/check_connectivity.dart';
import 'package:flutter_sdui/features/login/domain/repositories/login_repository.dart';

class SubmitLogin {
  SubmitLogin(this._repository, this._checkConnectivity);

  final LoginRepository _repository;
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
