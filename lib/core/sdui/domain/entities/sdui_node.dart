import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_validator.dart';

class SduiNode {
  const SduiNode({
    required this.id,
    required this.type,
    this.props = const {},
    this.children = const [],
    this.actions = const {},
    this.bind,
    this.validators = const [],
    this.visibleWhen,
    this.flex,
  });

  final String id;
  final String type;
  final Map<String, dynamic> props;
  final List<SduiNode> children;
  final Map<String, SduiAction> actions;
  final String? bind;
  final List<SduiValidator> validators;
  final Map<String, dynamic>? visibleWhen;
  final int? flex;
}
