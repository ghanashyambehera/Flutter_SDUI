import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';

sealed class OtpState {}

class OtpInitial extends OtpState {}

class OtpLoading extends OtpState {}

class OtpReady extends OtpState {
  OtpReady({
    required this.screen,
    required this.isOffline,
    required this.fromCache,
    required this.revision,
  });

  final SduiScreen screen;
  final bool isOffline;
  final bool fromCache;
  final int revision;

  OtpReady copy({bool? isOffline, bool? fromCache, int? revision}) {
    return OtpReady(
      screen: screen,
      isOffline: isOffline ?? this.isOffline,
      fromCache: fromCache ?? this.fromCache,
      revision: revision ?? this.revision,
    );
  }
}

class OtpError extends OtpState {
  OtpError(this.failure);
  final Failure failure;
}
