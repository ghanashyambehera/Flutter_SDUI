class OtpRouteArgs {
  const OtpRouteArgs({
    required this.destination,
    this.flow = 'signup',
  });

  final String destination;
  final String flow;
}
