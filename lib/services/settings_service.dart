import 'package:shared_preferences/shared_preferences.dart';

/// Simple service for persisting user settings (locale, theme, etc.)
class SettingsService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Locale ──────────────────────────────────────────────

  /// 'system' | 'en' | 'zh'  — defaults to system
  static String get locale => _prefs.getString('locale') ?? 'system';
  static set locale(String v) => _prefs.setString('locale', v);

  // ── Theme ───────────────────────────────────────────────

  /// 'system' | 'light' | 'dark'  — defaults to system
  static String get themeMode => _prefs.getString('themeMode') ?? 'system';
  static set themeMode(String v) => _prefs.setString('themeMode', v);

  // ── Send Message Shortcut ───────────────────────────────

  /// 'enter' | 'ctrlEnter'  — defaults to enter
  static String get sendShortcut => _prefs.getString('sendShortcut') ?? 'enter';
  static set sendShortcut(String v) => _prefs.setString('sendShortcut', v);

  // ── Progressive Disclosure ──────────────────────────────

  /// Whether the user has created at least one project (or dismissed the intro).
  static bool get hasSeenProjectIntro =>
      _prefs.getBool('hasSeenProjectIntro') ?? false;
  static set hasSeenProjectIntro(bool v) =>
      _prefs.setBool('hasSeenProjectIntro', v);
}
