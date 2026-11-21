import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// Local Storage & Preferences Manager
/// Caches App Login, Security Tokens, Biometric Flags, Theme, Locale, and Offline Sync Data
class AppPreferences {
  AppPreferences._();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _currentUserIdKey = 'current_user_id';
  static const String _cachedStateKey = 'lmt_cached_state_v1';
  static const String _sloganKey = 'lmt_slogan_of_year';
  static const String _verseKey = 'lmt_verse_of_year';
  static const String _savedStickersKey = 'lmt_saved_stickers_v1';

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
        return ThemeMode.light;
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

  // Login & Security Tokens
  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs();
    return prefs.getBool(AppConstants.loggedInKey) ?? false;
  }

  static Future<void> saveLogin({
    required String username,
    required String password,
    String? userId,
    String? accessToken,
    String? refreshToken,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(AppConstants.usernameKey, username);
    await prefs.setString(AppConstants.passwordKey, password);
    await prefs.setBool(AppConstants.loggedInKey, true);
    if (userId != null) {
      await prefs.setString(_currentUserIdKey, userId);
    }
    if (accessToken != null) {
      await prefs.setString(AppConstants.accessTokenKey, accessToken);
    }
    if (refreshToken != null) {
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
    }
  }

  static Future<String?> getSavedUsername() async {
    final prefs = await _prefs();
    return prefs.getString(AppConstants.usernameKey);
  }

  static Future<String?> getSavedPassword() async {
    final prefs = await _prefs();
    return prefs.getString(AppConstants.passwordKey);
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await _prefs();
    return prefs.getString(_currentUserIdKey);
  }

  static Future<void> setCurrentUserId(String userId) async {
    final prefs = await _prefs();
    await prefs.setString(_currentUserIdKey, userId);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await _prefs();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  static Future<void> clearLogin() async {
    final prefs = await _prefs();
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.passwordKey);
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.setBool(AppConstants.loggedInKey, false);
  }

  // Biometric Authentication (Fingerprint & Face Recognition)
  static Future<bool> isBiometricEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_biometricEnabledKey) ?? true;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  // Year Slogan & Verse
  static Future<String?> getSloganOfYear() async {
    final prefs = await _prefs();
    return prefs.getString(_sloganKey);
  }

  static Future<void> setSloganOfYear(String slogan) async {
    final prefs = await _prefs();
    await prefs.setString(_sloganKey, slogan);
  }

  static Future<String?> getVerseOfYear() async {
    final prefs = await _prefs();
    return prefs.getString(_verseKey);
  }

  static Future<void> setVerseOfYear(String verse) async {
    final prefs = await _prefs();
    await prefs.setString(_verseKey, verse);
  }

  // Offline/Online Cached State JSON
  static Future<String?> getCachedStateJson() async {
    final prefs = await _prefs();
    return prefs.getString(_cachedStateKey);
  }

  static Future<void> setCachedStateJson(String jsonString) async {
    final prefs = await _prefs();
    await prefs.setString(_cachedStateKey, jsonString);
  }

  static Future<void> clearCachedState() async {
    final prefs = await _prefs();
    await prefs.remove(_cachedStateKey);
  }

  // Saved WhatsApp-style Stickers
  static Future<List<String>> getSavedStickers() async {
    final prefs = await _prefs();
    return prefs.getStringList(_savedStickersKey) ?? const <String>[];
  }

  static Future<void> setSavedStickers(List<String> stickerPaths) async {
    final prefs = await _prefs();
    await prefs.setStringList(_savedStickersKey, stickerPaths);
  }
}
