import 'package:flutter/material.dart';

/// Comprehensive Design System Spacing & Layout
/// Based on Cloud Ironing App Design Guidelines
class AppSpacing {
  // ===============================
  // SPACING CONSTANTS
  // ===============================

  /// Extra small spacing - 4px
  static const double xs = 4.0;
  
  /// Small spacing - 8px
  static const double s = 8.0;
  
  /// Medium spacing - 16px
  static const double m = 16.0;
  
  /// Large spacing - 24px
  static const double l = 24.0;
  
  /// Extra large spacing - 32px
  static const double xl = 32.0;
  
  /// Extra extra large spacing - 48px
  static const double xxl = 48.0;

  // ===============================
  // PADDING CONSTANTS
  // ===============================

  /// Extra small padding
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  
  /// Small padding
  static const EdgeInsets paddingS = EdgeInsets.all(s);
  
  /// Medium padding
  static const EdgeInsets paddingM = EdgeInsets.all(m);
  
  /// Large padding
  static const EdgeInsets paddingL = EdgeInsets.all(l);
  
  /// Extra large padding
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: s);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: l);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: s);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: m);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: l);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(vertical: xl);

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(m);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: m);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(m);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(s);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(l);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: m,
    vertical: s,
  );

  // Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: l,
    vertical: m,
  );

  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: m,
    vertical: s,
  );

  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: l,
  );

  // ===============================
  // BORDER RADIUS CONSTANTS
  // ===============================

  /// Small border radius - 8px
  static const double radiusS = 8.0;
  
  /// Medium border radius - 12px
  static const double radiusM = 12.0;
  
  /// Large border radius - 16px
  static const double radiusL = 16.0;
  
  /// Extra large border radius - 20px
  static const double radiusXL = 20.0;
  
  /// Circular border radius - 999px
  static const double radiusCircular = 999.0;

  // BorderRadius objects
  static const BorderRadius borderRadiusS = BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius borderRadiusM = BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius borderRadiusL = BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusCircular = BorderRadius.all(Radius.circular(radiusCircular));

  // Top border radius
  static const BorderRadius borderRadiusTopS = BorderRadius.vertical(top: Radius.circular(radiusS));
  static const BorderRadius borderRadiusTopM = BorderRadius.vertical(top: Radius.circular(radiusM));
  static const BorderRadius borderRadiusTopL = BorderRadius.vertical(top: Radius.circular(radiusL));
  static const BorderRadius borderRadiusTopXL = BorderRadius.vertical(top: Radius.circular(radiusXL));

  // Bottom border radius
  static const BorderRadius borderRadiusBottomS = BorderRadius.vertical(bottom: Radius.circular(radiusS));
  static const BorderRadius borderRadiusBottomM = BorderRadius.vertical(bottom: Radius.circular(radiusM));
  static const BorderRadius borderRadiusBottomL = BorderRadius.vertical(bottom: Radius.circular(radiusL));
  static const BorderRadius borderRadiusBottomXL = BorderRadius.vertical(bottom: Radius.circular(radiusXL));

  // ===============================
  // ELEVATION CONSTANTS
  // ===============================

  /// No elevation
  static const double elevationNone = 0.0;
  
  /// Small elevation
  static const double elevationS = 2.0;
  
  /// Medium elevation
  static const double elevationM = 4.0;
  
  /// Large elevation
  static const double elevationL = 8.0;
  
  /// Extra large elevation
  static const double elevationXL = 16.0;

  // ===============================
  // ICON SIZE CONSTANTS
  // ===============================

  /// Small icon - 16px
  static const double iconS = 16.0;
  
  /// Medium icon - 20px
  static const double iconM = 20.0;
  
  /// Large icon - 24px
  static const double iconL = 24.0;
  
  /// Extra large icon - 32px
  static const double iconXL = 32.0;
  
  /// Extra extra large icon - 48px
  static const double iconXXL = 48.0;

  // ===============================
  // LAYOUT DIMENSIONS
  // ===============================

  /// App bar height
  static const double appBarHeight = 56.0;
  
  /// Bottom navigation bar height
  static const double bottomNavHeight = 56.0;
  
  /// Tab bar height
  static const double tabBarHeight = 48.0;
  
  /// Floating action button size
  static const double fabSize = 56.0;
  
  /// Mini floating action button size
  static const double fabMiniSize = 40.0;

  // Button heights
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Input field heights
  static const double inputHeightSmall = 40.0;
  static const double inputHeightMedium = 48.0;
  static const double inputHeightLarge = 56.0;

  // Card dimensions
  static const double cardMinHeight = 120.0;
  static const double cardMaxWidth = 400.0;

  // List item heights
  static const double listItemHeightSmall = 48.0;
  static const double listItemHeightMedium = 56.0;
  static const double listItemHeightLarge = 72.0;

  // ===============================
  // BREAKPOINTS (Responsive Design)
  // ===============================

  /// Mobile breakpoint
  static const double mobile = 480.0;
  
  /// Tablet breakpoint
  static const double tablet = 768.0;
  
  /// Desktop breakpoint
  static const double desktop = 1024.0;
  
  /// Large desktop breakpoint
  static const double largeDesktop = 1440.0;

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth < mobile) {
      return paddingM;
    } else if (screenWidth < tablet) {
      return paddingL;
    } else {
      return paddingXL;
    }
  }

  /// Get responsive border radius based on screen width
  static BorderRadius getResponsiveBorderRadius(double screenWidth) {
    if (screenWidth < mobile) {
      return borderRadiusM;
    } else if (screenWidth < tablet) {
      return borderRadiusL;
    } else {
      return borderRadiusXL;
    }
  }

  /// Check if screen is mobile
  static bool isMobile(double screenWidth) => screenWidth < mobile;
  
  /// Check if screen is tablet
  static bool isTablet(double screenWidth) => screenWidth >= mobile && screenWidth < desktop;
  
  /// Check if screen is desktop
  static bool isDesktop(double screenWidth) => screenWidth >= desktop;

  /// Get appropriate column count for grid based on screen width
  static int getGridColumnCount(double screenWidth) {
    if (screenWidth < mobile) {
      return 1;
    } else if (screenWidth < tablet) {
      return 2;
    } else if (screenWidth < desktop) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get appropriate font size scaling based on screen width
  static double getFontSizeScale(double screenWidth) {
    if (screenWidth < mobile) {
      return 0.9;
    } else if (screenWidth < tablet) {
      return 1.0;
    } else {
      return 1.1;
    }
  }
}

