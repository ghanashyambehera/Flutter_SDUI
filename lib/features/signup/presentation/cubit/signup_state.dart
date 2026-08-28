import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';

sealed class SignupState {}

class SignupInitial extends SignupState {}

class SignupLoading extends SignupState {}

class SignupReady extends SignupState {
  SignupReady({
    required this.screen,
    required this.isOffline,
    required this.fromCache,
    required this.revision,
  });

  final SduiScreen screen;
  final bool isOffline;
  final bool fromCache;
  final int revision;

  SignupReady copy({bool? isOffline, bool? fromCache, int? revision}) {
    return SignupReady(
      screen: screen,
      isOffline: isOffline ?? this.isOffline,
      fromCache: fromCache ?? this.fromCache,
      revision: revision ?? this.revision,
    );
  }
}

class SignupError extends SignupState {
  SignupError(this.failure);
  final Failure failure;
}
