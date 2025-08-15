import 'package:flutter/material.dart';

/// Comprehensive Design System Color Palette
/// Based on Cloud Ironing App Design Guidelines
class AppColors {
  // ===============================
  // BRAND COLORS
  // ===============================
  
  /// Primary: Deep Navy Blue - Main actions, headers, key UI elements
  static const Color primary = Color(0xFF0F3057);
  static const Color primaryLight = Color(0xFF1A4570);
  static const Color primaryDark = Color(0xFF081B3A);
  
  /// Secondary: Light Blue - Supporting elements, backgrounds, selection states
  static const Color secondary = Color(0xFF88C1E3);
  static const Color secondaryLight = Color(0xFFA3D1E9);
  static const Color secondaryDark = Color(0xFF6BA8D3);
  
  /// Accent: Bright Azure - Call-to-action elements, highlight indicators
  static const Color accent = Color(0xFF00A8E8);
  static const Color accentLight = Color(0xFF33BAEA);
  static const Color accentDark = Color(0xFF0088C1);

  // ===============================
  // SEMANTIC COLORS
  // ===============================
  
  /// Success: Fresh Teal - Completion states, success indicators
  static const Color success = Color(0xFF5CB8B2);
  static const Color successLight = Color(0xFF7DC7C2);
  static const Color successDark = Color(0xFF47A199);
  
  /// Alert/Warning: Soft Coral - Error states, alerts, critical actions
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorLight = Color(0xFFFF8888);
  static const Color errorDark = Color(0xFFE55555);
  
  /// Warning: Warm amber for warnings
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFFF9800);
  
  /// Info: Same as accent for consistency
  static const Color info = accent;

  // ===============================
  // NEUTRAL COLORS
  // ===============================
  
  /// White - Backgrounds, cards
  static const Color white = Color(0xFFFFFFFF);
  
  /// Light Gray - Secondary backgrounds, inactive states
  static const Color lightGray = Color(0xFFF5F7FA);
  
  /// Medium Gray - Borders, dividers
  static const Color mediumGray = Color(0xFFD9E2EC);
  
  /// Dark Gray - Primary text
  static const Color darkGray = Color(0xFF3B4D61);
  
  /// Warm Gray - Secondary text
  static const Color warmGray = Color(0xFF6E7A8A);

  // ===============================
  // TEXT COLORS
  // ===============================
  
  /// Primary text color (Deep Navy Blue for headings)
  static const Color textPrimary = primary;
  
  /// Secondary text color (Dark Gray for body text)
  static const Color textSecondary = darkGray;
  
  /// Tertiary text color (Warm Gray for captions)
  static const Color textTertiary = warmGray;
  
  /// Text on primary background
  static const Color textOnPrimary = white;
  
  /// Text on secondary background
  static const Color textOnSecondary = primary;
  
  /// Text on accent background
  static const Color textOnAccent = white;
  
  /// Text on success background
  static const Color textOnSuccess = white;
  
  /// Text on error background
  static const Color textOnError = white;
  
  /// Hint text color
  static const Color textHint = warmGray;
  
  /// Disabled text color
  static const Color textDisabled = mediumGray;

  // ===============================
  // BACKGROUND COLORS
  // ===============================
  
  /// Main background color
  static const Color background = white;
  
  /// Secondary background color
  static const Color backgroundSecondary = lightGray;
  
  /// Surface color for cards, dialogs, etc.
  static const Color surface = white;
  
  /// Surface variant for elevated elements
  static const Color surfaceVariant = lightGray;

  // ===============================
  // BORDER & DIVIDER COLORS
  // ===============================
  
  /// Standard border color
  static const Color border = mediumGray;
  
  /// Light border color
  static const Color borderLight = lightGray;
  
  /// Divider color
  static const Color divider = mediumGray;
  
  /// Focus border color
  static const Color borderFocus = accent;

  // ===============================
  // STATE COLORS
  // ===============================
  
  /// Selected state color
  static const Color selected = accent;
  
  /// Pressed state color
  static const Color pressed = primaryDark;
  
  /// Hover state color
  static const Color hover = primaryLight;
  
  /// Disabled state color
  static const Color disabled = mediumGray;
  
  /// Active state color
  static const Color active = accent;
  
  /// Inactive state color
  static const Color inactive = warmGray;

  // ===============================
  // OVERLAY COLORS
  // ===============================
  
  /// Backdrop overlay
  static const Color backdrop = Color(0x80000000);
  
  /// Modal overlay
  static const Color modalOverlay = Color(0x4D000000);
  
  /// Scrim color
  static const Color scrim = Color(0x66000000);

  // ===============================
  // GRADIENT COLORS
  // ===============================
  
  /// Primary gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Secondary gradient
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Accent gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===============================
  // ANT DESIGN DARK THEME TOKENS (for dark mode)
  // ===============================
  
  /// Ant Design dark background colors
  static const Color adDarkBackground = Color(0xFF141414); // base background
  static const Color adDarkSurface = Color(0xFF1F1F1F); // containers/cards
  static const Color adDarkSurfaceSecondary = Color(0xFF262626);
  
  /// Ant Design dark text colors (using alpha on white)
  static const Color adTextPrimary = Color(0xD9FFFFFF); // 85% white
  static const Color adTextSecondary = Color(0xA6FFFFFF); // 65% white
  static const Color adTextDisabled = Color(0x40FFFFFF); // 25% white
  
  /// Ant Design dark border/divider colors
  static const Color adBorder = Color(0x26FFFFFF); // 15% white
  static const Color adDivider = Color(0x1FFFFFFF); // 12% white
  
  // ===============================
  // UTILITY METHODS
  // ===============================
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Check if color is light
  static bool isLight(Color color) {
    return color.computeLuminance() > 0.5;
  }
  
  /// Get contrasting text color
  static Color getContrastingTextColor(Color backgroundColor) {
    return isLight(backgroundColor) ? textPrimary : white;
  }
} 
