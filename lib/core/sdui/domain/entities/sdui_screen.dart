import 'package:flutter_sdui/core/sdui/domain/entities/sdui_node.dart';

class SduiFormSpec {
  const SduiFormSpec({required this.formId, required this.fields});

  final String formId;
  final List<String> fields;
}

class SduiScreen {
  const SduiScreen({
    required this.schemaVersion,
    required this.screenId,
    required this.title,
    required this.root,
    this.safeArea = true,
    this.theme = const {},
    this.forms = const {},
    this.params = const {},
    this.initialState = const {},
  });

  final int schemaVersion;
  final String screenId;
  final String title;
  final bool safeArea;
  final Map<String, dynamic> theme;
  final SduiNode root;
  final Map<String, SduiFormSpec> forms;
  final Map<String, dynamic> params;
  final Map<String, dynamic> initialState;

  SduiScreen copyWithParams(Map<String, dynamic> extra) {
    return SduiScreen(
      schemaVersion: schemaVersion,
      screenId: screenId,
      title: title,
      root: root,
      safeArea: safeArea,
      theme: theme,
      forms: forms,
      params: {...params, ...extra},
      initialState: initialState,
    );
  }
}

class GetScreenOutcome {
  const GetScreenOutcome({
    required this.screen,
    required this.fromCache,
    required this.isOffline,
  });

  final SduiScreen screen;
  final bool fromCache;
  final bool isOffline;
}
