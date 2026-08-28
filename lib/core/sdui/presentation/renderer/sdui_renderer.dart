import 'package:flutter/material.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_action_runner.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';
import 'package:flutter_sdui/core/sdui/presentation/renderer/sdui_widget_factory.dart';

class SduiRenderer {
  SduiRenderer({SduiWidgetFactory? factory})
      : _factory = factory ?? SduiWidgetFactory();

  final SduiWidgetFactory _factory;

  Widget build({
    required BuildContext context,
    required SduiScreen screen,
    required SduiController controller,
    required SduiActionRunner runner,
  }) {
    return _factory.build(
      screen.root,
      SduiBuildContext(
        context: context,
        screen: screen,
        controller: controller,
        runner: runner,
      ),
    );
  }
}
