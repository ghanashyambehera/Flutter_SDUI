sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NoConnectivityFailure extends Failure {
  const NoConnectivityFailure([super.message = 'No internet connection']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request timed out']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class ClientFailure extends Failure {
  const ClientFailure([super.message = 'Request failed']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Invalid screen JSON']);
}

class UnsupportedSchemaFailure extends Failure {
  const UnsupportedSchemaFailure([super.message = 'Please update the app']);
}

class CacheMissFailure extends Failure {
  const CacheMissFailure([super.message = 'Screen is not available offline']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
