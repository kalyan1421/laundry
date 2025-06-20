import 'package:customer_app/core/constants/font_constants.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart'; // Assuming AppColors is in the same directory

/// Comprehensive Design System Typography
/// Based on Cloud Ironing App Design Guidelines
/// 
/// Typography Hierarchy:
/// - Heading 1: 22px, Bold, Deep Navy Blue
/// - Heading 2: 20px, Bold, Deep Navy Blue  
/// - Heading 3: 18px, SemiBold, Deep Navy Blue
/// - Body Text: 16px, Regular, Dark Gray
/// - Caption: 14px, Regular, Warm Gray
/// - Button Text: 14px, Medium, varies by button type
class AppTextTheme {
  static const String _fontFamily = FontConstants.sfProDisplay;

  // ===============================
  // HEADINGS
  // ===============================

  /// Heading 1: 22px, Bold, Deep Navy Blue
  /// Used for: Main page titles, primary headers
  static const TextStyle heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, // Deep Navy Blue
    height: 1.3,
    letterSpacing: -0.3,
  );

  /// Heading 2: 20px, Bold, Deep Navy Blue
  /// Used for: Section headers, card titles
  static const TextStyle heading2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, // Deep Navy Blue
    height: 1.3,
    letterSpacing: -0.2,
  );

  /// Heading 3: 18px, SemiBold, Deep Navy Blue
  /// Used for: Subsection headers, important labels
  static const TextStyle heading3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.textPrimary, // Deep Navy Blue
    height: 1.4,
    letterSpacing: -0.1,
  );

  // ===============================
  // BODY TEXT
  // ===============================

  /// Body Text: 16px, Regular, Dark Gray
  /// Used for: Main content, descriptions, paragraphs
  static const TextStyle bodyText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textSecondary, // Dark Gray
    height: 1.5,
    letterSpacing: 0.0,
  );

  /// Body Text Medium: 16px, Medium, Dark Gray
  /// Used for: Emphasized body text, important content
  static const TextStyle bodyTextMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textSecondary, // Dark Gray
    height: 1.5,
    letterSpacing: 0.0,
  );

  /// Body Text Small: 14px, Regular, Dark Gray
  /// Used for: Secondary content, smaller descriptions
  static const TextStyle bodyTextSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textSecondary, // Dark Gray
    height: 1.4,
    letterSpacing: 0.1,
  );

  // ===============================
  // CAPTIONS & LABELS
  // ===============================

  /// Caption: 14px, Regular, Warm Gray
  /// Used for: Helper text, timestamps, metadata
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textTertiary, // Warm Gray
    height: 1.3,
    letterSpacing: 0.2,
  );

  /// Caption Small: 12px, Regular, Warm Gray
  /// Used for: Small helper text, fine print
  static const TextStyle captionSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textTertiary, // Warm Gray
    height: 1.3,
    letterSpacing: 0.3,
  );

  /// Label: 14px, Medium, varies by context
  /// Used for: Form labels, menu items
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textSecondary, // Dark Gray
    height: 1.3,
    letterSpacing: 0.1,
  );

  // ===============================
  // BUTTON TEXT
  // ===============================

  /// Button Text: 14px, Medium
  /// Base style for buttons - color varies by button type
  static const TextStyle buttonText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500, // Medium
    height: 1.2,
    letterSpacing: 0.8,
  );

  /// Primary Button Text: 14px, Medium, White
  static const TextStyle buttonTextPrimary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textOnPrimary, // White
    height: 1.2,
    letterSpacing: 0.8,
  );

  /// Secondary Button Text: 14px, Medium, Deep Navy Blue
  static const TextStyle buttonTextSecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textPrimary, // Deep Navy Blue
    height: 1.2,
    letterSpacing: 0.8,
  );

  /// Accent Button Text: 14px, Medium, White
  static const TextStyle buttonTextAccent = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textOnAccent, // White
    height: 1.2,
    letterSpacing: 0.8,
  );

  // ===============================
  // LEGACY FLUTTER TEXT THEME MAPPING
  // ===============================

  /// Large Display Text (for Flutter compatibility)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Medium Display Text (for Flutter compatibility)
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.4,
  );

  /// Small Display Text (for Flutter compatibility)
  static const TextStyle displaySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  /// Large Headline (maps to heading1)
  static const TextStyle headlineLarge = heading1;
  
  /// Medium Headline (maps to heading2)
  static const TextStyle headlineMedium = heading2;
  
  /// Small Headline (maps to heading3)
  static const TextStyle headlineSmall = heading3;

  /// Large Title
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.0,
  );

  /// Medium Title
  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,  
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Small Title
  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  /// Large Body (maps to bodyText)
  static const TextStyle bodyLarge = bodyText;
  
  /// Medium Body (maps to bodyTextSmall)
  static const TextStyle bodyMedium = bodyTextSmall;
  
  /// Small Body (maps to captionSmall)
  static const TextStyle bodySmall = captionSmall;

  /// Large Label
  static const TextStyle labelLarge = label;
  
  /// Medium Label
  static const TextStyle labelMedium = caption;
  
  /// Small Label
  static const TextStyle labelSmall = captionSmall;

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Get text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get text style with custom size
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }

  /// Get text style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight fontWeight) {
    return style.copyWith(fontWeight: fontWeight);
  }

  /// Get text style with opacity
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withOpacity(opacity));
  }
} 