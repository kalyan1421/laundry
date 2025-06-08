// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import '../constants/font_constants.dart';

class AppTypography {
  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.displayLarge,
    fontWeight: FontConstants.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.displayMedium,
    fontWeight: FontConstants.medium,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.displaySmall,
    fontWeight: FontConstants.medium,
    height: 1.3,
    letterSpacing: -0.2,
  );
  
  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.headlineLarge,
    fontWeight: FontConstants.medium,
    height: 1.4,
    letterSpacing: -0.2,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.headlineMedium,
    fontWeight: FontConstants.medium,
    height: 1.4,
    letterSpacing: -0.1,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.headlineSmall,
    fontWeight: FontConstants.medium,
    height: 1.4,
  );
  
  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.titleLarge,
    fontWeight: FontConstants.medium,
    height: 1.5,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.titleMedium,
    fontWeight: FontConstants.medium,
    height: 1.5,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.titleSmall,
    fontWeight: FontConstants.medium,
    height: 1.5,
  );
  
  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.bodyLarge,
    fontWeight: FontConstants.regular,
    height: 1.6,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.bodyMedium,
    fontWeight: FontConstants.regular,
    height: 1.6,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.bodySmall,
    fontWeight: FontConstants.regular,
    height: 1.6,
  );
  
  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.labelLarge,
    fontWeight: FontConstants.medium,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.labelMedium,
    fontWeight: FontConstants.medium,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: FontConstants.labelSmall,
    fontWeight: FontConstants.medium,
    height: 1.4,
  );
  
  // Button Styles
  static const TextStyle button = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: 16,
    fontWeight: FontConstants.medium,
    height: 1.2,
    letterSpacing: 0.1,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: 14,
    fontWeight: FontConstants.medium,
    height: 1.2,
    letterSpacing: 0.1,
  );
  
  // Caption and Overline
  static const TextStyle caption = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: 12,
    fontWeight: FontConstants.regular,
    height: 1.3,
    letterSpacing: 0.4,
  );
  
  static const TextStyle overline = TextStyle(
    fontFamily: FontConstants.sfProDisplay,
    fontSize: 10,
    fontWeight: FontConstants.medium,
    height: 1.6,
    letterSpacing: 1.5,
  );
}