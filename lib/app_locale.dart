import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocale {
  static const _keyLocale = 'appLocale';

  static final ValueNotifier<Locale> locale =
      ValueNotifier<Locale>(const Locale('en'));

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyLocale);
    if (code == 'ur') {
      locale.value = const Locale('ur');
    } else {
      locale.value = const Locale('en');
    }
  }

  static Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, newLocale.languageCode);
  }

  static bool isUrdu() => locale.value.languageCode == 'ur';
}
