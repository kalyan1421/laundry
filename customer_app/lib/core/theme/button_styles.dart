import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Comprehensive Design System Button Styles
/// Based on Cloud Ironing App Design Guidelines
class AppButtonStyles {
  // ===============================
  // BUTTON CONSTANTS
  // ===============================
  
  static const double _borderRadius = 12.0;
  static const double _smallBorderRadius = 8.0;
  static const double _largeBorderRadius = 16.0;
  
  static const EdgeInsets _defaultPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );
  
  static const EdgeInsets _smallPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  
  static const EdgeInsets _largePadding = EdgeInsets.symmetric(
    horizontal: 32.0,
    vertical: 20.0,
  );

  static const Size _defaultMinSize = Size(120, 48);
  static const Size _smallMinSize = Size(80, 36);
  static const Size _largeMinSize = Size(160, 56);

  // ===============================
  // PRIMARY BUTTONS
  // ===============================

  /// Primary Button: Deep Navy Blue background, white text
  /// Used for: Main actions, form submissions, confirmations
  static ButtonStyle get primary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        textStyle: AppTextTheme.buttonTextPrimary,
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primaryDark.withOpacity(0.8);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primaryLight.withOpacity(0.1);
          }
          return null;
        }),
      );

  /// Primary Button Large
  static ButtonStyle get primaryLarge => primary.copyWith(
        padding: WidgetStateProperty.all(_largePadding),
        minimumSize: WidgetStateProperty.all(_largeMinSize),
        textStyle: WidgetStateProperty.all(
          AppTextTheme.buttonTextPrimary.copyWith(fontSize: 16.0),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_largeBorderRadius),
          ),
        ),
      );

  /// Primary Button Small
  static ButtonStyle get primarySmall => primary.copyWith(
        padding: WidgetStateProperty.all(_smallPadding),
        minimumSize: WidgetStateProperty.all(_smallMinSize),
        textStyle: WidgetStateProperty.all(
          AppTextTheme.buttonTextPrimary.copyWith(fontSize: 12.0),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_smallBorderRadius),
          ),
        ),
      );

  // ===============================
  // SECONDARY BUTTONS
  // ===============================

  /// Secondary Button: Light Blue background, Deep Navy text
  /// Used for: Secondary actions, alternative options
  static ButtonStyle get secondary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnSecondary,
        textStyle: AppTextTheme.buttonTextSecondary,
        elevation: 1,
        shadowColor: AppColors.secondary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  /// Secondary Button Large
  static ButtonStyle get secondaryLarge => secondary.copyWith(
        padding: WidgetStateProperty.all(_largePadding),
        minimumSize: WidgetStateProperty.all(_largeMinSize),
        textStyle: WidgetStateProperty.all(
          AppTextTheme.buttonTextSecondary.copyWith(fontSize: 16.0),
        ),
      );

  // ===============================
  // ACCENT BUTTONS
  // ===============================

  /// Accent Button: Bright Azure background, white text
  /// Used for: Call-to-action elements, highlight actions
  static ButtonStyle get accent => ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        textStyle: AppTextTheme.buttonTextAccent,
        elevation: 2,
        shadowColor: AppColors.accent.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  // ===============================
  // OUTLINE BUTTONS
  // ===============================

  /// Outline Primary: Deep Navy border and text, transparent background
  static ButtonStyle get outlinePrimary => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextTheme.buttonTextSecondary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  /// Outline Secondary: Light Blue border and text, transparent background
  static ButtonStyle get outlineSecondary => OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        textStyle: AppTextTheme.buttonTextSecondary.copyWith(
          color: AppColors.secondary,
        ),
        side: const BorderSide(color: AppColors.secondary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  // ===============================
  // TEXT BUTTONS
  // ===============================

  /// Text Primary: Deep Navy text, no background
  static ButtonStyle get textPrimary => TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextTheme.buttonTextSecondary,
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      );

  /// Text Secondary: Warm Gray text, no background
  static ButtonStyle get textSecondary => TextButton.styleFrom(
        foregroundColor: AppColors.warmGray,
        textStyle: AppTextTheme.buttonTextSecondary.copyWith(
          color: AppColors.warmGray,
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      );

  // ===============================
  // SEMANTIC BUTTONS
  // ===============================

  /// Success Button: Fresh Teal background, white text
  static ButtonStyle get success => ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.textOnSuccess,
        textStyle: AppTextTheme.buttonTextPrimary,
        elevation: 1,
        shadowColor: AppColors.success.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  /// Error Button: Soft Coral background, white text
  static ButtonStyle get error => ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.textOnError,
        textStyle: AppTextTheme.buttonTextPrimary,
        elevation: 1,
        shadowColor: AppColors.error.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  /// Warning Button: Warning color background, appropriate text
  static ButtonStyle get warning => ElevatedButton.styleFrom(
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.textPrimary,
        textStyle: AppTextTheme.buttonTextSecondary,
        elevation: 1,
        shadowColor: AppColors.warning.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  // ===============================
  // SPECIAL BUTTONS
  // ===============================

  /// Disabled Button: Medium gray background, disabled text
  static ButtonStyle get disabled => ElevatedButton.styleFrom(
        backgroundColor: AppColors.disabled,
        foregroundColor: AppColors.textDisabled,
        textStyle: AppTextTheme.buttonTextSecondary.copyWith(
          color: AppColors.textDisabled,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  /// Gradient Primary Button
  static ButtonStyle get gradientPrimary => ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textOnPrimary,
        textStyle: AppTextTheme.buttonTextPrimary,
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: _defaultPadding,
        minimumSize: _defaultMinSize,
      );

  /// Floating Action Button Style
  static ButtonStyle get fab => ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        elevation: 6,
        shadowColor: AppColors.accent.withOpacity(0.4),
        shape: const CircleBorder(),
        minimumSize: const Size(56, 56),
        padding: EdgeInsets.zero,
      );

  /// Icon Button Style
  static ButtonStyle get iconButton => IconButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(8.0),
      );

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Create custom button style with specific color
  static ButtonStyle custom({
    required Color backgroundColor,
    required Color foregroundColor,
    TextStyle? textStyle,
    double? elevation,
    EdgeInsets? padding,
    Size? minimumSize,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      textStyle: textStyle ?? AppTextTheme.buttonText,
      elevation: elevation ?? 1,
      shadowColor: backgroundColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? _borderRadius),
      ),
      padding: padding ?? _defaultPadding,
      minimumSize: minimumSize ?? _defaultMinSize,
    );
  }

  /// Create outline button with custom color
  static ButtonStyle customOutline({
    required Color borderColor,
    required Color foregroundColor,
    TextStyle? textStyle,
    double borderWidth = 1.5,
    EdgeInsets? padding,
    Size? minimumSize,
    double? borderRadius,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      textStyle: textStyle ?? AppTextTheme.buttonTextSecondary,
      side: BorderSide(color: borderColor, width: borderWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? _borderRadius),
      ),
      padding: padding ?? _defaultPadding,
      minimumSize: minimumSize ?? _defaultMinSize,
    );
  }
}
