import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';

class SduiConditionEvaluator {
  bool eval(Map<String, dynamic>? condition, SduiController controller) {
    if (condition == null) return true;
    if (condition.containsKey('all') && condition['all'] is List) {
      return (condition['all'] as List).every((item) {
        if (item is Map) {
          return eval(Map<String, dynamic>.from(item), controller);
        }
        return true;
      });
    }
    final field = condition['field'] as String? ?? '';
    final op = condition['op'] as String? ?? 'eq';
    final expected = condition['value'];
    final actual = controller.value(field);

    switch (op) {
      case 'eq':
        return _equals(actual, expected);
      case 'neq':
        return !_equals(actual, expected);
      case 'gt':
        return _num(actual) > _num(expected);
      case 'empty':
        return actual == null || '$actual'.isEmpty;
      case 'notEmpty':
        return actual != null && '$actual'.isNotEmpty;
      case 'hasError':
        return controller.errors.containsKey(field);
      default:
        return true;
    }
  }

  bool _equals(dynamic a, dynamic b) {
    if (a is num && b is num) return a == b;
    return '$a' == '$b';
  }

  num _num(dynamic v) {
    if (v is num) return v;
    return num.tryParse('$v') ?? 0;
  }
}
