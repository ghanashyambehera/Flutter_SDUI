import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/watch_connectivity.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_action_runner.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';
import 'package:flutter_sdui/features/signup/domain/usecases/get_signup_screen.dart';
import 'package:flutter_sdui/features/signup/domain/usecases/submit_signup.dart';
import 'package:flutter_sdui/features/signup/presentation/cubit/signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit({
    required GetSignupScreen getSignupScreen,
    required SubmitSignup submitSignup,
    required WatchConnectivity watchConnectivity,
  })  : _getSignupScreen = getSignupScreen,
        _submitSignup = submitSignup,
        _watchConnectivity = watchConnectivity,
        super(SignupInitial());

  final GetSignupScreen _getSignupScreen;
  final SubmitSignup _submitSignup;
  final WatchConnectivity _watchConnectivity;

  SduiController? controller;
  SduiActionRunner? runner;
  StreamSubscription<bool>? _connectivitySub;
  var _revision = 0;

  Future<void> started() async {
    emit(SignupLoading());
    _connectivitySub ??= _watchConnectivity().listen(_onConnectivity);
    final result = await _getSignupScreen();
    result.fold((f) => emit(SignupError(f)), (outcome) {
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
            _submitSignup(formId: formId, values: values),
      );
      emit(
        SignupReady(
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
    if (current is SignupReady) {
      emit(current.copy(revision: ++_revision));
    }
  }

  void _onConnectivity(bool online) {
    final current = state;
    if (current is! SignupReady) return;
    emit(current.copy(isOffline: !online));
    if (online && current.fromCache) started();
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    controller?.dispose();
    return super.close();
  }
}
