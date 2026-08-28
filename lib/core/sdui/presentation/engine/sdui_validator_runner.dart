import 'package:flutter_sdui/core/sdui/domain/entities/sdui_node.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_validator.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';

class SduiValidatorRunner {
  String? validateField({
    required SduiValidator validator,
    required dynamic value,
    required SduiController controller,
  }) {
    switch (validator.type) {
      case 'required':
        if (value == null || '$value'.trim().isEmpty) {
          return validator.message;
        }
      case 'requiredTrue':
        if (value != true) return validator.message;
      case 'email':
        final text = '$value';
        if (text.isEmpty) return null;
        final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(text);
        if (!ok) return validator.message;
      case 'minLength':
        final min = validator.args['value'] as int? ?? 0;
        if ('$value'.length < min) return validator.message;
      case 'maxLength':
        final max = validator.args['value'] as int? ?? 0;
        if ('$value'.length > max) return validator.message;
      case 'matchField':
        final other = validator.args['field'] as String? ?? '';
        if ('$value' != '${controller.value(other) ?? ''}') {
          return validator.message;
        }
      case 'otpLength':
        final len = validator.args['value'] as int? ?? 6;
        if ('$value'.length != len) return validator.message;
    }
    return null;
  }

  Map<String, String> validateForm(SduiScreen screen, String formId, SduiController controller) {
    final errors = <String, String>{};
    _walk(screen.root, formId, controller, errors);
    return errors;
  }

  void _walk(
    SduiNode node,
    String formId,
    SduiController controller,
    Map<String, String> errors,
  ) {
    if (node.bind != null && node.validators.isNotEmpty) {
      for (final v in node.validators) {
        final message = validateField(
          validator: v,
          value: controller.value(node.bind!),
          controller: controller,
        );
        if (message != null) {
          errors[node.bind!] = message;
          break;
        }
      }
    }
    for (final child in node.children) {
      _walk(child, formId, controller, errors);
    }
  }
}