/// Animation Duration Constants
class AppDurations {
  /// Very fast animation - 100ms
  static const Duration fast = Duration(milliseconds: 100);
  
  /// Medium animation - 200ms
  static const Duration medium = Duration(milliseconds: 200);
  
  /// Slow animation - 300ms
  static const Duration slow = Duration(milliseconds: 300);
  
  /// Very slow animation - 500ms
  static const Duration verySlow = Duration(milliseconds: 500);

  /// Page transition duration
  static const Duration pageTransition = Duration(milliseconds: 250);
  
  /// Dialog animation duration
  static const Duration dialog = Duration(milliseconds: 200);
  
  /// Snackbar duration
  static const Duration snackbar = Duration(seconds: 3);
  
  /// Tooltip duration
  static const Duration tooltip = Duration(seconds: 2);
}

/// Animation Curve Constants
class AppCurves {
  /// Standard ease curve
  static const Curve ease = Curves.ease;
  
  /// Ease in curve
  static const Curve easeIn = Curves.easeIn;
  
  /// Ease out curve
  static const Curve easeOut = Curves.easeOut;
  
  /// Ease in-out curve
  static const Curve easeInOut = Curves.easeInOut;
  
  /// Bounce curve
  static const Curve bounce = Curves.bounceOut;
  
  /// Elastic curve
  static const Curve elastic = Curves.elasticOut;
} 