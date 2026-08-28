import 'package:flutter_sdui/core/error/result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action_result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';

abstract class OtpRepository {
  Future<Result<SduiScreen>> fetchRemote();
  SduiScreen? readCache();
  Future<void> writeCache(Map<String, dynamic> json);
  Future<Result<SduiActionResult>> submit({
    required String formId,
    required Map<String, dynamic> values,
  });
  Future<Result<SduiActionResult>> resend();
}
