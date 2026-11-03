import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

/// Theme state notifier
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.light;
  }

  /// Load saved theme mode
  Future<void> _loadThemeMode() async {
    final savedMode = await _storage.read(key: 'theme_mode');
    if (savedMode == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }

  /// Toggle theme
  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    await _storage.write(key: 'theme_mode', value: isDark ? 'dark' : 'light');
  }

  /// Check if dark mode is enabled
  bool get isDarkMode => state == ThemeMode.dark;
}

/// Provider for theme
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

