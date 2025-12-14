import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const _keyThemeMode = 'themeMode';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyThemeMode);
    if (stored == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else if (stored == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (stored == 'system') {
      themeMode.value = ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.system:
      // ignore: unreachable_switch_default
      default:
        value = 'system';
        break;
    }
    await prefs.setString(_keyThemeMode, value);
  }
}
