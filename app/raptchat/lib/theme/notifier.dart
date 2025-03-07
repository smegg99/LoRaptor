// lib/theme/notifier.dart
import 'package:flutter/material.dart';

TextTheme modifyTextTheme(TextTheme base, double weightValue) {
  return TextTheme(
    displayLarge: base.displayLarge?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontVariations: [FontVariation('wght', weightValue)],
    ),
  );
}

class ThemeNotifier extends ChangeNotifier {
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  ThemeMode _themeMode;

  static const String fontFamily = 'Overpass';
  static const double fontWeight = 500;

  ThemeNotifier({
    required ThemeData lightThemeBase,
    required ThemeData darkThemeBase,
    required String initialMode,
  })  : lightTheme = lightThemeBase.copyWith(
          textTheme: modifyTextTheme(
              lightThemeBase.textTheme.apply(fontFamily: fontFamily), fontWeight),
          primaryTextTheme: modifyTextTheme(
              lightThemeBase.primaryTextTheme.apply(fontFamily: fontFamily),
              fontWeight),
        ),
        darkTheme = darkThemeBase.copyWith(
          textTheme: modifyTextTheme(
              darkThemeBase.textTheme.apply(fontFamily: fontFamily), fontWeight),
          primaryTextTheme: modifyTextTheme(
              darkThemeBase.primaryTextTheme.apply(fontFamily: fontFamily),
              fontWeight),
        ),
        _themeMode = _getThemeMode(initialMode);

  ThemeMode get currentThemeMode => _themeMode;

  void switchThemeMode(String mode) {
    _themeMode = _getThemeMode(mode);
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
