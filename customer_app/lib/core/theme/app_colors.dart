import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF007BFF); // A vibrant blue
  static const Color primaryDark = Color(0xFF0056b3); // A darker shade of blue
  static const Color primaryLight = Color(0xFF3395FF); // A lighter shade of blue

  // Secondary Colors
  static const Color secondary = Color(0xFF6C757D); // A neutral grey
  static const Color secondaryDark = Color(0xFF495057); // Darker grey
  static const Color secondaryLight = Color(0xFFADB5BD); // Lighter grey

  // Accent Colors
  static const Color accent = Color(0xFF28A745); // A success green, can also be used as accent
  static const Color accentYellow = Color(0xFFFFC107); // A warning yellow
  static const Color accentRed = Color(0xFFDC3545); // An error red

  // Text Colors
  static const Color textPrimary = Color(0xFF212529); // Dark grey for primary text
  static const Color textSecondary = Color(0xFF6C757D); // Lighter grey for secondary text
  static const Color textOnPrimary = Colors.white; // Text color on primary background
  static const Color textOnSecondary = Colors.white; // Text color on secondary background
  static const Color textOnAccent = Colors.white; // Text color on accent background
  static const Color textLink = Color(0xFF007BFF); // Blue for links
  static const Color textSuccess = Color(0xFF28A745); // Green for success messages
  static const Color textWarning = Color(0xFFFFC107); // Yellow for warning messages
  static const Color textError = Color(0xFFDC3545); // Red for error messages
  static const Color textHint = Color(0xFFA0AEC0); // Hint text color (added back)

  // Background Colors
  static const Color background = Color(0xFFF8F9FA); // Very light grey for page backgrounds
  static const Color backgroundDark = Color(0xFFE9ECEF); // Slightly darker background
  static const Color surface = Colors.white; // For cards, dialogs, etc.

  // Border & Divider Colors
  static const Color border = Color(0xFFDEE2E6); // Light grey for borders
  static const Color divider = Color(0xFFE9ECEF); // Light grey for dividers

  // Status Colors (semantic colors)
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  // Extended Palette (Optional - if you need more shades)
  static const Color blueLight = Color(0xFFE0F2FE); // Example: Very light blue
  static const Color greenLight = Color(0xFFD4EDDA); // Example: Very light green
  static const Color redLight = Color(0xFFF8D7DA);   // Example: Very light red
  static const Color yellowLight = Color(0xFFFFF3CD);// Example: Very light yellow

  // Greyscale Palette
  static const Color greyDarkest = Color(0xFF343A40);
  static const Color greyDark = Color(0xFF495057);
  static const Color greyMedium = Color(0xFF6C757D);
  static const Color greyLight = Color(0xFFADB5BD);
  static const Color greyLightest = Color(0xFFF8F9FA);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Other Common Colors
  static const Color disabled = Color(0xFFBDBDBD);

  // You can add more specific colors as needed, e.g.:
  // static const Color googleButtonColor = Color(0xFFDB4437);
  // static const Color facebookButtonColor = Color(0xFF3B5998);
} 