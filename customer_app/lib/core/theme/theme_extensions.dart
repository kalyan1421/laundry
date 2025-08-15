// lib/core/theme/theme_extensions.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Theme Extensions for easy access to colors and text styles
/// This provides a convenient way to access theme properties throughout the app
extension ThemeExtensions on BuildContext {
  
  // ===============================
  // THEME ACCESSORS
  // ===============================
  
  /// Get the current theme
  ThemeData get theme => Theme.of(this);
  
  /// Get the current color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Get the current text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Check if current theme is dark
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Check if current theme is light
  bool get isLightMode => theme.brightness == Brightness.light;
  
  // ===============================
  // COLOR ACCESSORS
  // ===============================
  
  /// Primary colors
  Color get primaryColor => colorScheme.primary;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get primaryContainer => colorScheme.primaryContainer;
  Color get onPrimaryContainer => colorScheme.onPrimaryContainer;
  
  /// Secondary colors
  Color get secondaryColor => colorScheme.secondary;
  Color get onSecondaryColor => colorScheme.onSecondary;
  Color get secondaryContainer => colorScheme.secondaryContainer;
  Color get onSecondaryContainer => colorScheme.onSecondaryContainer;
  
  /// Tertiary colors (accent)
  Color get tertiaryColor => colorScheme.tertiary;
  Color get onTertiaryColor => colorScheme.onTertiary;
  Color get tertiaryContainer => colorScheme.tertiaryContainer;
  Color get onTertiaryContainer => colorScheme.onTertiaryContainer;
  
  /// Surface colors
  Color get surfaceColor => colorScheme.surface;
  Color get onSurfaceColor => colorScheme.onSurface;
  Color get surfaceVariant => colorScheme.surfaceVariant;
  Color get onSurfaceVariant => colorScheme.onSurfaceVariant;
  
  /// Background colors
  Color get backgroundColor => colorScheme.background;
  Color get onBackgroundColor => colorScheme.onBackground;
  
  /// Error colors
  Color get errorColor => colorScheme.error;
  Color get onErrorColor => colorScheme.onError;
  Color get errorContainer => colorScheme.errorContainer;
  Color get onErrorContainer => colorScheme.onErrorContainer;
  
  /// Outline colors
  Color get outlineColor => colorScheme.outline;
  Color get outlineVariant => colorScheme.outlineVariant;
  
  /// Shadow and scrim
  Color get shadowColor => colorScheme.shadow;
  Color get scrimColor => colorScheme.scrim;
  
  /// Inverse colors
  Color get inverseSurface => colorScheme.inverseSurface;
  Color get onInverseSurface => colorScheme.onInverseSurface;
  Color get inversePrimary => colorScheme.inversePrimary;
  
  // ===============================
  // SEMANTIC COLOR ACCESSORS
  // ===============================
  
  /// Success color (always from AppColors for consistency)
  Color get successColor => AppColors.success;
  Color get onSuccessColor => AppColors.textOnSuccess;
  
  /// Warning color
  Color get warningColor => AppColors.warning;
  Color get onWarningColor => AppColors.textPrimary;
  
  /// Info color (uses tertiary/accent)
  Color get infoColor => tertiaryColor;
  Color get onInfoColor => onTertiaryColor;
  
  // ===============================
  // TEXT STYLE ACCESSORS
  // ===============================
  
  /// Heading styles
  TextStyle get heading1 => textTheme.headlineLarge!;
  TextStyle get heading2 => textTheme.headlineMedium!;
  TextStyle get heading3 => textTheme.headlineSmall!;
  
  /// Title styles
  TextStyle get titleLarge => textTheme.titleLarge!;
  TextStyle get titleMedium => textTheme.titleMedium!;
  TextStyle get titleSmall => textTheme.titleSmall!;
  
  /// Body styles
  TextStyle get bodyLarge => textTheme.bodyLarge!;
  TextStyle get bodyMedium => textTheme.bodyMedium!;
  TextStyle get bodySmall => textTheme.bodySmall!;
  
  /// Label styles
  TextStyle get labelLarge => textTheme.labelLarge!;
  TextStyle get labelMedium => textTheme.labelMedium!;
  TextStyle get labelSmall => textTheme.labelSmall!;
  
  /// Display styles
  TextStyle get displayLarge => textTheme.displayLarge!;
  TextStyle get displayMedium => textTheme.displayMedium!;
  TextStyle get displaySmall => textTheme.displaySmall!;
  
  // ===============================
  // BUTTON STYLE ACCESSORS
  // ===============================
  
  /// Get primary button style
  ButtonStyle get primaryButtonStyle => theme.elevatedButtonTheme.style!;
  
  /// Get secondary button style
  ButtonStyle get secondaryButtonStyle => theme.outlinedButtonTheme.style!;
  
