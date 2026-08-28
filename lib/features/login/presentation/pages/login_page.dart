import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sdui/core/di/injection.dart';
import 'package:flutter_sdui/core/sdui/presentation/widgets/sdui_host.dart';
import 'package:flutter_sdui/features/login/presentation/cubit/login_cubit.dart';
import 'package:flutter_sdui/features/login/presentation/cubit/login_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>()..started(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return SduiHost(
          isLoading: state is LoginLoading || state is LoginInitial,
          failure: state is LoginError ? state.failure : null,
          screen: state is LoginReady ? state.screen : null,
          controller: cubit.controller,
          runner: cubit.runner,
          isOffline: state is LoginReady && state.isOffline,
          fromCache: state is LoginReady && state.fromCache,
          onRetry: cubit.started,
        );
      },
    );
  }
}
