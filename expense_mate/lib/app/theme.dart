import 'package:flutter/material.dart';

ThemeData appTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF2563EB),
    brightness: Brightness.light,
  );
  return base.copyWith(
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
