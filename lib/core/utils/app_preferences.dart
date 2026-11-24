import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// Local Storage & Preferences Manager
/// Caches App Login, Security Tokens, Biometric Flags, Theme, Locale, and Offline Sync Data
class AppPreferences {
  AppPreferences._();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _rememberMeKey = 'lmt_remember_me';
  static const String _currentUserIdKey = 'current_user_id';
  static const String _cachedStateKey = 'lmt_cached_state_v1';
  static const String _sloganKey = 'lmt_slogan_of_year';
  static const String _verseKey = 'lmt_verse_of_year';
  static const String _savedStickersKey = 'lmt_saved_stickers_v1';
  static const String _lastWelcomedVersionKey = 'last_welcomed_app_version';
  static const String _lastUpdateDateKey = 'last_app_update_date';
  static const String _pendingUpdateWelcomeKey =
      'pending_shorebird_update_welcome';
  static const String _alertedNotifPrefix = 'lmt_alerted_notifs_v1_';
  static const String _webAuthnCredPrefix = 'lmt_webauthn_cred_v1_';

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
    String password = '',
    String? userId,
    String? accessToken,
    String? refreshToken,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(AppConstants.usernameKey, username);
    // Never store plaintext account passwords in device preferences.
    await prefs.remove(AppConstants.passwordKey);
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
    await prefs.remove(_currentUserIdKey);
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

  static Future<bool> isRememberMeEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_rememberMeKey) ?? true;
  }

  static Future<void> setRememberMe(bool remember) async {
    final prefs = await _prefs();
    await prefs.setBool(_rememberMeKey, remember);
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

  // Shorebird OTA Update & Welcome Tracking
  static Future<String?> getLastWelcomedAppVersion() async {
    final prefs = await _prefs();
    return prefs.getString(_lastWelcomedVersionKey);
  }

  static Future<void> setLastWelcomedAppVersion(String versionSignature) async {
    final prefs = await _prefs();
    await prefs.setString(_lastWelcomedVersionKey, versionSignature);
  }

  static Future<DateTime?> getLastUpdateDate() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_lastUpdateDateKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> setLastUpdateDate(DateTime dateTime) async {
    final prefs = await _prefs();
    await prefs.setString(_lastUpdateDateKey, dateTime.toIso8601String());
  }

  static Future<String?> getPendingUpdateWelcome() async {
    final prefs = await _prefs();
    return prefs.getString(_pendingUpdateWelcomeKey);
  }

  static Future<void> setPendingUpdateWelcome(String? value) async {
    final prefs = await _prefs();
    if (value == null || value.isEmpty) {
      await prefs.remove(_pendingUpdateWelcomeKey);
    } else {
      await prefs.setString(_pendingUpdateWelcomeKey, value);
    }
  }

  // Per-user persisted OS notification IDs so alerts fire once reliably.
  static Future<Set<String>> getAlertedNotificationIds(String userId) async {
    final prefs = await _prefs();
    final list = prefs.getStringList('$_alertedNotifPrefix$userId');
    return list == null ? <String>{} : list.toSet();
  }

  static Future<void> addAlertedNotificationIds(
    String userId,
    Iterable<String> newIds,
  ) async {
    final items = newIds.where((id) => id.isNotEmpty).toList();
    if (items.isEmpty) return;
    final prefs = await _prefs();
    final key = '$_alertedNotifPrefix$userId';
    final existing = prefs.getStringList(key) ?? const <String>[];
    final merged = <String>{...existing, ...items}.toList();
    // Keep only the latest 300 IDs so storage stays compact.
    final trimmed =
        merged.length > 300 ? merged.sublist(merged.length - 300) : merged;
    await prefs.setStringList(key, trimmed);
  }

  // WebAuthn / Passkey credential ID bound per user on this Web / iOS PWA device.
  static Future<String?> getWebAuthnCredentialId(String userId) async {
    final prefs = await _prefs();
    return prefs.getString('$_webAuthnCredPrefix$userId');
  }

  static Future<void> setWebAuthnCredentialId(
    String userId,
    String? credentialId,
  ) async {
    final prefs = await _prefs();
    final key = '$_webAuthnCredPrefix$userId';
    if (credentialId == null || credentialId.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, credentialId);
    }
  }
}
