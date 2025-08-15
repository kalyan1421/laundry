// lib/core/theme/app_theme.dart
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_text_theme.dart';

ThemeData lightmode = ThemeData(
  // extensions: const <ThemeExtension>[
  //   AppAssets(logo: 'lib/presentation/assets/logos/app_logo_light.svg'),
  // ],
  // textTheme: GoogleFonts.poppinsTextTheme(),
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Color(0xffE6F4FD),
    secondary: Color(0xff006BAF),
    onSecondary: Color(0xffE6F4FD),
    tertiary: Color(0xff1A304E),
    onTertiary: Color(0xffFFFFFF),
    surface: Color(0xffFFFFFF),
    onSurface: Color(0xff0A131E),
    inversePrimary: Color(0xff000000),
  ),
);

ThemeData darkmode = ThemeData(
  // extensions: const <ThemeExtension>[
  //   AppAssets(logo: 'lib/presentation/assets/logos/app_logo_dark.svg'),
  // ],
  // textTheme: GoogleFonts.poppinsTextTheme(),
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Color(0xff1668DC),
    onPrimary: Color(0xffE6F4FD),
    secondary: Color(0xff006BAF),
    onSecondary: Color(0xffE6F4FD),
    tertiary: Color(0xff1A304E),
    onTertiary: Color(0xffFFFFFF),
    surface: Color(0xff212121),
    onSurface: Color(0xffFFFFFF),
    inversePrimary: Color(0xffFFFFFF),
  ),
);

// / Professional Theme System using FlexColorScheme
// / Provides comprehensive light and dark themes with Material Design 3
// /
// / Features:
// / - Professional color schemes optimized for accessibility
// / - Consistent typography across all components
// / - Material Design 3 support
// / - Automatic surface tinting and elevation handling
// / - Perfect contrast ratios for WCAG compliance
class AppTheme {
  // Build a TextTheme that adapts text colors to current theme for readability
  static TextTheme _textThemeFor(ThemeData theme) {
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return theme.textTheme.copyWith(
      // Displays and headlines use primary text color against surface
      displayLarge: AppTextTheme.displayLarge.copyWith(color: onSurface),
      displayMedium: AppTextTheme.displayMedium.copyWith(color: onSurface),
      displaySmall: AppTextTheme.displaySmall.copyWith(color: onSurface),
      headlineLarge: AppTextTheme.headlineLarge.copyWith(color: onSurface),
      headlineMedium: AppTextTheme.headlineMedium.copyWith(color: onSurface),
      headlineSmall: AppTextTheme.headlineSmall.copyWith(color: onSurface),

      // Titles
      titleLarge: AppTextTheme.titleLarge.copyWith(color: onSurface),
      titleMedium: AppTextTheme.titleMedium.copyWith(color: onSurface),
      titleSmall: AppTextTheme.titleSmall.copyWith(color: onSurface),

      // Body
      bodyLarge: AppTextTheme.bodyLarge.copyWith(color: onSurface),
      bodyMedium: AppTextTheme.bodyMedium.copyWith(color: onSurface),
      bodySmall: AppTextTheme.bodySmall.copyWith(color: onSurfaceVariant),

      // Labels (assistive/captions)
      labelLarge: AppTextTheme.labelLarge.copyWith(color: onSurfaceVariant),
      labelMedium: AppTextTheme.labelMedium.copyWith(color: onSurfaceVariant),
      labelSmall: AppTextTheme.labelSmall.copyWith(color: onSurfaceVariant),
    );
  }
  // ===============================
  // FLEX COLOR SCHEME THEMES
  // ===============================

  /// Light Theme - Professional and clean design using FlexColorScheme
  static ThemeData get lightTheme {
    final theme = FlexThemeData.light(
      // Use app design system colors for the light theme
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.accent,
        tertiaryContainer: AppColors.accentLight,
        error: AppColors.error,
      ),

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

    return theme.copyWith(
      // BottomNavigationBar styling for light theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: theme.colorScheme.background,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
        unselectedIconTheme:
            IconThemeData(color: theme.colorScheme.onSurfaceVariant),
        selectedLabelStyle: AppTextTheme.labelMedium.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextTheme.labelMedium
            .copyWith(color: theme.colorScheme.onSurfaceVariant),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      // Ensure ColorScheme backgrounds consistent with our palette
      colorScheme: theme.colorScheme.copyWith(
        surface: AppColors.surface,
        onSurface: AppColors.textSecondary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
      ),
      // Ensure text colors adapt to current theme for visibility
      textTheme: _textThemeFor(theme),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant,
        labelStyle:
            TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.9)),
        hintStyle:
            TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        helperStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        errorStyle: TextStyle(color: theme.colorScheme.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
    );
  }

  /// Dark Theme - Comfortable dark mode using FlexColorScheme
  static ThemeData get darkTheme {
    final theme = FlexThemeData.dark(
      // Use app design system colors for the dark theme
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        secondaryContainer: AppColors.secondary,
        tertiary: AppColors.accentDark,
        tertiaryContainer: AppColors.accent,
        error: AppColors.errorDark,
      ),

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
      darkIsTrueBlack:
          false, // Use dark gray instead of pure black for better OLED experience
    );

    return theme.copyWith(
      // BottomNavigationBar styling for dark theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
        unselectedIconTheme:
            IconThemeData(color: theme.colorScheme.onSurfaceVariant),
        selectedLabelStyle: AppTextTheme.labelMedium.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextTheme.labelMedium
            .copyWith(color: theme.colorScheme.onSurfaceVariant),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      // Override dark ColorScheme with Ant Design dark tokens while keeping brand colors
      colorScheme: theme.colorScheme.copyWith(
        surface: AppColors.adDarkSurface,
        onSurface: AppColors.adTextPrimary,
        surfaceContainerHighest: AppColors.adDarkSurfaceSecondary,
        onSurfaceVariant: AppColors.adTextSecondary,
        outline: AppColors.adBorder,
        outlineVariant: AppColors.adDivider,
        // Keep primary/secondary/tertiary from scheme (already brand colors)
      ),
      // Ensure text colors adapt to current theme for visibility
      textTheme: _textThemeFor(theme),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant,
        labelStyle:
            TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.9)),
        hintStyle:
            TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        helperStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        errorStyle: TextStyle(color: theme.colorScheme.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
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

// ignore_for_file: prefer_const_constructors
