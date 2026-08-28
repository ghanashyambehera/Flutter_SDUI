class SduiValidator {
  const SduiValidator({
    required this.type,
    required this.message,
    this.args = const {},
  });

  final String type;
  final String message;
  final Map<String, dynamic> args;
}
