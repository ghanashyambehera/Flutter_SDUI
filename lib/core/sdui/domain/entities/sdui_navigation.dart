class SduiNavigation {
  const SduiNavigation({
    required this.type,
    this.screenId,
    this.route,
    this.params = const {},
  });

  final String type;
  final String? screenId;
  final String? route;
  final Map<String, dynamic> params;

  factory SduiNavigation.fromJson(Map<String, dynamic> json) {
    return SduiNavigation(
      type: json['type'] as String? ?? 'push',
      screenId: json['screenId'] as String?,
      route: json['route'] as String?,
      params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
    );
  }
}
