import 'package:flutter/material.dart';
import 'package:flutter_sdui/core/error/result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action_result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_navigation.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_validator_runner.dart';
import 'package:flutter_sdui/core/sdui/presentation/navigation/sdui_navigator.dart';

typedef SubmitAction = Future<Result<SduiActionResult>> Function({
  required String actionId,
  required String formId,
  required Map<String, dynamic> values,
});

class SduiActionRunner {
  SduiActionRunner({
    required this.controller,
    required this.screen,
    required this.onChanged,
    required this.submit,
    this.resend,
  });

  final SduiController controller;
  SduiScreen screen;
  final VoidCallback onChanged;
  final SubmitAction submit;
  final SubmitAction? resend;
  final _validators = SduiValidatorRunner();

  Future<void> dispatch(BuildContext context, SduiAction action) async {
    switch (action.type) {
      case 'submit_form':
        await _submit(context, action);
      case 'resend_otp':
        await _resend(context, action);
      case 'navigate':
        await SduiNavigator.open(
          context,
          SduiNavigationLike(action),
        );
      case 'pop':
        Navigator.of(context).maybePop();
      case 'set_state':
        final patch = action.payload['patch'];
        if (patch is Map) {
          controller.patchState(Map<String, dynamic>.from(patch));
          onChanged();
        }
    }
  }

  Future<void> _submit(BuildContext context, SduiAction action) async {
    final formId = action.formId ?? screen.forms.keys.first;
    final errors = _validators.validateForm(screen, formId, controller);
    if (errors.isNotEmpty) {
      controller.errors
        ..clear()
        ..addAll(errors);
      onChanged();
      return;
    }
    controller.submitting = true;
    controller.clearErrors();
    onChanged();
    final result = await submit(
      actionId: action.actionId ?? '',
      formId: formId,
      values: controller.valuesForForm(screen, formId),
    );
    controller.submitting = false;
    if (!context.mounted) return;
    await result.fold((failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      onChanged();
    }, (value) => _applyResult(context, value, action));
  }

  Future<void> _resend(BuildContext context, SduiAction action) async {
    if (resend == null) return;
    final result = await resend!(
      actionId: action.actionId ?? 'resend_otp',
      formId: 'otp_form',
      values: const {},
    );
    await result.fold((failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }, (value) async {
      if (!context.mounted) return;
      await _applyResult(context, value, action);
      if (action.thenAction != null && context.mounted) {
        await dispatch(context, action.thenAction!);
      }
    });
  }

  Future<void> _applyResult(
    BuildContext context,
    SduiActionResult result,
    SduiAction action,
  ) async {
    if (result.fieldErrors.isNotEmpty) {
      controller.errors
        ..clear()
        ..addAll(result.fieldErrors);
      onChanged();
      return;
    }
    if (result.statePatch.isNotEmpty) {
      controller.patchState(result.statePatch);
    }
    onChanged();
    if (result.navigation != null && context.mounted) {
      await SduiNavigator.open(context, result.navigation!);
    }
  }
}

class SduiNavigationLike extends SduiNavigation {
  SduiNavigationLike(SduiAction action)
      : super(
          type: 'push',
          screenId: action.screenId,
          route: action.payload['route'] as String?,
          params: Map<String, dynamic>.from(action.payload['params'] as Map? ?? {}),
        );
}
