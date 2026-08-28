import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sdui/core/di/injection.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/otp_route_args.dart';
import 'package:flutter_sdui/core/sdui/presentation/widgets/sdui_host.dart';
import 'package:flutter_sdui/features/otp/presentation/cubit/otp_cubit.dart';
import 'package:flutter_sdui/features/otp/presentation/cubit/otp_state.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key, required this.args});

  final OtpRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OtpCubit>(param1: args)..started(),
      child: const _OtpView(),
    );
  }
}

class _OtpView extends StatelessWidget {
  const _OtpView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      builder: (context, state) {
        final cubit = context.read<OtpCubit>();
        return SduiHost(
          isLoading: state is OtpLoading || state is OtpInitial,
          failure: state is OtpError ? state.failure : null,
          screen: state is OtpReady ? state.screen : null,
          controller: cubit.controller,
          runner: cubit.runner,
          isOffline: state is OtpReady && state.isOffline,
          fromCache: state is OtpReady && state.fromCache,
          onRetry: cubit.started,
        );
      },
    );
  }
}
