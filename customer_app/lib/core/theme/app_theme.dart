// lib/core/theme/app_theme.dart
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Professional Theme System using FlexColorScheme
/// Provides comprehensive light and dark themes with Material Design 3
/// 
/// Features:
/// - Professional color schemes optimized for accessibility
/// - Consistent typography across all components
/// - Material Design 3 support
/// - Automatic surface tinting and elevation handling
/// - Perfect contrast ratios for WCAG compliance
class AppTheme {
  // ===============================
  // FLEX COLOR SCHEME THEMES
  // ===============================

  /// Light Theme - Professional and clean design using FlexColorScheme
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      // Color scheme selection - using a professional blue scheme
      scheme: FlexScheme.blue,
      
      // Custom surface mode for better depth perception
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      
      // Blend level for surface tinting (subtle brand color integration)
      blendLevel: 7,
      
      // Enhanced component theming
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        
        // Button styling
        elevatedButtonRadius: 12.0,
        elevatedButtonElevation: 2.0,
        elevatedButtonSchemeColor: SchemeColor.primary,
        
        outlinedButtonRadius: 12.0,
        outlinedButtonSchemeColor: SchemeColor.primary,
        
        textButtonRadius: 12.0,
        textButtonSchemeColor: SchemeColor.primary,
        
        // Input decoration
        inputDecoratorRadius: 12.0,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        
        // Card styling
        cardRadius: 16.0,
        cardElevation: 2.0,
        
        // Navigation bar styling
        navigationBarElevation: 3.0,
        navigationBarHeight: 70.0,
        
        // FAB styling
        fabRadius: 16.0,
        fabUseShape: true,
        fabSchemeColor: SchemeColor.primary,
        
        // Dialog styling
        dialogRadius: 20.0,
        dialogElevation: 6.0,
        
        // Bottom sheet styling
        bottomSheetRadius: 20.0,
        bottomSheetElevation: 4.0,
      ),
      
      // Custom typography using SF Pro Display
      fontFamily: 'SF Pro Display',
      
      // Visual density for better touch targets
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      
      // Material Design 3 features
      useMaterial3: true,
      
      // Custom app bar theme for consistent branding
      appBarStyle: FlexAppBarStyle.primary,
      
      // Tab bar styling
      tabBarStyle: FlexTabBarStyle.forAppBar,
    );
  }

  /// Dark Theme - Comfortable dark mode using FlexColorScheme
  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      // Same color scheme as light theme for consistency
      scheme: FlexScheme.blue,
      
      // Dark surface mode for better dark theme experience
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      
      // Slightly higher blend level for dark theme depth
      blendLevel: 13,
      
      // Enhanced dark theme styling
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        
        // Button styling
        elevatedButtonRadius: 12.0,
        elevatedButtonElevation: 2.0,
        elevatedButtonSchemeColor: SchemeColor.primary,
        
        outlinedButtonRadius: 12.0,
        outlinedButtonSchemeColor: SchemeColor.primary,
        
        textButtonRadius: 12.0,
        textButtonSchemeColor: SchemeColor.primary,
        
        // Input decoration
        inputDecoratorRadius: 12.0,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        
        // Card styling
        cardRadius: 16.0,
        cardElevation: 2.0,
        
        // Navigation bar styling
        navigationBarElevation: 3.0,
        navigationBarHeight: 70.0,
        
        // FAB styling
        fabRadius: 16.0,
        fabUseShape: true,
        fabSchemeColor: SchemeColor.primary,
        
        // Dialog styling
        dialogRadius: 20.0,
        dialogElevation: 6.0,
        
        // Bottom sheet styling
        bottomSheetRadius: 20.0,
        bottomSheetElevation: 4.0,
      ),
      
      // Custom typography using SF Pro Display
      fontFamily: 'SF Pro Display',
      
      // Visual density for better touch targets
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      
      // Material Design 3 features
      useMaterial3: true,
      
      // Custom app bar theme for consistent branding
      appBarStyle: FlexAppBarStyle.primary,
      
      // Tab bar styling
      tabBarStyle: FlexTabBarStyle.forAppBar,
      
      // Dark theme specific adjustments
      darkIsTrueBlack: false, // Use dark gray instead of pure black for better OLED experience
    );
  }

  // ===============================
  // THEME UTILITIES
  // ===============================

  /// Get theme data based on brightness
  static ThemeData getTheme(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return lightTheme;
      case Brightness.dark:
        return darkTheme;
    }
  }

  /// Check if a theme is dark
  static bool isDark(ThemeData theme) {
    return theme.brightness == Brightness.dark;
  }

  /// Check if a theme is light
  static bool isLight(ThemeData theme) {
    return theme.brightness == Brightness.light;
  }

  // ===============================
  // SYSTEM UI OVERLAY STYLES
  // ===============================

  /// System UI overlay style for light theme
  static SystemUiOverlayStyle get lightSystemUiOverlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  /// System UI overlay style for dark theme
  static SystemUiOverlayStyle get darkSystemUiOverlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  /// Get system UI overlay style based on theme brightness
  static SystemUiOverlayStyle getSystemUiOverlayStyle(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return lightSystemUiOverlayStyle;
      case Brightness.dark:
        return darkSystemUiOverlayStyle;
    }
  }
}

// ===============================
// THEME EXTENSIONS
// ===============================

/// Extension to easily access theme properties
extension ThemeExtension on ThemeData {
  /// Check if current theme is dark
  bool get isDark => brightness == Brightness.dark;
  
  /// Check if current theme is light
  bool get isLight => brightness == Brightness.light;
  
  /// Get contrasting color for current theme
  Color get contrastingColor => isDark ? Colors.white : Colors.black;
  
  /// Get subtle background color
  Color get subtleBackground => colorScheme.surfaceContainerHighest;
  
  /// Get card background color
  Color get cardBackground => colorScheme.surface;
  
  /// Get divider color
  Color get dividerColor => colorScheme.outline.withOpacity(0.2);
}