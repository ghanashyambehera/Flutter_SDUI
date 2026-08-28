import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/otp_route_args.dart';
import 'package:flutter_sdui/core/sdui/domain/usecases/watch_connectivity.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_action_runner.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';
import 'package:flutter_sdui/features/otp/domain/usecases/get_otp_screen.dart';
import 'package:flutter_sdui/features/otp/domain/usecases/otp_actions.dart';
import 'package:flutter_sdui/features/otp/presentation/cubit/otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit({
    required GetOtpScreen getOtpScreen,
    required SubmitOtp submitOtp,
    required ResendOtp resendOtp,
    required WatchConnectivity watchConnectivity,
    required this.args,
  })  : _getOtpScreen = getOtpScreen,
        _submitOtp = submitOtp,
        _resendOtp = resendOtp,
        _watchConnectivity = watchConnectivity,
        super(OtpInitial());

  final GetOtpScreen _getOtpScreen;
  final SubmitOtp _submitOtp;
  final ResendOtp _resendOtp;
  final WatchConnectivity _watchConnectivity;
  final OtpRouteArgs args;

  SduiController? controller;
  SduiActionRunner? runner;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _timer;
  var _revision = 0;

  Future<void> started() async {
    emit(OtpLoading());
    _connectivitySub ??= _watchConnectivity().listen(_onConnectivity);
    final result = await _getOtpScreen(args);
    result.fold((f) => emit(OtpError(f)), (outcome) {
      controller?.dispose();
      controller = SduiController()
        ..applyScreen(
          outcome.screen,
          routeParams: {
            'destination': args.destination,
            'flow': args.flow,
          },
        );
      runner = SduiActionRunner(
        controller: controller!,
        screen: outcome.screen,
        onChanged: () {
          _maybeStartTimer();
          refresh();
        },
        submit: ({
          required actionId,
          required formId,
          required values,
        }) =>
            _submitOtp(formId: formId, values: values),
        resend: ({
          required actionId,
          required formId,
          required values,
        }) =>
            _resendOtp(),
      );
      emit(
        OtpReady(
          screen: outcome.screen,
          isOffline: outcome.isOffline,
          fromCache: outcome.fromCache,
          revision: ++_revision,
        ),
      );
      _maybeStartTimer();
    });
  }

  void _maybeStartTimer() {
    _timer?.cancel();
    final seconds = controller?.extraState['resendSecondsLeft'];
    final n = seconds is num ? seconds.toInt() : int.tryParse('$seconds') ?? 0;
    if (n <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = (controller?.extraState['resendSecondsLeft'] as num?)?.toInt() ?? 0;
      if (left <= 1) {
        controller?.extraState['resendSecondsLeft'] = 0;
        timer.cancel();
      } else {
        controller?.extraState['resendSecondsLeft'] = left - 1;
      }
      refresh();
    });
  }

  void refresh() {
    final current = state;
    if (current is OtpReady) {
      emit(current.copy(revision: ++_revision));
    }
  }

  void _onConnectivity(bool online) {
    final current = state;
    if (current is! OtpReady) return;
    emit(current.copy(isOffline: !online));
    if (online && current.fromCache) started();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _connectivitySub?.cancel();
    controller?.dispose();
    return super.close();
  }
}
