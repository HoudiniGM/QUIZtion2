import 'package:shared_preferences/shared_preferences.dart';

/// Stores simple app settings locally. For now, only the backend base URL.
///
/// Resolution order for the backend URL:
///   1. a value saved by the user in Settings (if any);
///   2. otherwise the compile-time default from --dart-define=BACKEND_URL=...;
///   3. otherwise an empty string (generation disabled until configured).
class SettingsRepository {
  static const _backendUrlKey = 'backend_url';

  /// Compile-time default, e.g.:
  ///   flutter run --dart-define=BACKEND_URL=http://192.168.0.10:3000
  static const String compileTimeDefaultUrl =
      String.fromEnvironment('BACKEND_URL', defaultValue: '');

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static Future<SettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  /// Current effective backend URL (saved value, else compile-time default).
  String get backendUrl {
    final saved = _prefs.getString(_backendUrlKey);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return compileTimeDefaultUrl.trim();
  }

  bool get hasBackendUrl => backendUrl.isNotEmpty;

  Future<void> setBackendUrl(String url) async {
    await _prefs.setString(_backendUrlKey, url.trim());
  }

  Future<void> clearBackendUrl() async {
    await _prefs.remove(_backendUrlKey);
  }
}
