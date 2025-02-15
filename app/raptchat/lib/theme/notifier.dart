import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  final ThemeData _currentTheme;
  ThemeMode _currentThemeMode;

  ThemeNotifier(this._currentTheme, String initialMode)
      : _currentThemeMode = _getThemeMode(initialMode);

  ThemeData get currentTheme => _currentTheme;
  ThemeMode get currentThemeMode => _currentThemeMode;

  void switchThemeMode(String mode) {
    _currentThemeMode = _getThemeMode(mode);
    notifyListeners();
  }

  static ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
      default:
        return ThemeMode.system;
    }
  }
}
