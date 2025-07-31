import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'UniRoute';

  // Splash Screen
  static const Duration minSplashDuration = Duration(seconds: 2);
  static const Duration transitionDuration = Duration(milliseconds: 300);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  static const String firstLaunchKey = 'isFirstLaunch';

  // Asset Paths
  static const String logoPath = 'assets/images/bus_logo.png';
  static const String busLogoPath = 'assets/images/bus_logo.gif';
  static const String lottieSuccess = 'assets/animations/success.json';

  // Colors
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF42A5F5);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFFA000);

  // Padding, Radius, etc.
  static const double defaultPadding = 16.0;
  static const double cornerRadius = 12.0;
  static const double buttonHeight = 48.0;

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

  // Error Messages
  static const String initializationErrorTitle = 'Initialization Error';
  static const String unknownError = 'Unknown error occurred';
  static const String attemptingRecovery = 'Attempting to recover...';
  static const String initializationFailed = 'Initialization failed';
  static const String fieldRequired = 'All fields are required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPassword =
      'Password must contain at least 6 characters with letters, numbers, and special characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String userExists = 'User already exists';
  static const String loginFailed =
      'Login failed. Please check your credentials';

  // UI Texts
  static const String keepMeSignedIn = 'Keep me signed in';
  static const String retryNow = 'Retry Now';
  static const String continueAnyway = 'Continue Anyway';
  static const String retry = 'Retry';
  static const String success = 'Success';
  static const String error = 'Error';

  // Animation Durations
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
  static const Duration toastDuration = Duration(seconds: 3);

  // Maximum values
  static const int maxEmailLength = 50;
  static const int maxPasswordLength = 30;
  static const int maxNameLength = 50;

  // Default values
  static const String defaultUserRole = 'student';
  static const String defaultUserStatus = 'active';

  // List of country codes and dial codes
  static List<Map<String, String>> countryCodes = [
    {'code': 'US', 'dial_code': '+1', 'name': 'United States'},
    {'code': 'TR', 'dial_code': '+90', 'name': 'Turkey'},
    {'code': 'GB', 'dial_code': '+44', 'name': 'United Kingdom'},
    // Add more as needed
  ];

  static Map<String, String> countryNames = {
    'US': 'United States',
    'TR': 'Turkey',
    'GB': 'United Kingdom',
    // Add more
  };
}
