// lib/theme/theme.dart
import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 8,
    foregroundColor: Colors.black,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
    bodySmall: TextStyle(fontSize: 14, color: Colors.grey),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.blue,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    showCloseIcon: true,
    dismissDirection: DismissDirection.down,
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.black,
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 8,
    foregroundColor: Colors.white,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.black,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
    bodySmall: TextStyle(fontSize: 14, color: Colors.grey),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.blue,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    showCloseIcon: true,
    dismissDirection: DismissDirection.down,
  ),
);
