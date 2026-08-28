import 'package:flutter_sdui/core/cache/sdui_screen_cache.dart';
import 'package:flutter_sdui/core/constants/api_paths.dart';
import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/error/result.dart';
import 'package:flutter_sdui/core/sdui/data/parsers/sdui_screen_parser.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_action_result.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/features/signup/data/datasources/signup_remote_data_source.dart';
import 'package:flutter_sdui/features/signup/domain/repositories/signup_repository.dart';

class SignupRepositoryImpl implements SignupRepository {
  SignupRepositoryImpl(this._remote, this._cache, this._parser);

  final SignupRemoteDataSource _remote;
  final SduiScreenCache _cache;
  final SduiScreenParser _parser;

  static const _id = 'signup';

  @override
  Future<Result<SduiScreen>> fetchRemote() async {
    try {
      final json = await _remote.fetchScreen();
      final screen = _parser.parseScreen(json);
      await writeCache(json);
      return Ok(screen);
    } on Failure catch (f) {
      return Err(f);
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  SduiScreen? readCache() {
    final json = _cache.read(
      screenId: _id,
      locale: 'en',
      appVersion: AppConfig.appVersion,
    );
    if (json == null) return null;
    try {
      return _parser.parseScreen(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeCache(Map<String, dynamic> json) {
    return _cache.save(
      screenId: _id,
      locale: 'en',
      appVersion: AppConfig.appVersion,
      json: json,
    );
  }

  @override
  Future<Result<SduiActionResult>> submit({
    required String formId,
    required Map<String, dynamic> values,
  }) async {
    try {
      final json = await _remote.submit({
        'screenId': _id,
        'formId': formId,
        'values': values,
        'client': {'appVersion': AppConfig.appVersion, 'platform': 'flutter'},
      });
      return Ok(_parser.parseActionResult(json));
    } on Failure catch (f) {
      return Err(f);
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }
}
