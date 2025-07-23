// constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'UniRoute';

  // Asset Paths
  static const String logoPath = 'assets/images/bus_logo.png';
  static const String lottieSuccess = 'assets/animations/success.json';

  // Colors
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF42A5F5);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFD32F2F);

  // Padding, Radius, etc.
  static const double defaultPadding = 16.0;
  static const double cornerRadius = 12.0;

  // Regex Patterns
  static const String emailPattern = r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$";
  static const String passwordPattern =
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~]).{6,}$';

  // Firestore Collections
  static const String usersCollection = 'users';

  // Field Keys
  static const String statusKey = 'status';
  static const String roleKey = 'role';

  // SharedPreferences keys
  static const String keepSignedInKey = 'keep_signed_in';
  static const String authTokenKey = 'auth_token';
  static const String authEmailKey = 'auth_email';

  // Localization keys
  static const String fieldRequired = 'fields_required';
  static const String invalidEmail = 'invalid_email';
  static const String invalidPassword = 'invalid_password';
  static const String passwordMismatch = 'passwords_do_not_match';
  static const String userExists = 'user_already_exists';
  static const String loginFailed = 'login_failed';
  static const String keepMeSignedIn = 'keep_me_signed_in';
}
