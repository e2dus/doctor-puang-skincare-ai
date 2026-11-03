import 'package:flutter/material.dart';

/// Theme mode entity
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Extension to convert to Flutter ThemeMode
extension AppThemeModeExtension on AppThemeMode {
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

