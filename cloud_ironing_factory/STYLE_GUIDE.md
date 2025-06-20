# Cloud Ironing Factory - Style Guide

## Color Palette

### Primary Colors

#### Deep Navy Blue (#0F3057) - `AppTheme.primaryNavy`
**Usage**: Headers, navigation, primary buttons, brand elements
- Navigation bars
- Main headers (H1, H2)
- Primary action buttons
- Brand logo backgrounds
- Footer backgrounds

#### Light Blue (#88C1E3) - `AppTheme.secondaryLightBlue` 
**Usage**: Accent elements, hover states, secondary backgrounds
- Button hover states
- Section dividers
- Secondary backgrounds
- Card borders (subtle)
- Navigation hover effects

#### Bright Azure (#00A8E8) - `AppTheme.accentAzure`
**Usage**: Call-to-action buttons, links, highlights
- CTA buttons ("Book a Pickup", "Contact Us")
- Interactive links
- Icon highlights
- Progress indicators
- Active states

#### Fresh Teal (#5CB8B2) - `AppTheme.successTeal`
**Usage**: Success indicators, testimonial highlights
- Success messages
- Completed status indicators
- Testimonial accents
- Positive feedback elements

#### Gold Yellow (#FFB347) - `AppTheme.warmGold`
**Usage**: Special offers, premium service highlights
- Special offer badges
- Premium service indicators
- Important notifications
- Achievement highlights

### Neutral Colors

#### Pure White (#FFFFFF) - `AppTheme.pureWhite`
**Usage**: Main backgrounds, card backgrounds
- Page backgrounds
- Card backgrounds
- Modal backgrounds
- Button text (on dark backgrounds)

#### Light Gray (#F5F7FA) - `AppTheme.lightGray`
**Usage**: Section backgrounds, subtle separators
- Alternate section backgrounds
- Input field backgrounds
- Subtle dividers
- Loading placeholders

#### Medium Gray (#D9E2EC) - `AppTheme.mediumGray`
**Usage**: Borders, inactive states
- Input borders
- Card borders
- Inactive button states
- Disabled elements

#### Dark Gray (#3B4D61) - `AppTheme.darkGray`
**Usage**: Body text, content
- Main body text
- Paragraph content
- Labels
- Content headings

#### Warm Gray (#6E7A8A) - `AppTheme.warmGray`
**Usage**: Secondary text, captions
- Secondary text
- Captions
- Placeholder text
- Metadata

## Typography

### Font Family
**Primary Font**: SF Pro Display (`AppTheme.primaryFont`)
- All text elements use SF Pro Display for consistency
- Modern, professional, highly readable
- Available weights: Thin, Light, Regular, Medium, Semibold, Bold, Heavy, Black
- Available styles: Normal and Italic

### Text Styles

#### Display Styles (Hero Titles)
- **Display Large**: 48px, Bold, Primary Navy
- **Display Medium**: 40px, Bold, Primary Navy  
- **Display Small**: 32px, Bold, Primary Navy

#### Headline Styles (Section Headers)
- **Headline Large**: 32px, Bold, Primary Navy
- **Headline Medium**: 28px, Bold, Primary Navy
- **Headline Small**: 24px, Semi-bold, Primary Navy

#### Title Styles (Card Headers)
- **Title Large**: 22px, Semi-bold, Dark Gray
- **Title Medium**: 18px, Semi-bold, Dark Gray
- **Title Small**: 16px, Semi-bold, Dark Gray

#### Body Styles (Content)
- **Body Large**: 16px, Regular, Dark Gray
- **Body Medium**: 14px, Regular, Dark Gray
- **Body Small**: 12px, Regular, Warm Gray

#### Label Styles (Buttons & UI)
- **Label Large**: 16px, Semi-bold, Pure White (buttons)
- **Label Medium**: 14px, Medium, Dark Gray
- **Label Small**: 12px, Medium, Warm Gray

## Usage Guidelines

### Color Combinations

#### High Contrast (Accessibility)
- **Primary Navy + Pure White**: Navigation, headers
- **Dark Gray + Light Gray**: Content areas
- **Accent Azure + Pure White**: Call-to-action buttons

#### Subtle Combinations
- **Light Gray + Medium Gray**: Borders and dividers
- **Warm Gray + Pure White**: Secondary content
- **Secondary Light Blue + Pure White**: Hover states

### Button Styles

#### Primary Buttons
- Background: Accent Azure (#00A8E8)
- Text: Pure White
- Font: SF Pro Display, 16px, Semi-bold
- Padding: 32px horizontal, 16px vertical
- Border Radius: 25px

#### Secondary Buttons
- Background: Transparent
- Border: 2px Primary Navy
- Text: Primary Navy
- Font: SF Pro Display, 16px, Semi-bold

#### Text Buttons
- Background: Transparent
- Text: Accent Azure
- Font: SF Pro Display, 16px, Semi-bold

### Accessibility

#### Color Contrast Ratios
- Primary Navy (#0F3057) + Pure White: 11.42:1 (AAA)
- Dark Gray (#3B4D61) + Pure White: 7.8:1 (AAA)
- Accent Azure (#00A8E8) + Pure White: 2.9:1 (AA Large)
- Warm Gray (#6E7A8A) + Pure White: 4.2:1 (AA)

#### Font Size Accessibility
- Minimum body text: 14px
- Minimum UI elements: 12px
- Recommended line height: 1.5-1.6
- Maximum line length: 70-80 characters

### Implementation

#### CSS/Flutter Usage
```dart
// Colors
AppTheme.primaryNavy
AppTheme.secondaryLightBlue
AppTheme.accentAzure
AppTheme.successTeal
AppTheme.warmGold
AppTheme.pureWhite
AppTheme.lightGray
AppTheme.mediumGray
AppTheme.darkGray
AppTheme.warmGray

// Font
AppTheme.primaryFont // 'SF Pro Display'

// Utility Methods
AppTheme.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)
AppTheme.getButtonStyle(backgroundColor: AppTheme.accentAzure)
AppTheme.getCardDecoration(color: AppTheme.pureWhite, hasShadow: true)
```

#### Legacy Compatibility
For gradual migration, these aliases are available:
- `AppTheme.primaryBlue` → `AppTheme.accentAzure`
- `AppTheme.darkBlue` → `AppTheme.primaryNavy`
- `AppTheme.white` → `AppTheme.pureWhite`
- `AppTheme.textDark` → `AppTheme.darkGray`
- `AppTheme.textGrey` → `AppTheme.warmGray`

## Brand Guidelines

### Logo Usage
- Primary logo on Pure White backgrounds
- White logo on Primary Navy backgrounds
- Minimum size: 32px height
- Clear space: 16px on all sides

### Brand Voice
- Professional yet approachable
- Clean and modern
- Trustworthy and reliable
- Premium service quality

### Do's
✅ Use high contrast color combinations
✅ Maintain consistent spacing (16px grid system)
✅ Use SF Pro Display throughout
✅ Follow accessibility guidelines
✅ Use semantic color meanings (teal for success, etc.)

### Don'ts
❌ Mix different font families
❌ Use colors outside the defined palette
❌ Create low contrast combinations
❌ Use tiny font sizes (<12px)
❌ Ignore accessibility guidelines

---

**Last Updated**: 2024
**Version**: 1.0
**Contact**: Cloud Ironing Factory Development Team 