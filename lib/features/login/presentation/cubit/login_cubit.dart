import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/watch_connectivity.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_action_runner.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';
import 'package:flutter_sdui/features/login/domain/usecases/get_login_screen.dart';
import 'package:flutter_sdui/features/login/domain/usecases/submit_login.dart';
import 'package:flutter_sdui/features/login/presentation/cubit/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required GetLoginScreen getLoginScreen,
    required SubmitLogin submitLogin,
    required WatchConnectivity watchConnectivity,
  })  : _getLoginScreen = getLoginScreen,
        _submitLogin = submitLogin,
        _watchConnectivity = watchConnectivity,
        super(LoginInitial());

  final GetLoginScreen _getLoginScreen;
  final SubmitLogin _submitLogin;
  final WatchConnectivity _watchConnectivity;

  SduiController? controller;
  SduiActionRunner? runner;
  StreamSubscription<bool>? _connectivitySub;
  var _revision = 0;

  Future<void> started() async {
    emit(LoginLoading());
    _connectivitySub ??= _watchConnectivity().listen(_onConnectivity);
    final result = await _getLoginScreen();
    result.fold((f) => emit(LoginError(f)), (outcome) {
      controller?.dispose();
      controller = SduiController()..applyScreen(outcome.screen);
      runner = SduiActionRunner(
        controller: controller!,
        screen: outcome.screen,
        onChanged: refresh,
        submit: ({
          required actionId,
          required formId,
          required values,
        }) =>
            _submitLogin(formId: formId, values: values),
      );
      emit(
        LoginReady(
          screen: outcome.screen,
          isOffline: outcome.isOffline,
          fromCache: outcome.fromCache,
          revision: ++_revision,
        ),
      );
    });
  }

  void refresh() {
    final current = state;
    if (current is LoginReady) {
      emit(current.copy(revision: ++_revision));
    }
  }

  void _onConnectivity(bool online) {
    final current = state;
    if (current is! LoginReady) return;
    emit(current.copy(isOffline: !online));
    if (online && current.fromCache) {
      started();
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    controller?.dispose();
    return super.close();
  }
}
