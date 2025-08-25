import 'package:flutter/material.dart';

/// Notifier that manages current theme mode and notifies listeners on changes.
class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Check if current theme is dark mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Accept nullable ThemeMode? to match ValueChanged<ThemeMode?> signature.
  void setThemeMode(ThemeMode? mode) {
    if (mode == null) return; // ignore null values
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  void toggleTheme() {
    setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
