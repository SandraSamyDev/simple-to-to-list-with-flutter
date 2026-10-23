import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the light/dark choice and remembers it on the device.
class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dark = prefs.getBool('dark_mode') ?? false;
      mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // if reading fails we simply stay on the light theme
    }
  }

  static Future<void> setDark(bool dark) async {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', dark);
    } catch (_) {}
  }
}
