# Theme Usage Guide

This guide explains how to use the unified theme system in the Customer App to ensure consistent styling across all screens and components.

## Overview

The app uses a comprehensive theme system that supports both light and dark modes. All colors, typography, and component styles are centralized in the theme files.

## Theme Files Structure

```
lib/core/theme/
├── app_theme.dart          # Main theme definitions (light & dark)
├── app_colors.dart         # Color palette and constants
├── app_text_theme.dart     # Typography definitions
├── button_styles.dart      # Button style definitions
└── theme_extensions.dart   # Helper extensions for easy access
```

## Quick Start

### 1. Import Theme Extensions

```dart
import 'package:customer_app/core/theme/theme_extensions.dart';
```

### 2. Use Theme Colors

**❌ Don't use hardcoded colors:**
```dart
Container(
  color: Colors.blue,           // ❌ Hardcoded
  child: Text(
    'Hello',
    style: TextStyle(
      color: Colors.white,      // ❌ Hardcoded
      fontSize: 16,             // ❌ Hardcoded
    ),
  ),
)
```

**✅ Use theme colors:**
```dart
Container(
  color: context.primaryColor,  // ✅ Theme-aware
  child: Text(
    'Hello',
    style: context.bodyLarge,   // ✅ Theme-aware
  ),
)
```

### 3. Use Theme Text Styles

**❌ Don't use inline text styles:**
```dart
Text(
  'Title',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ),
)
```

**✅ Use theme text styles:**
```dart
Text(
  'Title',
  style: context.heading2,
)
```

## Color Usage

### Primary Colors
```dart
context.primaryColor          // Main brand color
context.onPrimaryColor        // Text on primary background
context.primaryContainer      // Light primary background
context.onPrimaryContainer    // Text on primary container
```

### Surface Colors
```dart
context.surfaceColor          // Card/dialog backgrounds
context.onSurfaceColor        // Text on surface
context.backgroundColor       // Main background
context.onBackgroundColor     // Text on background
```

### Semantic Colors
```dart
context.errorColor            // Error states
context.successColor          // Success states
context.warningColor          // Warning states
context.infoColor             // Info states
```

### Interactive Colors
```dart
context.tertiaryColor         // Accent/CTA elements
context.outlineColor          // Borders
context.outlineVariant        // Light borders/dividers
```

## Typography Usage

### Headings
```dart
Text('Main Title', style: context.heading1)      // 22px, Bold
Text('Section Title', style: context.heading2)   // 20px, Bold
Text('Subsection', style: context.heading3)      // 18px, SemiBold
```

### Body Text
```dart
Text('Main content', style: context.bodyLarge)   // 16px, Regular
Text('Secondary text', style: context.bodyMedium) // 14px, Regular
Text('Small text', style: context.bodySmall)     // 12px, Regular
```

### Labels and Captions
```dart
Text('Form Label', style: context.labelLarge)    // 14px, Medium
Text('Caption', style: context.labelMedium)      // 14px, Regular
Text('Small caption', style: context.labelSmall) // 12px, Regular
```

## Component Usage

### Buttons

**✅ Use theme-aware buttons:**
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Primary Action'),
  // Style automatically applied from theme
)

OutlinedButton(
  onPressed: () {},
  child: Text('Secondary Action'),
  // Style automatically applied from theme
)
```

### Text Fields

**✅ Use theme-aware text fields:**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email',
    // All styling applied from theme
  ),
)
```

### Cards and Containers

**✅ Use theme-aware containers:**
```dart
// Simple container
Container(
  color: context.surfaceColor,
  child: content,
)

// Using extension helper
content.withThemeContainer(
  context,
  padding: EdgeInsets.all(16),
  borderRadius: 12,
)

// Using Card widget
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: content,
  ),
)
```

## Dark Mode Support

The theme system automatically handles dark mode. Your widgets will adapt when the user switches themes.

**✅ Theme-aware conditional styling:**
```dart
Container(
  color: context.isDarkMode 
    ? context.surfaceColor 
    : context.backgroundColor,
  child: content,
)
```

## Migration from Hardcoded Styles

### Step 1: Replace Colors
```dart
// Before
Colors.blue        → context.primaryColor
Colors.white       → context.surfaceColor
Colors.black       → context.onSurfaceColor
Colors.grey        → context.outlineColor
Colors.red         → context.errorColor
Colors.green       → context.successColor
```

### Step 2: Replace Text Styles
```dart
// Before
TextStyle(fontSize: 20, fontWeight: FontWeight.bold)  → context.heading2
TextStyle(fontSize: 16, fontWeight: FontWeight.normal) → context.bodyLarge
TextStyle(fontSize: 14, color: Colors.grey)           → context.labelMedium
```

### Step 3: Use Theme Components
```dart
// Before
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey),
  ),
)

// After
Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: context.outlineColor),
  ),
)
```

## Best Practices

### 1. Always Use Theme References
- Never use `Colors.xxx` directly
- Never use hardcoded hex colors
- Never use inline `TextStyle` definitions

### 2. Prefer Extension Methods
```dart
// Good
context.primaryColor
context.heading1

// Avoid
Theme.of(context).colorScheme.primary
Theme.of(context).textTheme.headlineLarge
```

### 3. Use Semantic Names
```dart
// Good - semantic meaning
context.errorColor
context.successColor

// Avoid - specific colors
context.redColor
context.greenColor
```

### 4. Test in Both Themes
Always test your UI in both light and dark modes to ensure proper contrast and readability.

### 5. Use Helper Widgets
```dart
// Use theme-aware helpers
ThemeAwareWidgets.divider(context)
ThemeAwareWidgets.loadingIndicator(context)
content.withThemeCard(context)
```

## Common Patterns

### Loading States
```dart
ThemeAwareWidgets.loadingIndicator(
  context,
  color: context.primaryColor,
)
```

### Error States
```dart
Container(
  color: context.errorColor,
  child: Text(
    'Error message',
    style: context.bodyMedium.copyWith(
      color: context.onErrorColor,
    ),
  ),
)
```

### Success States
```dart
Container(
  color: context.successColor,
  child: Text(
    'Success message',
    style: context.bodyMedium.copyWith(
      color: context.onSuccessColor,
    ),
  ),
)
```

### Disabled States
```dart
Text(
  'Disabled text',
  style: context.bodyMedium.copyWith(
    color: context.onSurfaceColor.withOpacity(0.38),
  ),
)
```

## Troubleshooting

### Theme Not Applied
- Ensure your widget is wrapped in `MaterialApp` with the theme
- Check that you're using `context.xxx` not hardcoded values
- Verify imports are correct

### Colors Look Wrong in Dark Mode
- Use semantic colors instead of specific colors
- Test with `context.isDarkMode` conditions
- Check contrast ratios

### Text Not Readable
- Use appropriate text colors for backgrounds
- Use `context.getTextColorForBackground(backgroundColor)`
- Follow Material Design contrast guidelines

## Examples

See the updated components in:
- `lib/presentation/widgets/common/custom_button.dart`
- `lib/presentation/widgets/common/custom_text_field.dart`
- `lib/presentation/screens/main/main_wrapper.dart`
- `lib/presentation/screens/main/bottom_navigation.dart`

These files demonstrate proper theme usage patterns.

