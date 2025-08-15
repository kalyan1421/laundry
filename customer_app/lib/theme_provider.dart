import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeFromPreferences(); // Load the theme mode when the provider is initialized
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners(); // Notify listeners to rebuild UI
    await _saveThemeToPreferences(mode); // Save the theme mode
  }

  Future<void> _loadThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final theme =
        prefs.getString('themeMode') ?? 'system'; // Default to 'system'
    _themeMode = _themeModeFromString(theme);
    notifyListeners();
  }

  Future<void> _saveThemeToPreferences(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', _themeModeToString(mode));
  }

  // Helper methods to convert ThemeMode to/from String
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}