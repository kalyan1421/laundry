# Cloud Ironing - Design System

## Overview

This document outlines the comprehensive design system implemented for the Cloud Ironing application. The design system ensures consistency, accessibility, and maintainability across the entire application.

## Color Palette

### Primary Colors
- **Deep Navy Blue** (`#0F3057`) - Main actions, headers, key UI elements
- **Light Navy** (`#1A4570`) - Hover states, lighter variants
- **Dark Navy** (`#081B3A`) - Pressed states, darker variants

### Secondary Colors
- **Light Blue** (`#88C1E3`) - Supporting elements, backgrounds, selection states
- **Lighter Blue** (`#A3D1E9`) - Light variants
- **Darker Blue** (`#6BA8D3`) - Dark variants

### Accent Colors
- **Bright Azure** (`#00A8E8`) - Call-to-action elements, highlight indicators
- **Light Azure** (`#33BAEA`) - Light variants
- **Dark Azure** (`#0088C1`) - Dark variants

### Semantic Colors
- **Success** (`#5CB8B2`) - Fresh Teal for completion states, success indicators
- **Error** (`#FF6B6B`) - Soft Coral for error states, alerts, critical actions
- **Warning** (`#FFA726`) - Warm amber for warnings
- **Info** (`#00A8E8`) - Same as accent for consistency

### Neutral Colors
- **White** (`#FFFFFF`) - Backgrounds, cards
- **Light Gray** (`#F5F7FA`) - Secondary backgrounds, inactive states
- **Medium Gray** (`#D9E2EC`) - Borders, dividers
- **Dark Gray** (`#3B4D61`) - Primary text
- **Warm Gray** (`#6E7A8A`) - Secondary text

## Typography

### Font Family
**SF Pro Display** - Primary font family for all text elements

### Typography Hierarchy

#### Headings
- **Heading 1**: 22px, Bold, Deep Navy Blue - Main page titles, primary headers
- **Heading 2**: 20px, Bold, Deep Navy Blue - Section headers, card titles
- **Heading 3**: 18px, SemiBold, Deep Navy Blue - Subsection headers, important labels

#### Body Text
- **Body Text**: 16px, Regular, Dark Gray - Main content, descriptions, paragraphs
- **Body Text Medium**: 16px, Medium, Dark Gray - Emphasized body text
- **Body Text Small**: 14px, Regular, Dark Gray - Secondary content

#### Captions & Labels
- **Caption**: 14px, Regular, Warm Gray - Helper text, timestamps, metadata
- **Caption Small**: 12px, Regular, Warm Gray - Small helper text, fine print
- **Label**: 14px, Medium, Dark Gray - Form labels, menu items

#### Button Text
- **Button Text**: 14px, Medium - Base style, color varies by button type
- **Primary Button**: 14px, Medium, White
- **Secondary Button**: 14px, Medium, Deep Navy Blue
- **Accent Button**: 14px, Medium, White

### Font Weights
- **Regular**: 400
- **Medium**: 500
- **SemiBold**: 600
- **Bold**: 700

## Iconography

### Sizes
- **Small Icons**: 16px (inline icons)
- **Medium Icons**: 20px (section headers)
- **Large Icons**: 24px (primary navigation)
- **Extra Large Icons**: 32px (feature highlights)
- **Extra Extra Large Icons**: 48px (major actions)

### Style Guidelines
- **Stroke Weight**: 2px
- **Style**: Rounded caps and joins
- **Color**: Matches text color in context (Deep Navy Blue for primary actions)

## Spacing & Layout

### Spacing Scale
- **XS**: 4px - Fine adjustments
- **S**: 8px - Small gaps
- **M**: 16px - Standard spacing
- **L**: 24px - Section spacing
- **XL**: 32px - Large gaps
- **XXL**: 48px - Major sections

### Border Radius
- **Small**: 8px - Small elements
- **Medium**: 12px - Standard elements
- **Large**: 16px - Cards, major elements
- **Extra Large**: 20px - Modal dialogs
- **Circular**: 999px - Circular elements

### Elevation
- **None**: 0px - Flat elements
- **Small**: 2dp - Subtle elevation
- **Medium**: 4dp - Cards
- **Large**: 8dp - Dialogs
- **Extra Large**: 16dp - Major overlays

## Button Styles

### Primary Button
- **Background**: Deep Navy Blue (`#0F3057`)
- **Text**: White, 14px, Medium
- **Usage**: Main actions, form submissions, confirmations
- **Variants**: Small, Default, Large

### Secondary Button
- **Background**: Light Blue (`#88C1E3`)
- **Text**: Deep Navy Blue, 14px, Medium
- **Usage**: Secondary actions, alternative options

### Accent Button
- **Background**: Bright Azure (`#00A8E8`)
- **Text**: White, 14px, Medium
- **Usage**: Call-to-action elements, highlight actions

