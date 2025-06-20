# Cloud Ironing

A comprehensive Flutter application for professional laundry and ironing services, allowing customers to order, track, and manage their laundry services with real-time updates.

## Features

- **Order Management**: Place new laundry orders with customizable service options
- **Real-time Tracking**: Track your laundry status from pickup to delivery
- **Location Services**: GPS-based pickup and delivery location tracking
- **Secure Payments**: Multiple payment options including UPI, cards, and cash
- **Push Notifications**: Real-time updates on order status changes
- **Order History**: View past orders and reorder favorite services
- **Profile Management**: Manage personal information and preferences
- **QR Code Scanning**: Quick order tracking using QR codes

## Technical Stack

- **Framework**: Flutter 3.2+
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **Maps**: Google Maps integration
- **State Management**: Provider pattern
- **Notifications**: Firebase Cloud Messaging + Local Notifications

## Getting Started

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Android Studio / VS Code
- Firebase project setup

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase for your project
4. Run the app using `flutter run`

## App Architecture

The app follows a clean architecture pattern with:
- **Providers**: State management using Provider package
- **Services**: Firebase integration and API calls
- **Models**: Data models for orders, users, and services
- **Screens**: UI components organized by feature

## Play Store Readiness

This app is configured for Google Play Store publication with:
- Proper app signing configuration
- Appropriate permissions for location, camera, and storage
- UPI payment integration with popular apps
- Compliant with Google Play policies

## Support

For technical support or feature requests, please contact the development team.

---

*Built with Flutter for modern laundry management solutions*
