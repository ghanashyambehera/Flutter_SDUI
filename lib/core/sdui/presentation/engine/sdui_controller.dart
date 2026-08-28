import 'package:flutter/material.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';

class SduiController {
  SduiController();

  final Map<String, dynamic> values = {};
  final Map<String, String> errors = {};
  final Map<String, dynamic> extraState = {};
  final Map<String, TextEditingController> textControllers = {};
  bool submitting = false;

  void applyScreen(SduiScreen screen, {Map<String, dynamic>? routeParams}) {
    extraState
      ..clear()
      ..addAll(screen.initialState)
      ..addAll(screen.params)
      ..addAll(routeParams ?? {});
    for (final spec in screen.forms.values) {
      for (final field in spec.fields) {
        values.putIfAbsent(field, () => field == 'termsAccepted' ? false : '');
      }
    }
  }

  dynamic value(String bind) {
    if (values.containsKey(bind)) return values[bind];
    return extraState[bind];
  }

  void setValue(String bind, dynamic value) {
    values[bind] = value;
    errors.remove(bind);
  }

  void setFieldError(String bind, String message) {
    errors[bind] = message;
  }

  void clearErrors() => errors.clear();

  Map<String, dynamic> valuesForForm(SduiScreen screen, String formId) {
    final spec = screen.forms[formId];
    if (spec == null) return Map<String, dynamic>.from(values);
    final out = <String, dynamic>{};
    for (final field in spec.fields) {
      out[field] = values[field];
    }
    return out;
  }

  void patchState(Map<String, dynamic> patch) {
    extraState.addAll(patch);
  }

  TextEditingController textController(String bind) {
    return textControllers.putIfAbsent(
      bind,
      () => TextEditingController(text: '${values[bind] ?? ''}'),
    );
  }

  void dispose() {
    for (final c in textControllers.values) {
      c.dispose();
    }
    textControllers.clear();
  }
}
