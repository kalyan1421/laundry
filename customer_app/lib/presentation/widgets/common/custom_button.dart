// lib/widgets/common/custom_button.dart
import 'package:flutter/material.dart' hide TextButton, IconButton;
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final IconData? icon;
  final IconData? suffixIcon;
  final double? iconSize;
  final double? iconSpacing;
  final TextStyle? textStyle;
  final double? elevation;
  final Widget? child;
  final ButtonStyle? style;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.width,
    this.height = 50,
    this.padding,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.icon,
    this.suffixIcon,
    this.iconSize,
    this.iconSpacing,
    this.textStyle,
    this.elevation,
    this.child,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isButtonDisabled = isDisabled || onPressed == null || isLoading;
    
    // Default colors from theme
    final Color defaultBackgroundColor = backgroundColor ?? theme.colorScheme.primary;
    final Color defaultTextColor = textColor ?? theme.colorScheme.onPrimary;
    final Color defaultDisabledBgColor = disabledBackgroundColor ?? AppColors.disabled;
    final Color defaultDisabledTextColor = disabledTextColor ?? AppColors.textDisabled;
    
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        boxShadow: boxShadow,
        border: border,
      ),
      child: ElevatedButton(
        onPressed: isButtonDisabled ? null : onPressed,
        style: style ?? ElevatedButton.styleFrom(
          backgroundColor: isButtonDisabled 
              ? defaultDisabledBgColor 
              : defaultBackgroundColor,
          foregroundColor: isButtonDisabled 
              ? defaultDisabledTextColor 
              : defaultTextColor,
          disabledBackgroundColor: defaultDisabledBgColor,
          disabledForegroundColor: defaultDisabledTextColor,
          elevation: elevation ?? 0,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textStyle ?? AppTextTheme.buttonText,
        ),
        child: child ?? _buildButtonContent(
          isButtonDisabled ? defaultDisabledTextColor : defaultTextColor,
        ),
      ),
    );
  }

  Widget _buildButtonContent(Color color) {
    if (isLoading) {
      return _buildLoadingContent(color);
    }

    if (icon != null && suffixIcon != null) {
      return _buildIconTextSuffixContent(color);
    }

    if (icon != null) {
      return _buildIconTextContent(color);
    }

    if (suffixIcon != null) {
      return _buildTextSuffixContent(color);
    }

    return _buildTextContent(color);
  }

  Widget _buildLoadingContent(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (text.isNotEmpty) ...[
          SizedBox(width: iconSpacing ?? 8),
          Text(
            text,
            style: TextStyle(color: color),
          ),
        ],
      ],
    );
  }

  Widget _buildIconTextContent(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize ?? 20,
          color: color,
        ),
        if (text.isNotEmpty) ...[
          SizedBox(width: iconSpacing ?? 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextSuffixContent(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (text.isNotEmpty) ...[
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: iconSpacing ?? 8),
        ],
        Icon(
          suffixIcon,
          size: iconSize ?? 20,
          color: color,
        ),
      ],
    );
  }

  Widget _buildIconTextSuffixContent(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize ?? 20,
          color: color,
        ),
        if (text.isNotEmpty) ...[
          SizedBox(width: iconSpacing ?? 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: iconSpacing ?? 8),
        ],
        Icon(
          suffixIcon,
          size: iconSize ?? 20,
          color: color,
        ),
      ],
    );
  }

  Widget _buildTextContent(Color color) {
    return Text(
      text,
      style: TextStyle(color: color),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Predefined button variants for common use cases
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? child;
  final IconData? icon;
  final double? width;
  final double? height;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.child,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: theme.colorScheme.primary,
      textColor: theme.colorScheme.onPrimary,
      width: width,
      height: height ?? 50,
      icon: icon,
      child: child,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? child;
  final IconData? icon;
  final double? width;
  final double? height;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.child,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: theme.colorScheme.surface,
      textColor: theme.colorScheme.primary,
      border: Border.all(color: theme.colorScheme.primary),
      width: width,
      height: height ?? 50,
      icon: icon,
      child: child,
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? borderColor;
  final Color? textColor;
  final Widget? child;
  final IconData? icon;
  final double? width;
  final double? height;

  const OutlineButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.borderColor,
    this.textColor,
    this.child,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color defaultBorderColor = borderColor ?? theme.colorScheme.tertiary;
    final Color defaultTextColor = textColor ?? theme.colorScheme.tertiary;

    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: Colors.transparent,
      textColor: defaultTextColor,
      border: Border.all(color: defaultBorderColor),
      width: width,
      height: height ?? 50,
      icon: icon,
      child: child,
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? child;
  final IconData? icon;
  final double? width;
  final double? height;

  const DangerButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.child,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: theme.colorScheme.error,
      textColor: theme.colorScheme.onError,
      width: width,
      height: height ?? 50,
      icon: icon,
      child: child,
    );
  }
}

class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? child;
  final IconData? icon;
  final double? width;
  final double? height;

  const SuccessButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.child,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: AppColors.success,
      textColor: AppColors.textOnSuccess,
      width: width,
      height: height ?? 50,
      icon: icon,
      child: child,
    );
  }
}

// Custom TextButton to avoid conflict with Flutter's TextButton
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? textColor;
  final Widget? child;
  final IconData? icon;
  final double? width;
  final double? height;

  const AppTextButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.textColor,
    this.child,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: Colors.transparent,
      textColor: textColor ?? theme.colorScheme.primary,
      elevation: 0,
      width: width,
      height: height ?? 40,
      icon: icon,
      child: child,
    );
  }
}

class FloatingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Widget? child;
  final IconData? icon;
  final double? width;
  final double? height;

  const FloatingButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.child,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      textColor: theme.colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(25),
      elevation: 4,
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      width: width,
      height: height ?? 50,
      icon: icon,
      child: child,
    );
  }
}

// Custom IconButton to avoid conflict with Flutter's IconButton
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final BorderRadius? borderRadius;

  const AppIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double buttonSize = size ?? 48;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return CustomButton(
      text: '',
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      backgroundColor: backgroundColor ?? colors.surfaceVariant,
      textColor: iconColor ?? colors.onSurface, // ensures spinner/text contrast if needed
      width: buttonSize,
      height: buttonSize,
      borderRadius: borderRadius ?? BorderRadius.circular(buttonSize / 2),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  iconColor ?? colors.onSurface,
                ),
              ),
            )
          : Icon(
              icon,
              size: iconSize ?? 24,
              color: iconColor ?? colors.onSurface,
            ),
    );
  }
}