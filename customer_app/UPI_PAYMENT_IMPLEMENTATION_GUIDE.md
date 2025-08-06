# UPI Payment Integration - Complete Implementation Guide

## Overview
This document provides a comprehensive guide for the UPI payment integration implemented in the customer app using the `upi_pay: ^1.1.0` package. The implementation includes transaction management, local storage, and a complete payment flow.

## Package Information
- **Package**: `upi_pay: ^1.1.0`
- **Purpose**: UPI payment functionality with support for popular UPI apps
- **Platform Support**: Android and iOS

## Dependencies Added

```yaml
dependencies:
  # UPI Payment Integration
  upi_pay: ^1.1.0 # For UPI payment functionality
  sqflite: ^2.3.3 # For local database storage
  crypto: ^3.0.3 # For generating transaction IDs
  device_info_plus: ^10.1.2 # For device information
```

## File Structure

```
lib/
├── data/
│   └── models/
│       └── transaction_model.dart          # Transaction data model
├── services/
│   └── upi_payment_service.dart           # Core UPI payment service
├── presentation/
│   ├── providers/
│   │   └── payment_provider.dart          # Payment state management
│   └── screens/
│       └── payment/
│           ├── payment_screen.dart         # Payment form UI
│           ├── payment_status_screen.dart  # Payment result display
│           └── transaction_history_screen.dart # Transaction history
```

## Key Features

### 1. **UPI App Detection**
- Automatically detects installed UPI applications
- Supports popular apps: PhonePe, GPay, Paytm, etc.
- Displays app icons and names for selection

### 2. **Payment Form**
- Amount input with validation (₹1 - ₹1,00,000)
- Payment description
- Payer information (name and UPI ID)
- UPI app selection grid

### 3. **Transaction Management**
- Unique transaction ID generation using SHA-256
- Local SQLite database storage
- Transaction status tracking (pending, success, failed, cancelled)
- Transaction history with filtering

### 4. **Error Handling**
- Form validation for all input fields
- UPI ID format validation
- Amount range validation
- Network and app-specific error handling

### 5. **Cross-Platform Support**
- Android: Full UPI transaction support with response data
- iOS: UPI app launch with status tracking

## Core Components

### UpiPaymentService
The main service class that handles:
- UPI app discovery using `getInstalledUpiApplications()`
- Payment initiation with `initiateTransaction()`
- Transaction database management
- Response handling for both Android and iOS

### PaymentProvider
State management for:
- Form validation
- UPI app selection
- Payment processing
- Transaction loading

### Transaction Model
Data structure for:
- Transaction details and metadata
- Status tracking
- Amount and description
- UPI app information

## API Methods Used

### UpiPay Class
```dart
// Get installed UPI applications
Future<List<ApplicationMeta>> getInstalledUpiApplications()

// Initiate payment transaction
Future<UpiTransactionResponse> initiateTransaction({
  required UpiApplication app,
  required String receiverUpiAddress,
  required String receiverName,
  required String transactionRef,
  required String amount,
  String? transactionNote,
})
```

### UpiTransactionResponse Properties
```dart
// Android-specific properties
String? get txnId              // Transaction ID
String? get responseCode       // Response code
String? get txnRef            // Transaction reference
UpiTransactionStatus? get status  // Transaction status

// iOS-specific properties  
String? get launchError       // App launch error (iOS only)
```

## Configuration Required

### Business Configuration
Update these constants in `UpiPaymentService`:

```dart
static const String _merchantId = 'YOUR_MERCHANT_ID';
static const String _merchantName = 'Your Business Name';
static const String _merchantUpiId = 'your-upi-id@provider';
static const String _merchantPhone = 'your-phone-number';
```

### Android Manifest
Add UPI app queries in `android/app/src/main/AndroidManifest.xml`:

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="upi" />
    </intent>
    <!-- Popular UPI Apps -->
    <package android:name="com.google.android.apps.nbu.paisa.user" />
    <package android:name="com.phonepe.app" />
    <package android:name="net.one97.paytm" />
    <!-- Add more as needed -->
</queries>
```

### iOS Configuration
Add to `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>freecharge</string>
    <string>gpay</string>
    <string>in.fampay.app</string>
    <string>lotza</string>
    <string>mobikwik</string>
    <string>paytm</string>
    <string>phonepe</string>
    <string>upi</string>
    <string>upibillpay</string>
    <string>whatsapp</string>
