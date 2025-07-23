// validators.dart
import 'package:easy_localization/easy_localization.dart';

class AppValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'email_required'.tr();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'invalid_email_format'.tr();
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'password_required'.tr();
    if (value.length < 8) return 'password_min_length'.tr();

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

    if (!hasUppercase) return 'password_uppercase_required'.tr();
    if (!hasLowercase) return 'password_lowercase_required'.tr();
    if (!hasNumber) return 'password_number_required'.tr();
    if (!hasSpecialChar) return 'password_special_char_required'.tr();

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'confirm_password_required'.tr();
    if (value != password) return 'passwords_mismatch'.tr();
    return null;
  }
}
