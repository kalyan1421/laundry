// lib/presentation/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Provider for managing app theme state
/// Supports light, dark, and system themes with persistence
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  // Default to system theme to follow device settings
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  
  /// Check if current theme is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Check if current theme is light
  bool get isLightMode => _themeMode == ThemeMode.light;
  
  /// Check if current theme follows system
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Initialize theme from stored preferences
  Future<void> initializeTheme() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 2; // Default to system (2)
      
      switch (themeIndex) {
        case 0:
          _themeMode = ThemeMode.light;
          break;
        case 1:
          _themeMode = ThemeMode.dark;
          break;
        case 2:
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing theme: $e');
      _themeMode = ThemeMode.light; // Fallback to light theme
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      int themeIndex;
      
      switch (mode) {
        case ThemeMode.light:
          themeIndex = 0;
          break;
        case ThemeMode.dark:
          themeIndex = 1;
          break;
        case ThemeMode.system:
          themeIndex = 2;
          break;
      }
      
      await prefs.setInt(_themeKey, themeIndex);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Set light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Set system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Get theme mode display name
  String getThemeModeDisplayName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get theme mode description
  String getThemeModeDescription() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system settings';
    }
  }
}
