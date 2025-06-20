// lib/core/constants/app_constants.dart
class AppConstants {
  // Development settings
  static const bool isDevelopment = true; // Set to false for production
  
  // Rate limiting settings
  static const Duration otpCooldownDuration = Duration(minutes: 1);
  static const Duration tooManyRequestsCooldown = Duration(minutes: 15);
  
  // Bypass settings for development (REMOVE IN PRODUCTION)
  static const List<String> testPhoneNumbers = [
    '+919063290012', // Your test number
    '+911234567890', // Additional test numbers
  ];
  
  // Firebase settings
  static const int maxOtpRetries = 3;
  static const Duration otpTimeout = Duration(seconds: 60);
  
  // App Info
  static const String appName = 'Cloud Ironing';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Cloud Ironing Factory';
  
  // ===============================
  // DESIGN SYSTEM COLORS (Hex Values)
  // ===============================
  
  // Primary Colors
  static const int primaryColorValue = 0xFF0F3057;      // Deep Navy Blue
  static const int primaryLightColorValue = 0xFF1A4570; // Light Navy
  static const int primaryDarkColorValue = 0xFF081B3A;  // Dark Navy
  
  // Secondary Colors
  static const int secondaryColorValue = 0xFF88C1E3;      // Light Blue
  static const int secondaryLightColorValue = 0xFFA3D1E9; // Lighter Blue
  static const int secondaryDarkColorValue = 0xFF6BA8D3;  // Darker Blue
  
  // Accent Colors
  static const int accentColorValue = 0xFF00A8E8;      // Bright Azure
  static const int accentLightColorValue = 0xFF33BAEA; // Light Azure
  static const int accentDarkColorValue = 0xFF0088C1;  // Dark Azure
  
  // Semantic Colors
  static const int successColorValue = 0xFF5CB8B2;   // Fresh Teal
  static const int errorColorValue = 0xFFFF6B6B;     // Soft Coral
  static const int warningColorValue = 0xFFFFA726;   // Warning Amber
  static const int infoColorValue = 0xFF00A8E8;      // Same as accent
  
  // Neutral Colors
  static const int whiteColorValue = 0xFFFFFFFF;     // White
  static const int lightGrayColorValue = 0xFFF5F7FA; // Light Gray
  static const int mediumGrayColorValue = 0xFFD9E2EC; // Medium Gray
  static const int darkGrayColorValue = 0xFF3B4D61;  // Dark Gray
  static const int warmGrayColorValue = 0xFF6E7A8A;  // Warm Gray
  
  // Text Colors
  static const int textPrimaryValue = 0xFF0F3057;    // Deep Navy Blue (same as primary)
  static const int textSecondaryValue = 0xFF3B4D61;  // Dark Gray
  static const int textTertiaryValue = 0xFF6E7A8A;   // Warm Gray
  
  // ===============================
  // SPACING & LAYOUT
  // ===============================
  
  // Spacing (aligned with design system)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius (aligned with design system)
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 20.0;
  
  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;
  
  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;
  
  // ===============================
  // ANIMATION DURATIONS
  // ===============================
  
  static const int animationFast = 100;
  static const int animationMedium = 200;
  static const int animationSlow = 300;
  static const int animationVerySlow = 500;
  
  // Legacy support (deprecated - use AppDurations instead)
  static const int animationShort = animationFast;
  static const int animationLong = animationSlow;
  
  // ===============================
  // BUSINESS LOGIC
  // ===============================
  
  // Delivery
  static const double freeDeliveryMinAmount = 500.0;
  static const double baseDeliveryCharge = 50.0;
  static const double expressDeliveryCharge = 100.0;
  
  // Contact
  static const String supportPhone = '+91 9876543210';
  static const String supportEmail = 'support@cloudironing.com';
  static const String companyAddress = 'Nellore, Andhra Pradesh, India';
  
  // ===============================
  // RESPONSIVE BREAKPOINTS
  // ===============================
  
  static const double mobileBreakpoint = 480.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  
  // ===============================
  // UTILITY METHODS
  // ===============================
  
  /// Check if the app is in development mode
  static bool get isDebugMode => isDevelopment;
  
  /// Get app display name
  static String get displayName => appName;
  
  /// Get full app version string
  static String get fullVersion => '$appName v$appVersion';
  
  /// Check if phone number is a test number
  static bool isTestPhoneNumber(String phoneNumber) {
    return testPhoneNumbers.contains(phoneNumber);
  }
}
