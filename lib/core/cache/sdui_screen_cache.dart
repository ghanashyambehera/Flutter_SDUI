import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SduiScreenCache {
  SduiScreenCache(this._prefs);

  final SharedPreferences _prefs;

  String _key(String screenId, String locale, String appVersion) =>
      'sdui:$screenId:$locale:$appVersion';

  String _etagKey(String cacheKey) => '$cacheKey:etag';

  Future<void> save({
    required String screenId,
    required String locale,
    required String appVersion,
    required Map<String, dynamic> json,
    String? etag,
  }) async {
    final key = _key(screenId, locale, appVersion);
    await _prefs.setString(key, jsonEncode(json));
    if (etag != null) {
      await _prefs.setString(_etagKey(key), etag);
    }
  }

  Map<String, dynamic>? read({
    required String screenId,
    required String locale,
    required String appVersion,
  }) {
    final raw = _prefs.getString(_key(screenId, locale, appVersion));
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  String? readEtag({
    required String screenId,
    required String locale,
    required String appVersion,
  }) {
    return _prefs.getString(_etagKey(_key(screenId, locale, appVersion)));
  }
}
