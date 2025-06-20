import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Responsive helper class for consistent breakpoints and sizing
class ResponsiveHelper {
  // Breakpoint constants
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  
  /// Get current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }
  
  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  /// Get responsive width based on percentage
  static double getResponsiveWidth(BuildContext context, {
    double mobilePercent = 0.9,
    double tabletPercent = 0.8,
    double desktopMaxWidth = 1200,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile(context)) {
      return screenWidth * mobilePercent;
    } else if (isTablet(context)) {
      return screenWidth * tabletPercent;
    } else {
      return desktopMaxWidth.clamp(0, screenWidth * 0.9);
    }
  }
  
  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, {
    required double mobileSize,
    required double tabletSize,
    required double desktopSize,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize;
    return desktopSize;
  }
  
  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isMobile(context)) return mobile ?? const EdgeInsets.all(16);
    if (isTablet(context)) return tablet ?? const EdgeInsets.all(24);
    return desktop ?? const EdgeInsets.all(32);
  }
  
  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isMobile(context)) return mobile ?? const EdgeInsets.all(8);
    if (isTablet(context)) return tablet ?? const EdgeInsets.all(16);
    return desktop ?? const EdgeInsets.all(20);
  }
  
  /// Get responsive value based on device type
  static T getResponsiveValue<T>(BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }
  
  /// Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(BuildContext context, {
    double? maxWidth,
  }) {
    final responsiveMaxWidth = maxWidth ?? getResponsiveWidth(context);
    
    return BoxConstraints(
      maxWidth: responsiveMaxWidth,
      minWidth: 0,
    );
  }
  
  /// Get responsive grid column count
  static int getGridColumnCount(BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
  }) {
    if (isMobile(context)) return mobileColumns;
    if (isTablet(context)) return tabletColumns;
    return desktopColumns;
  }
}

/// Device type enumeration
enum DeviceType { mobile, tablet, desktop }

/// Responsive widget that builds different layouts based on screen size
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  
  const ResponsiveWidget({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return mobile;
    } else if (ResponsiveHelper.isTablet(context)) {
      return tablet ?? desktop;
    } else {
      return desktop;
    }
  }
}

/// Responsive text widget with automatic sizing
class ResponsiveText extends StatelessWidget {
  final String text;
  final double mobileSize;
  final double tabletSize;
  final double desktopSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fontFamily;
  
  const ResponsiveText(
    this.text, {
    Key? key,
    required this.mobileSize,
    required this.tabletSize,
    required this.desktopSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontFamily,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(
          context,
          mobileSize: mobileSize,
          tabletSize: tabletSize,
          desktopSize: desktopSize,
        ),
        fontWeight: fontWeight,
        color: color ?? AppTheme.darkGray,
        fontFamily: fontFamily ?? AppTheme.primaryFont,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive container with automatic sizing
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileWidthPercent;
  final double? tabletWidthPercent;
  final double? desktopMaxWidth;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;
  
  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.mobileWidthPercent,
    this.tabletWidthPercent,
    this.desktopMaxWidth,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResponsiveHelper.getResponsiveWidth(
        context,
        mobilePercent: mobileWidthPercent ?? 0.9,
        tabletPercent: tabletWidthPercent ?? 0.8,
        desktopMaxWidth: desktopMaxWidth ?? 1200,
      ),
      padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
      margin: margin ?? ResponsiveHelper.getResponsiveMargin(context),
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
} 