  /// Get text button style
  ButtonStyle get textButtonStyle => theme.textButtonTheme.style!;
  
  // ===============================
  // CONVENIENCE METHODS
  // ===============================
  
  /// Get appropriate text color for a background
  Color getTextColorForBackground(Color backgroundColor) {
    return AppColors.getContrastingTextColor(backgroundColor);
  }
  
  /// Get color with opacity
  Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Create a text style with custom color
  TextStyle textStyleWithColor(TextStyle baseStyle, Color color) {
    return baseStyle.copyWith(color: color);
  }
  
  /// Create a text style with custom size
  TextStyle textStyleWithSize(TextStyle baseStyle, double fontSize) {
    return baseStyle.copyWith(fontSize: fontSize);
  }
  
  /// Create a text style with custom weight
  TextStyle textStyleWithWeight(TextStyle baseStyle, FontWeight fontWeight) {
    return baseStyle.copyWith(fontWeight: fontWeight);
  }
}

/// Color Scheme Extensions for additional color utilities
extension ColorSchemeExtensions on ColorScheme {
  
  /// Get a disabled version of primary color
  Color get primaryDisabled => primary.withOpacity(0.38);
  
  /// Get a hover version of primary color
  Color get primaryHover => primary.withOpacity(0.08);
  
  /// Get a pressed version of primary color
  Color get primaryPressed => primary.withOpacity(0.12);
  
  /// Get a focus version of primary color
  Color get primaryFocus => primary.withOpacity(0.12);
  
  /// Get surface tint (for elevated surfaces)
  Color get surfaceTint => primary;
  
  /// Get container colors for different states
  Color get successContainer => AppColors.success.withOpacity(0.12);
  Color get warningContainer => AppColors.warning.withOpacity(0.12);
  Color get infoContainer => tertiary.withOpacity(0.12);
}

/// Text Theme Extensions for additional text utilities
extension TextThemeExtensions on TextTheme {
  
  /// Get caption style (deprecated in Material 3, but useful for migration)
  TextStyle get caption => labelMedium!;
  
  /// Get overline style (deprecated in Material 3, but useful for migration)
  TextStyle get overline => labelSmall!;
  
  /// Get subtitle1 style (deprecated in Material 3, but useful for migration)
  TextStyle get subtitle1 => titleMedium!;
  
  /// Get subtitle2 style (deprecated in Material 3, but useful for migration)
  TextStyle get subtitle2 => titleSmall!;
  
  /// Get headline6 style (deprecated in Material 3, but useful for migration)
  TextStyle get headline6 => titleLarge!;
  
  /// Get headline5 style (deprecated in Material 3, but useful for migration)
  TextStyle get headline5 => headlineSmall!;
  
  /// Get headline4 style (deprecated in Material 3, but useful for migration)
  TextStyle get headline4 => headlineMedium!;
  
  /// Get bodyText1 style (deprecated in Material 3, but useful for migration)
  TextStyle get bodyText1 => bodyLarge!;
  
  /// Get bodyText2 style (deprecated in Material 3, but useful for migration)
  TextStyle get bodyText2 => bodyMedium!;
}

/// Widget Extensions for theme-aware styling
extension WidgetExtensions on Widget {
  
  /// Wrap widget with theme-aware container
  Widget withThemeContainer(BuildContext context, {
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    Color? backgroundColor,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        border: border,
        boxShadow: boxShadow,
      ),
      child: this,
    );
  }
  
  /// Wrap widget with theme-aware card
  Widget withThemeCard(BuildContext context, {
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? elevation,
  }) {
    return Card(
      margin: margin,
      elevation: elevation,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: this,
      ),
    );
  }
}

/// Common theme-aware widgets
class ThemeAwareWidgets {
  
  /// Create a theme-aware divider
  static Widget divider(BuildContext context, {
    double? thickness,
    double? indent,
    double? endIndent,
  }) {
    return Divider(
      color: context.outlineVariant,
      thickness: thickness ?? 1,
      indent: indent,
      endIndent: endIndent,
    );
  }
  
  /// Create a theme-aware vertical divider
  static Widget verticalDivider(BuildContext context, {
    double? thickness,
    double? indent,
    double? endIndent,
  }) {
    return VerticalDivider(
      color: context.outlineVariant,
      thickness: thickness ?? 1,
      indent: indent,
      endIndent: endIndent,
    );
  }
  
  /// Create a theme-aware loading indicator
  static Widget loadingIndicator(BuildContext context, {
    double? size,
    Color? color,
  }) {
    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        color: color ?? context.primaryColor,
        strokeWidth: 2,
      ),
    );
  }
  
  /// Create a theme-aware icon button
  static Widget iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double? size,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: color ?? context.onSurfaceColor,
        size: size ?? 24,
      ),
      tooltip: tooltip,
    );
  }
}

