import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

/// Responsive section wrapper for consistent layout across the app
class ResponsiveSection extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final bool centerContent;
  final double? maxWidth;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveSection({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.centerContent = true,
    this.maxWidth,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Wrap in responsive container if centerContent is true
    if (centerContent) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? ResponsiveHelper.getResponsiveWidth(context),
          ),
          child: content,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
      margin: margin,
      color: backgroundColor,
      child: content,
    );
  }
}

/// Responsive row that automatically wraps to column on mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool forceColumn;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16.0,
    this.forceColumn = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shouldUseColumn = forceColumn || ResponsiveHelper.isMobile(context);

    if (shouldUseColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, isColumn: true),
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, isColumn: false),
      );
    }
  }

  List<Widget> _addSpacing(List<Widget> widgets, {required bool isColumn}) {
    if (widgets.isEmpty) return widgets;

    final List<Widget> spacedWidgets = [];
    for (int i = 0; i < widgets.length; i++) {
      spacedWidgets.add(widgets[i]);
      if (i < widgets.length - 1) {
        spacedWidgets.add(
          isColumn 
            ? SizedBox(height: spacing)
            : SizedBox(width: spacing),
        );
      }
    }
    return spacedWidgets;
  }
}

/// Responsive grid that adjusts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columnCount = ResponsiveHelper.getGridColumnCount(
      context,
      mobileColumns: mobileColumns,
      tabletColumns: tabletColumns,
      desktopColumns: desktopColumns,
    );

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 
                 (spacing * (columnCount - 1))) / columnCount,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Responsive image that scales properly across devices
class ResponsiveImage extends StatelessWidget {
  final String imagePath;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final BoxFit fit;
  final Widget? errorWidget;

  const ResponsiveImage({
    Key? key,
    required this.imagePath,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.fit = BoxFit.cover,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveValue(
      context,
      mobile: mobileHeight ?? 200.0,
      tablet: tabletHeight ?? 300.0,
      desktop: desktopHeight ?? 400.0,
    );

    return SizedBox(
      height: height,
      child: Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? Container(
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      ),
    );
  }
}

/// Responsive card with consistent styling
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? ResponsiveHelper.getResponsiveValue(
        context,
        mobile: 2.0,
        tablet: 4.0,
        desktop: 6.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(
          ResponsiveHelper.getResponsiveValue(
            context,
            mobile: 8.0,
            tablet: 12.0,
            desktop: 16.0,
          ),
        ),
      ),
      color: backgroundColor,
      margin: margin ?? ResponsiveHelper.getResponsiveMargin(context),
      child: Padding(
        padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
        child: child,
      ),
    );
  }
} 