</array>
```

## UI Components

### Payment Screen Features
- **Modern Material Design 3 UI**
- **Responsive layout with proper spacing**
- **Form validation with real-time feedback**
- **UPI app grid with visual selection**
- **Payment summary card**
- **Loading states and error handling**

### Payment Status Screen
- **Animated status indicators**
- **Detailed transaction information**
- **Action buttons for retry/sharing**
- **Platform-specific handling**

### Transaction History
- **Filterable transaction list**
- **Status-based color coding**
- **Search functionality**
- **Transaction statistics**

## Usage Examples

### Basic Payment Flow
```dart
// 1. Initialize payment provider
final paymentProvider = PaymentProvider();
await paymentProvider.initialize();

// 2. Set payment details
paymentProvider.setAmount(100.0);
paymentProvider.setDescription('Order payment');
paymentProvider.setPayerName('John Doe');
paymentProvider.setUpiId('john@paytm');

// 3. Select UPI app
paymentProvider.selectUpiApp(selectedApp);

// 4. Initiate payment
final success = await paymentProvider.initiatePayment(
  orderId: 'ORDER123',
  customerId: 'USER456',
);
```

### Transaction Retrieval
```dart
// Get transaction by ID
final transaction = await paymentService.getTransaction(transactionId);

// Get customer transactions
final transactions = await paymentService.getTransactionsByCustomerId(
  customerId,
  limit: 20,
);

// Get transaction statistics
final stats = await paymentService.getTransactionStats(customerId);
```

## Error Handling

### Common Error Scenarios
1. **UPI app not installed**: Show appropriate message and suggestions
2. **Invalid UPI ID**: Real-time validation with error messages
3. **Amount validation**: Range checking with user-friendly messages
4. **Network issues**: Retry mechanisms and offline support
5. **Transaction timeouts**: Status checking and user notifications

### Platform-Specific Handling
- **Android**: Full transaction response with detailed status codes
- **iOS**: App launch status with simplified error handling

## Testing

### Test Payment Flow
1. Use small amounts (₹1-10) for testing
2. Test with different UPI apps if available
3. Verify transaction storage and retrieval
4. Test error scenarios (invalid inputs, network issues)

### Test Scenarios
- Valid payment with successful completion
- Payment cancellation by user
- Invalid UPI ID handling
- Amount validation (below minimum, above maximum)
- UPI app not available scenarios

## Security Considerations

1. **Transaction ID Generation**: Uses cryptographic hashing (SHA-256)
2. **Input Validation**: Comprehensive validation for all user inputs
3. **Local Storage**: Encrypted SQLite database for sensitive data
4. **UPI ID Validation**: Regular expression-based format checking
5. **Amount Limits**: Built-in maximum transaction limits

## Maintenance

### Database Cleanup
The service includes automatic cleanup of old transactions:
```dart
await paymentService.cleanupOldTransactions(daysOld: 365);
```

### Logging
Comprehensive logging using the Logger package for:
- Payment initiation and completion
- Error tracking and debugging
- UPI app detection and selection
- Database operations

## Troubleshooting

### Common Issues
1. **UPI apps not detected**: Check AndroidManifest.xml queries configuration
2. **Payment fails immediately**: Verify UPI ID format and amount validity
3. **iOS app launch issues**: Check Info.plist LSApplicationQueriesSchemes
4. **Database errors**: Ensure proper initialization and error handling

### Debug Tips
- Enable verbose logging in development
- Test with multiple UPI apps
- Verify merchant configuration details
- Check platform-specific implementations

## Performance Optimizations

1. **Lazy Loading**: UPI apps loaded only when needed
2. **Database Indexing**: Optimized queries with proper indexes
3. **Caching**: Application metadata cached for better performance
4. **Background Processing**: Heavy operations performed asynchronously

## Future Enhancements

1. **Merchant Integration**: Support for merchant-specific payments
2. **QR Code Payments**: Integration with UPI QR code scanning
3. **Recurring Payments**: Support for subscription-based payments
4. **Analytics**: Advanced transaction analytics and reporting
5. **Webhook Integration**: Real-time payment status updates

This implementation provides a robust, production-ready UPI payment system with comprehensive error handling, local storage, and a modern user interface. 