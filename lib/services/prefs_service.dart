import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  PrefsService._();
  static final instance = PrefsService._();

  static const _keyLastUsername = 'last_username';
  static const _keyDarkMode = 'is_dark_mode';

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_keyDarkMode) ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> simpanUsernameTerakhir(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUsername, username.trim());
  }

  Future<String> ambilUsernameTerakhir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUsername) ?? '';
  }

  Future<void> ubahTema(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;
}