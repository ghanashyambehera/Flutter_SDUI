import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';

class SduiStringResolver {
  static final _pattern = RegExp(r'\{\{([^}]+)\}\}');

  String resolve(String template, SduiController controller) {
    return template.replaceAllMapped(_pattern, (match) {
      final key = match.group(1)?.trim() ?? '';
      if (key.startsWith('fieldError.')) {
        final bind = key.substring('fieldError.'.length);
        return controller.errors[bind] ?? '';
      }
      return '${controller.value(key) ?? ''}';
    });
  }
}