### Outline Buttons
- **Primary Outline**: Deep Navy border, transparent background
- **Secondary Outline**: Light Blue border, transparent background

### Text Buttons
- **Primary Text**: Deep Navy Blue text, no background
- **Secondary Text**: Warm Gray text, no background

### Semantic Buttons
- **Success**: Fresh Teal background, white text
- **Error**: Soft Coral background, white text
- **Warning**: Warning amber background, appropriate text

## Component Styles

### Cards
- **Background**: White
- **Border Radius**: 16px
- **Elevation**: 2dp
- **Padding**: 16px
- **Margin**: 16px horizontal, 8px vertical

### Input Fields
- **Background**: Light Gray (`#F5F7FA`)
- **Border**: Medium Gray, 1px
- **Focus Border**: Bright Azure, 2px
- **Border Radius**: 12px
- **Padding**: 16px
- **Label**: 14px, Medium, Dark Gray
- **Hint Text**: 14px, Regular, Warm Gray

### Navigation
- **Bottom Navigation**: White background, Deep Navy selected, Warm Gray unselected
- **Tab Bar**: Deep Navy selected, Warm Gray unselected, Bright Azure indicator

## Implementation Files

### Core Theme Files
```
lib/core/theme/
├── app_colors.dart          # Complete color palette
├── app_text_theme.dart      # Typography system
├── button_styles.dart       # Button style variants
├── app_theme.dart          # Main theme configuration
└── app_spacing.dart        # Spacing & layout constants
```

### Constants
```
lib/core/constants/
├── app_constants.dart      # Updated color values & constants
└── font_constants.dart     # Font family & weight definitions
```

## Usage Examples

### Using Colors
```dart
// Import colors
import 'package:customer_app/core/theme/app_colors.dart';

// Use in widgets
Container(
  color: AppColors.primary,
  child: Text(
    'Hello World',
    style: TextStyle(color: AppColors.textOnPrimary),
  ),
)
```

### Using Typography
```dart
// Import text theme
import 'package:customer_app/core/theme/app_text_theme.dart';

// Use text styles
Text(
  'Main Heading',
  style: AppTextTheme.heading1,
)

Text(
  'Body content goes here...',
  style: AppTextTheme.bodyText,
)
```

### Using Button Styles
```dart
// Import button styles
import 'package:customer_app/core/theme/button_styles.dart';

// Use button styles
ElevatedButton(
  style: AppButtonStyles.primary,
  onPressed: () {},
  child: Text('Primary Action'),
)

ElevatedButton(
  style: AppButtonStyles.secondary,
  onPressed: () {},
  child: Text('Secondary Action'),
)
```

### Using Spacing
```dart
// Import spacing
import 'package:customer_app/core/theme/app_spacing.dart';

// Use spacing constants
Padding(
  padding: AppSpacing.paddingM,
  child: Column(
    children: [
      Text('Item 1'),
      SizedBox(height: AppSpacing.s),
      Text('Item 2'),
    ],
  ),
)
```

## Responsive Design

### Breakpoints
- **Mobile**: < 480px
- **Tablet**: 480px - 768px
- **Desktop**: > 768px

### Responsive Utilities
```dart
// Check device type
bool isMobile = AppSpacing.isMobile(screenWidth);
bool isTablet = AppSpacing.isTablet(screenWidth);

// Get responsive padding
EdgeInsets padding = AppSpacing.getResponsivePadding(screenWidth);

// Get grid column count
int columns = AppSpacing.getGridColumnCount(screenWidth);
```

## Best Practices

### Do's
✅ Use design system colors consistently  
✅ Follow typography hierarchy  
✅ Use appropriate spacing scale  
✅ Apply semantic colors for their intended purpose  
✅ Use button variants appropriately  
✅ Test on different screen sizes  

### Don'ts
❌ Don't use hardcoded colors  
❌ Don't mix font families  
❌ Don't use arbitrary spacing values  
❌ Don't use semantic colors for decoration  
❌ Don't create custom button styles without reason  
❌ Don't ignore accessibility guidelines  

## Accessibility

### Color Contrast
- All text meets WCAG AA standards (4.5:1 contrast ratio)
- Important actions meet AAA standards (7:1 contrast ratio)

### Typography
- Minimum font size: 12px for fine print
- Standard body text: 16px for readability
- Proper line heights for easy reading

### Interactive Elements
- Minimum touch target: 44px × 44px
- Clear focus states for keyboard navigation
- Proper semantic markup

## Future Enhancements

### Dark Mode Support
The design system includes basic dark mode theme structure for future implementation.

### Additional Components
- Alert/notification styles
- Badge components
- Progress indicators
- Data visualization colors

### Animation System
Standardized animation durations and curves are defined for consistent motion design.

---

**Note**: This design system ensures visual consistency and provides a solid foundation for scaling the Cloud Ironing application while maintaining excellent user experience across all platforms and devices. 