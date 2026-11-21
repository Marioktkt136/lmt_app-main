import 'package:easy_localization/easy_localization.dart';

import '../../../core/utils/constants.dart';

/// Pure validation functions for the login form (return a localized error
/// message or `null` when valid).
class LoginValidators {
  LoginValidators._();

  /// Validates the username: required and at least
  /// [AppConstants.minUsernameLength] characters.
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'field_required'.tr();
    if (value.trim().length < AppConstants.minUsernameLength) {
      return 'username_too_short'.tr();
    }
    return null;
  }

  /// Validates the password: required and at least
  /// [AppConstants.minPasswordLength] characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'field_required'.tr();
    if (value.length < AppConstants.minPasswordLength) {
      return 'password_too_short'.tr();
    }
    return null;
  }
}
