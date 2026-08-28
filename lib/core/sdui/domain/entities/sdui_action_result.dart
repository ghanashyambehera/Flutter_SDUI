import 'package:flutter_sdui/core/sdui/domain/entities/sdui_navigation.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';

class SduiActionResult {
  const SduiActionResult({
    required this.status,
    this.fieldErrors = const {},
    this.nextScreen,
    this.navigation,
    this.statePatch = const {},
  });

  final String status;
  final Map<String, String> fieldErrors;
  final SduiScreen? nextScreen;
  final SduiNavigation? navigation;
  final Map<String, dynamic> statePatch;
}
