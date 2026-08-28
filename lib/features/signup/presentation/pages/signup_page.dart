import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sdui/core/di/injection.dart';
import 'package:flutter_sdui/core/sdui/presentation/widgets/sdui_host.dart';
import 'package:flutter_sdui/features/signup/presentation/cubit/signup_cubit.dart';
import 'package:flutter_sdui/features/signup/presentation/cubit/signup_state.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignupCubit>()..started(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatelessWidget {
  const _SignupView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupCubit, SignupState>(
      builder: (context, state) {
        final cubit = context.read<SignupCubit>();
        return SduiHost(
          isLoading: state is SignupLoading || state is SignupInitial,
          failure: state is SignupError ? state.failure : null,
          screen: state is SignupReady ? state.screen : null,
          controller: cubit.controller,
          runner: cubit.runner,
          isOffline: state is SignupReady && state.isOffline,
          fromCache: state is SignupReady && state.fromCache,
          onRetry: cubit.started,
        );
      },
    );
  }
}
