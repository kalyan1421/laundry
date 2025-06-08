import 'package:customer_app/core/constants/font_constants.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart'; // Assuming AppColors is in the same directory

class AppTextTheme {
  static const String _fontFamily = FontConstants.sfProDisplay;

  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.25,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.0,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w600, // Semibold for slightly less emphasis
    color: AppColors.textPrimary,
    letterSpacing: 0.0,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.15,
  );
  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500, // Medium weight
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  // Body Text Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: 0.25,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );

  // Button Text Style
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary, // Default for primary buttons
    letterSpacing: 1.25,
  );

  // Caption Text Style
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    letterSpacing: 0.4,
  );

  // Overline Text Style
  static const TextStyle overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    letterSpacing: 1.5,
  );

  // Label styles (often similar to titles or body but can be distinct)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, 
    letterSpacing: 0.1,
  );
} 