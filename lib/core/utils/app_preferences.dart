import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class AppPreferences {
  AppPreferences._();

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  // Theme
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await _prefs();
    final value = prefs.getString(AppConstants.themeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _prefs();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(AppConstants.themeKey, value);
  }

  // Locale
  static Future<Locale?> getSavedLocale() async {
    final prefs = await _prefs();
    final code = prefs.getString(AppConstants.languageKey);
    if (code == null) return null;
    return Locale(code);
  }

  static Future<void> setLocale(Locale locale) async {
    final prefs = await _prefs();
    await prefs.setString(AppConstants.languageKey, locale.languageCode);
  }

  // Login
  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs();
    return prefs.getBool(AppConstants.loggedInKey) ?? false;
  }

  static Future<void> saveLogin({
    required String username,
    required String password,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(AppConstants.usernameKey, username);
    await prefs.setString(AppConstants.passwordKey, password);
    await prefs.setBool(AppConstants.loggedInKey, true);
  }

  static Future<void> clearLogin() async {
    final prefs = await _prefs();
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.passwordKey);
    await prefs.setBool(AppConstants.loggedInKey, false);
  }
}

