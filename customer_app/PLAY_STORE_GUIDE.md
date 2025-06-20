# Play Store Publication Guide

This guide will help you publish the Cloud Ironing app to the Google Play Store.

## Pre-Publication Checklist

### 1. App Configuration ✅
- [x] App name changed to "Cloud Ironing"
- [x] Package ID changed to `com.cloudironing.customer`
- [x] App description updated to professional content
- [x] Version set to 1.0.0+1
- [x] App icons generated successfully

### 2. Important: Package Name Update ✅

**Current Status**: Package name has been updated to `com.cloudironing.customer` - production ready!

**Previous Issues Fixed**:
- ❌ `com.example.customer_app` - Not allowed by Google Play Store
- ✅ `com.cloudironing.customer` - Production ready package name

### 3. Firebase Configuration ✅
- [x] Firebase project supports the new package name
- [x] google-services.json updated with new package configuration
- [x] Authentication and services configured

### 4. App Signing Setup
1. **Generate Upload Keystore**:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Create key.properties file**:
   - Copy `android/key.properties.example` to `android/key.properties`
   - Fill in your keystore details:
     ```
     storePassword=your_keystore_password
     keyPassword=your_key_password
     keyAlias=upload
     storeFile=../app/upload-keystore.jks
     ```

3. **Copy keystore to app directory**:
   ```bash
   cp ~/upload-keystore.jks android/app/
   ```

### 5. App Icon Setup
1. **Generate launcher icons**:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons:main
   ```

2. **Verify icon generation**: Check `android/app/src/main/res/mipmap-*` directories

### 6. Build Release APK/Bundle
1. **Build App Bundle (Recommended)**:
   ```bash
   flutter build appbundle --release
   ```

2. **Build APK (Alternative)**:
   ```bash
   flutter build apk --release
   ```

### 7. Play Store Console Setup

#### App Information
- **App Name**: Laundry Customer
- **Short Description**: Professional laundry services at your doorstep
- **Full Description**: 
  ```
  Transform your laundry experience with our comprehensive customer app. Order professional laundry services, track your items in real-time, and enjoy seamless pickup and delivery right to your doorstep.

  Key Features:
  • Easy order placement with customizable service options
  • Real-time tracking from pickup to delivery
  • GPS-based location services for accurate pickup/delivery
  • Multiple secure payment options (UPI, Cards, Cash)
  • Push notifications for order status updates
  • Complete order history and quick reordering
  • QR code scanning for instant tracking
  • Professional customer support

  Perfect for busy professionals, families, and anyone who values convenience and quality laundry care.
  ```

#### App Category & Tags
- **Category**: Lifestyle > Services
- **Tags**: laundry, cleaning, delivery, home services, lifestyle

#### Target Audience
- **Age Rating**: Everyone
- **Target Age**: 18-65 years
- **Content Rating**: Everyone

#### Pricing & Availability
- **Price**: Free
- **Countries**: Select your target countries
- **Device Categories**: Phone and Tablet

### 8. Store Listing Assets Required

#### App Icon
- Size: 512 x 512 pixels
- Format: PNG (no transparency)
- Location: Already configured in assets/icons/

#### Screenshots (Required)
Create the following screenshots:
1. **Phone Screenshots** (4-8 required):
   - Home/Dashboard screen
   - Order placement screen
   - Order tracking screen
   - Payment screen
   - Profile/Settings screen

2. **Tablet Screenshots** (Optional but recommended)
3. **Feature Graphic** (1024 x 500 pixels)

#### Store Listing Graphics
1. **Feature Graphic**: 1024 x 500 px
2. **High-res Icon**: 512 x 512 px (same as app icon)

### 9. App Content & Privacy

#### Privacy Policy
Create a privacy policy that covers:
- Data collection (location, personal info)
- Firebase/Google services usage
- Third-party integrations
- User rights and data handling

#### App Permissions Justification
- **Location**: For pickup and delivery address detection
- **Camera**: For QR code scanning and profile pictures
- **Internet**: For app functionality and real-time updates
- **Storage**: For caching images and offline functionality

#### Content Rating Questionnaire
- Violence: None
- Sexual Content: None
- Profanity: None
- Controlled Substances: None
- Gambling: None
- Social Features: None

### 10. Release Management

#### Internal Testing
1. Upload signed app bundle
2. Add internal testers (email addresses)
3. Test all core functionalities

#### Closed Testing (Optional)
1. Create closed testing track
2. Add external testers
3. Gather feedback and fix issues

#### Production Release
1. Review all store listing information
2. Submit for review
3. Monitor for review feedback
4. Publish when approved

### 11. Post-Launch Checklist

- [ ] Monitor crash reports and ANRs
- [ ] Respond to user reviews
- [ ] Track app performance metrics
- [ ] Plan for regular updates
- [ ] Monitor user feedback for improvements

### 12. Important Files & Locations

```
customer_app/
├── android/
│   ├── key.properties.example          # Keystore configuration template
│   │   ├── build.gradle.kts           # Build configuration
│   │   ├── proguard-rules.pro         # Code obfuscation rules
│   │   └── src/main/AndroidManifest.xml # App permissions & metadata
├── assets/icons/icon.png              # App icon source
├── pubspec.yaml                       # App metadata & dependencies
└── PLAY_STORE_GUIDE.md               # This guide
```

### 13. Common Issues & Solutions

#### Issue: App not signed properly
**Solution**: Ensure key.properties file is properly configured and keystore exists

#### Issue: App crashes on release build
**Solution**: Test release build locally first using `flutter run --release`

#### Issue: Missing permissions
**Solution**: Review AndroidManifest.xml and ensure all required permissions are declared

#### Issue: Large app size
**Solution**: Use app bundle instead of APK, enable R8 obfuscation

### 14. Support & Resources

- [Google Play Console](https://play.google.com/console/)
- [Flutter App Signing Guide](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Google Play Policy Center](https://play.google.com/about/developer-policy/)
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle)

---

**Remember**: Always test your release build thoroughly before uploading to Play Store!

**Note**: This app includes Firebase integration, location services, and payment features. Ensure you comply with all relevant Google Play policies for these sensitive permissions. 