import 'package:shared_preferences/shared_preferences.dart';

/// Simple service for persisting user settings (locale, theme, etc.)
class SettingsService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Locale ──────────────────────────────────────────────

  static String get locale => _prefs.getString('locale') ?? 'en';
  static set locale(String v) => _prefs.setString('locale', v);

  // ── Theme ───────────────────────────────────────────────

  static String get themeMode => _prefs.getString('themeMode') ?? 'light';
  static set themeMode(String v) => _prefs.setString('themeMode', v);
}
