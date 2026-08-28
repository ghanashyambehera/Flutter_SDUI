import 'package:flutter_sdui/core/constants/sdui_schema.dart';
import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action_result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_navigation.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_node.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_validator.dart';

class SduiScreenParser {
  SduiScreen parseScreen(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int? ?? 0;
    if (version < SduiSchema.min || version > SduiSchema.max) {
      throw const UnsupportedSchemaFailure();
    }
    final root = json['root'];
    if (root is! Map) {
      throw const ParseFailure('Missing root');
    }
    return SduiScreen(
      schemaVersion: version,
      screenId: json['screenId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      safeArea: json['safeArea'] as bool? ?? true,
      theme: Map<String, dynamic>.from(json['theme'] as Map? ?? {}),
      root: parseNode(Map<String, dynamic>.from(root)),
      forms: _parseForms(json['forms']),
      params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
      initialState:
          Map<String, dynamic>.from(json['initialState'] as Map? ?? {}),
    );
  }

  Map<String, SduiFormSpec> _parseForms(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((key, value) {
      final fields = value is Map && value['fields'] is List
          ? (value['fields'] as List).map((e) => '$e').toList()
          : <String>[];
      return MapEntry('$key', SduiFormSpec(formId: '$key', fields: fields));
    });
  }

  SduiNode parseNode(Map<String, dynamic> json) {
    final childrenRaw = json['children'];
    final children = <SduiNode>[];
    if (childrenRaw is List) {
      for (final child in childrenRaw) {
        if (child is Map) {
          children.add(parseNode(Map<String, dynamic>.from(child)));
        }
      }
    }

    final actionsRaw = json['actions'];
    final actions = <String, SduiAction>{};
    if (actionsRaw is Map) {
      for (final entry in actionsRaw.entries) {
        if (entry.value is Map) {
          actions['${entry.key}'] =
              SduiAction.fromJson(Map<String, dynamic>.from(entry.value as Map));
        }
      }
    }

    final validatorsRaw = json['validators'];
    final validators = <SduiValidator>[];
    if (validatorsRaw is List) {
      for (final v in validatorsRaw) {
        if (v is Map) {
          final map = Map<String, dynamic>.from(v);
          validators.add(
            SduiValidator(
              type: map['type'] as String? ?? '',
              message: map['message'] as String? ?? '',
              args: map,
            ),
          );
        }
      }
    }

    Map<String, dynamic>? visibleWhen;
    final vw = json['visibleWhen'];
    if (vw is Map) {
      visibleWhen = Map<String, dynamic>.from(vw);
    }

    return SduiNode(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      props: Map<String, dynamic>.from(json['props'] as Map? ?? {}),
      children: children,
      actions: actions,
      bind: json['bind'] as String?,
      validators: validators,
      visibleWhen: visibleWhen,
      flex: json['flex'] as int?,
    );
  }

  SduiActionResult parseActionResult(
    Map<String, dynamic> json, {
    SduiScreen? parsedNext,
  }) {
    final errorsRaw = json['fieldErrors'];
    final fieldErrors = <String, String>{};
    if (errorsRaw is Map) {
      errorsRaw.forEach((key, value) {
        fieldErrors['$key'] = '$value';
      });
    }

    SduiNavigation? navigation;
    final nav = json['navigation'];
    if (nav is Map) {
      navigation = SduiNavigation.fromJson(Map<String, dynamic>.from(nav));
    }

    SduiScreen? next = parsedNext;
    final nextRaw = json['next'];
    if (next == null && nextRaw is Map) {
      next = parseScreen(Map<String, dynamic>.from(nextRaw));
    }

    return SduiActionResult(
      status: json['status'] as String? ?? 'ok',
      fieldErrors: fieldErrors,
      nextScreen: next,
      navigation: navigation,
      statePatch: Map<String, dynamic>.from(json['statePatch'] as Map? ?? {}),
    );
  }
}
