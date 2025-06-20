// theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // PRIMARY COLOR PALETTE
  
  // Primary: Deep Navy Blue - Headers, navigation, primary buttons, brand elements
  static const Color primaryNavy = Color(0xFF0F3057);
  
  // Secondary: Light Blue - Accent elements, hover states, secondary backgrounds
  static const Color secondaryLightBlue = Color(0xFF88C1E3);
  
  // Accent: Bright Azure - Call-to-action buttons, links, highlights
  static const Color accentAzure = Color(0xFF00A8E8);
  
  // Success: Fresh Teal - Success indicators, testimonial highlights
  static const Color successTeal = Color(0xFF5CB8B2);
  
  // Warm: Gold Yellow - Special offers, premium service highlights
  static const Color warmGold = Color(0xFFFFB347);
  
  // NEUTRALS
  
  // Pure White - Main backgrounds, card backgrounds
  static const Color pureWhite = Color(0xFFFFFFFF);
  
  // Light Gray - Section backgrounds, subtle separators
  static const Color lightGray = Color(0xFFF5F7FA);
  
  // Medium Gray - Borders, inactive states
  static const Color mediumGray = Color(0xFFD9E2EC);
  
  // Dark Gray - Body text, content
  static const Color darkGray = Color(0xFF3B4D61);
  
  // Warm Gray - Secondary text, captions
  static const Color warmGray = Color(0xFF6E7A8A);
  
  // LEGACY COMPATIBILITY (for gradual migration)
  static const Color primaryBlue = accentAzure; // Maps to Bright Azure
  static const Color darkBlue = primaryNavy; // Maps to Deep Navy Blue
  static const Color lightBackground = lightGray; // Maps to Light Gray
  static const Color white = pureWhite; // Maps to Pure White
  static const Color textDark = darkGray; // Maps to Dark Gray
  static const Color textGrey = warmGray; // Maps to Warm Gray
  
  // FONT FAMILY CONSTANT
  static const String primaryFont = 'SF Pro Display';
  
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryNavy,
    scaffoldBackgroundColor: pureWhite,
    fontFamily: primaryFont,
    
    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: primaryNavy,
      secondary: secondaryLightBlue,
      tertiary: accentAzure,
      surface: pureWhite,
      background: lightGray,
      error: Colors.red.shade600,
      onPrimary: pureWhite,
      onSecondary: primaryNavy,
      onSurface: darkGray,
      onBackground: darkGray,
    ),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryNavy,
      elevation: 0,
      iconTheme: const IconThemeData(color: pureWhite),
      titleTextStyle: TextStyle(
        color: pureWhite,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: primaryFont,
      ),
    ),
    
    // Text Theme with SF Pro Display
    textTheme: TextTheme(
      // Display Styles - For hero titles and major headings
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: primaryNavy,
        height: 1.2,
        fontFamily: primaryFont,
      ),
      displayMedium: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: primaryNavy,
        height: 1.2,
        fontFamily: primaryFont,
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryNavy,
        height: 1.2,
        fontFamily: primaryFont,
      ),
      
      // Headline Styles - For section headers
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryNavy,
        height: 1.3,
        fontFamily: primaryFont,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryNavy,
        height: 1.3,
        fontFamily: primaryFont,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryNavy,
        height: 1.3,
        fontFamily: primaryFont,
      ),
      
      // Title Styles - For card headers and subsections
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkGray,
        height: 1.4,
        fontFamily: primaryFont,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkGray,
        height: 1.4,
        fontFamily: primaryFont,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkGray,
        height: 1.4,
        fontFamily: primaryFont,
      ),
      
      // Body Styles - For main content
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: darkGray,
        height: 1.6,
        fontFamily: primaryFont,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: darkGray,
        height: 1.5,
        fontFamily: primaryFont,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: warmGray,
        height: 1.5,
        fontFamily: primaryFont,
      ),
      
      // Label Styles - For buttons and small labels
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: pureWhite,
        fontFamily: primaryFont,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkGray,
        fontFamily: primaryFont,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: warmGray,
        fontFamily: primaryFont,
      ),
    ),
    
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentAzure,
        foregroundColor: pureWhite,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFont,
        ),
        elevation: 2,
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryNavy,
        side: const BorderSide(color: primaryNavy, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFont,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentAzure,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFont,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: pureWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(
        color: warmGray,
        fontFamily: primaryFont,
      ),
      labelStyle: TextStyle(
        color: darkGray,
        fontFamily: primaryFont,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentAzure, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      color: pureWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: primaryNavy.withOpacity(0.1),
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      color: mediumGray,
      thickness: 1,
    ),
    
    // Icon Theme
    iconTheme: IconThemeData(
      color: darkGray,
      size: 24,
    ),
    
    // Primary Icon Theme
    primaryIconTheme: IconThemeData(
      color: pureWhite,
      size: 24,
    ),
  );
  
  // UTILITY METHODS FOR CONSISTENT STYLING
  
  // Get text style with consistent font
  static TextStyle getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = darkGray,
    double height = 1.5,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontFamily: primaryFont,
    );
  }
  
  // Get button style with consistent styling
  static ButtonStyle getButtonStyle({
    Color backgroundColor = accentAzure,
    Color foregroundColor = pureWhite,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    double borderRadius = 25,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: primaryFont,
      ),
    );
  }
  
  // Get container decoration with consistent styling
  static BoxDecoration getCardDecoration({
    Color color = pureWhite,
    double borderRadius = 16,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: hasShadow ? [
        BoxShadow(
          color: primaryNavy.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ] : null,
    );
  }
}