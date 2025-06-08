// lib/core/utils/text_utils.dart
import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import '../constants/font_constants.dart';

// Extension for easy text styling
extension TextStyleExtension on String {
  Text get displayLarge => Text(this, style: AppTypography.displayLarge);
  Text get displayMedium => Text(this, style: AppTypography.displayMedium);
  Text get displaySmall => Text(this, style: AppTypography.displaySmall);

  Text get headlineLarge => Text(this, style: AppTypography.headlineLarge);
  Text get headlineMedium => Text(this, style: AppTypography.headlineMedium);
  Text get headlineSmall => Text(this, style: AppTypography.headlineSmall);

  Text get titleLarge => Text(this, style: AppTypography.titleLarge);
  Text get titleMedium => Text(this, style: AppTypography.titleMedium);
  Text get titleSmall => Text(this, style: AppTypography.titleSmall);

  Text get bodyLarge => Text(this, style: AppTypography.bodyLarge);
  Text get bodyMedium => Text(this, style: AppTypography.bodyMedium);
  Text get bodySmall => Text(this, style: AppTypography.bodySmall);

  Text get labelLarge => Text(this, style: AppTypography.labelLarge);
  Text get labelMedium => Text(this, style: AppTypography.labelMedium);
  Text get labelSmall => Text(this, style: AppTypography.labelSmall);

  Text get button => Text(this, style: AppTypography.button);
  Text get caption => Text(this, style: AppTypography.caption);

  // With custom colors
  Text primary([Color? color]) => Text(
    this,
    style: AppTypography.bodyMedium.copyWith(
      color: color ?? const Color(0xFF4299E1),
    ),
  );

  Text secondary([Color? color]) => Text(
    this,
    style: AppTypography.bodyMedium.copyWith(
      color: color ?? const Color(0xFF4A5568),
    ),
  );

  Text muted([Color? color]) => Text(
    this,
    style: AppTypography.bodyMedium.copyWith(
      color: color ?? const Color(0xFF718096),
    ),
  );

  Text error([Color? color]) => Text(
    this,
    style: AppTypography.bodyMedium.copyWith(
      color: color ?? const Color(0xFFEF4444),
    ),
  );

  Text success([Color? color]) => Text(
    this,
    style: AppTypography.bodyMedium.copyWith(
      color: color ?? const Color(0xFF38A169),
    ),
  );
}

// Custom Text widgets for common use cases
class AppText {
  // Headings
  static Widget h1(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.displayLarge.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  static Widget h2(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.displayMedium.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  static Widget h3(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.displaySmall.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  static Widget h4(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.headlineLarge.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  static Widget h5(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.headlineMedium.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  static Widget h6(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.headlineSmall.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  // Body text
  static Widget body(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  static Widget bodyLarge(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.bodyLarge.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  static Widget bodySmall(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  // Special text
  static Widget caption(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  static Widget label(String text, {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(color: color),
      textAlign: textAlign,
    );
  }

  // Branded text styles for your app
  static Widget appTitle(String text, {Color? color}) {
    return Text(
      text,
      style: AppTypography.headlineLarge.copyWith(
        color: color ?? const Color(0xFF0F3057),
        fontSize: 26,
        fontWeight: FontConstants.bold,
        letterSpacing: -0.2,
      ),
    );
  }

  static Widget welcomeTitle(String text, {Color? color}) {
    return Text(
      text,
      style: AppTypography.displayMedium.copyWith(
        color: color ?? const Color(0xFF0F3057),
        fontWeight: FontConstants.bold,
        letterSpacing: -0.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  static Widget buttonText(String text, {Color? color}) {
    return Text(text, style: AppTypography.button.copyWith(color: color));
  }

  static Widget subtitle(String text, {Color? color}) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        color: color ?? const Color(0xFF6E7A8A),
        fontWeight: FontConstants.regular,
      ),
      textAlign: TextAlign.center,
    );
  }

  static Widget fieldLabel(String text, {Color? color}) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: color ?? const Color(0xFF4A5568),
        fontWeight: FontConstants.medium,
      ),
    );
  }

  static Widget errorText(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: const Color(0xFFEF4444),
        fontWeight: FontConstants.regular,
      ),
    );
  }

  static Widget successText(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: const Color(0xFF38A169),
        fontWeight: FontConstants.medium,
      ),
    );
  }
}
