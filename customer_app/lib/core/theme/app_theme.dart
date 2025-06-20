// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';
import 'button_styles.dart';

/// Comprehensive Design System Theme
/// Based on Cloud Ironing App Design Guidelines
class AppTheme {
  // ===============================
  // MAIN THEMES
  // ===============================

  /// Light Theme - Primary theme for the application
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme based on Design System
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.primary,          // Deep Navy Blue
        onPrimary: AppColors.textOnPrimary,  // White
        secondary: AppColors.secondary,      // Light Blue
        onSecondary: AppColors.textOnSecondary, // Deep Navy Blue
        tertiary: AppColors.accent,          // Bright Azure
        onTertiary: AppColors.textOnAccent,  // White
        error: AppColors.error,              // Soft Coral
        onError: AppColors.textOnError,      // White
        surface: AppColors.surface,          // White
        onSurface: AppColors.textSecondary,  // Dark Gray
        surfaceVariant: AppColors.surfaceVariant, // Light Gray
        onSurfaceVariant: AppColors.textTertiary, // Warm Gray
        background: AppColors.background,    // White
        onBackground: AppColors.textSecondary, // Dark Gray
        outline: AppColors.border,           // Medium Gray
        outlineVariant: AppColors.borderLight, // Light Gray
        shadow: AppColors.darkGray,
        scrim: AppColors.scrim,
        inverseSurface: AppColors.darkGray,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.secondary,
      ),
      
      // Typography using SF Pro Display
      fontFamily: 'SF Pro Display',
      textTheme: TextTheme(
        // Display styles
        displayLarge: AppTextTheme.displayLarge,
        displayMedium: AppTextTheme.displayMedium,
        displaySmall: AppTextTheme.displaySmall,
        
        // Headline styles (H1, H2, H3)
        headlineLarge: AppTextTheme.heading1,    // 22px Bold
        headlineMedium: AppTextTheme.heading2,   // 20px Bold
        headlineSmall: AppTextTheme.heading3,    // 18px SemiBold
        
        // Title styles
        titleLarge: AppTextTheme.titleLarge,
        titleMedium: AppTextTheme.titleMedium,
        titleSmall: AppTextTheme.titleSmall,
        
        // Body styles (16px, 14px)
        bodyLarge: AppTextTheme.bodyText,        // 16px Regular
        bodyMedium: AppTextTheme.bodyTextSmall,  // 14px Regular
        bodySmall: AppTextTheme.captionSmall,    // 12px Regular
        
        // Label styles (14px captions, buttons)
        labelLarge: AppTextTheme.label,          // 14px Medium
        labelMedium: AppTextTheme.caption,       // 14px Regular
        labelSmall: AppTextTheme.captionSmall,   // 12px Regular
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shadowColor: AppColors.border,
        centerTitle: true,
        titleTextStyle: AppTextTheme.heading3,
        iconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.primary,
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.outlinePrimary,
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: AppButtonStyles.textPrimary,
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: AppButtonStyles.accent,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        labelStyle: AppTextTheme.label,
        hintStyle: AppTextTheme.caption,
        errorStyle: AppTextTheme.captionSmall.copyWith(
          color: AppColors.error,
        ),
        
        // Border styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.accent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.disabled,
            width: 1,
          ),
        ),
        
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.surface,
        shadowColor: AppColors.border,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.warmGray,
        selectedLabelStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.warmGray,
        labelStyle: AppTextTheme.label,
        unselectedLabelStyle: AppTextTheme.caption,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.accent,
            width: 2,
          ),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        shape: CircleBorder(),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.accent,
        secondarySelectedColor: AppColors.secondary,
        labelStyle: AppTextTheme.caption,
        secondaryLabelStyle: AppTextTheme.caption.copyWith(
          color: AppColors.textOnAccent,
        ),
        brightness: Brightness.light,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTextTheme.heading3,
        contentTextStyle: AppTextTheme.bodyText,
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      
      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkGray,
        contentTextStyle: AppTextTheme.bodyTextSmall.copyWith(
          color: AppColors.white,
        ),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.textOnPrimary,
        size: 24,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.mediumGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent.withOpacity(0.3);
          }
          return AppColors.lightGray;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(AppColors.textOnAccent),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(
          color: AppColors.border,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.border;
        }),
      ),
      
      // Slider Theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.lightGray,
        thumbColor: AppColors.accent,
        overlayColor: Color(0x1F00A8E8), // Accent with low opacity
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.lightGray,
        circularTrackColor: AppColors.lightGray,
      ),
    );
  }

  // ===============================
  // DARK THEME (Future Enhancement)
  // ===============================

  /// Dark Theme - For future dark mode support
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.accent,
        onPrimary: AppColors.textOnAccent,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.primary,
        tertiary: AppColors.accentLight,
        onTertiary: AppColors.textOnAccent,
        error: AppColors.errorLight,
        onError: AppColors.textOnError,
        surface: AppColors.darkGray,
        onSurface: AppColors.white,
        background: AppColors.primary,
        onBackground: AppColors.white,
        outline: AppColors.warmGray,
      ),
      
      fontFamily: 'SF Pro Display',
      
      // Use same text theme but with appropriate colors for dark mode
      textTheme: TextTheme(
        headlineLarge: AppTextTheme.heading1.copyWith(color: AppColors.white),
        headlineMedium: AppTextTheme.heading2.copyWith(color: AppColors.white),
        headlineSmall: AppTextTheme.heading3.copyWith(color: AppColors.white),
        bodyLarge: AppTextTheme.bodyText.copyWith(color: AppColors.white),
        bodyMedium: AppTextTheme.bodyTextSmall.copyWith(color: AppColors.lightGray),
        labelLarge: AppTextTheme.label.copyWith(color: AppColors.white),
      ),
    );
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get appropriate text color for current theme
  static Color getTextColor(BuildContext context) {
    return isDark(context) ? AppColors.white : AppColors.textPrimary;
  }
}
