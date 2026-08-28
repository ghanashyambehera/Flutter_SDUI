import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';

sealed class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginReady extends LoginState {
  LoginReady({
    required this.screen,
    required this.isOffline,
    required this.fromCache,
    required this.revision,
  });

  final SduiScreen screen;
  final bool isOffline;
  final bool fromCache;
  final int revision;

  LoginReady copy({
    bool? isOffline,
    bool? fromCache,
    int? revision,
  }) {
    return LoginReady(
      screen: screen,
      isOffline: isOffline ?? this.isOffline,
      fromCache: fromCache ?? this.fromCache,
      revision: revision ?? this.revision,
    );
  }
}

class LoginError extends LoginState {
  LoginError(this.failure);
  final Failure failure;
}
