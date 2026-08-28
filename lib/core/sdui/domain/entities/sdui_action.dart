class SduiAction {
  const SduiAction({
    required this.type,
    this.actionId,
    this.formId,
    this.screenId,
    this.payload = const {},
    this.thenAction,
  });

  final String type;
  final String? actionId;
  final String? formId;
  final String? screenId;
  final Map<String, dynamic> payload;
  final SduiAction? thenAction;

  factory SduiAction.fromJson(Map<String, dynamic> json) {
    final then = json['then'];
    return SduiAction(
      type: json['type'] as String? ?? '',
      actionId: json['actionId'] as String?,
      formId: json['formId'] as String?,
      screenId: json['screenId'] as String?,
      payload: json,
      thenAction: then is Map<String, dynamic> ? SduiAction.fromJson(then) : null,
    );
  }
}
