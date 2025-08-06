# UPI Payment - Quick Start Guide

## Quick Setup

### 1. Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  upi_pay: ^1.1.0
  sqflite: ^2.3.3
  crypto: ^3.0.3
  device_info_plus: ^10.1.2
```

### 2. Configuration

#### Update Business Details
In `lib/services/upi_payment_service.dart`:
```dart
static const String _merchantId = 'YOUR_MERCHANT_ID';
static const String _merchantName = 'Your Business Name';
static const String _merchantUpiId = 'your-upi-id@provider';
static const String _merchantPhone = 'your-phone-number';
```

#### Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="upi" />
    </intent>
    <package android:name="com.google.android.apps.nbu.paisa.user" />
    <package android:name="com.phonepe.app" />
    <package android:name="net.one97.paytm" />
</queries>
```

#### iOS Configuration  
Add to `ios/Runner/Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>gpay</string>
    <string>phonepe</string>
    <string>paytm</string>
    <string>upi</string>
</array>
```

### 3. Register Provider
In `lib/main.dart`:
```dart
import 'package:customer_app/presentation/providers/payment_provider.dart';

MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(create: (_) => PaymentProvider()),
  ],
  child: MyApp(),
);
```

## Quick Usage

### Navigate to Payment
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentScreen(
      orderId: 'ORDER123',
      initialAmount: 100.0,
      initialDescription: 'Service payment',
    ),
  ),
);
```

### Check Payment Status
```dart
final paymentProvider = Provider.of<PaymentProvider>(context);
final transaction = await paymentProvider.getTransaction('TRANSACTION_ID');

if (transaction?.isSuccessful == true) {
  // Payment successful
  print('Payment completed: ${transaction.formattedAmount}');
}
```

## API Reference

### UPI Service Methods
```dart
// Get available UPI apps
Future<List<ApplicationMeta>> getAvailableUpiApps()

// Create transaction
Future<TransactionModel> createTransaction({
  required String orderId,
  required String customerId,
  required double amount,
  required String description,
  required String upiId,
  required String payerName,
})

// Initiate payment
Future<UpiTransactionResponse> initiatePayment({
  required TransactionModel transaction,
  required ApplicationMeta appMeta,
})
```

### Payment Provider Methods
```dart
// Initialize provider
await paymentProvider.initialize();

// Set payment details
paymentProvider.setAmount(100.0);
paymentProvider.setDescription('Payment description');
paymentProvider.setPayerName('Customer Name');
paymentProvider.setUpiId('customer@upi');

// Select UPI app and initiate payment
paymentProvider.selectUpiApp(selectedApp);
final success = await paymentProvider.initiatePayment(
  orderId: 'ORDER123',
  customerId: 'USER456',
);
```

## Testing

### Test with Small Amounts
```dart
// Use ₹1-10 for testing
paymentProvider.setAmount(1.0);
```

### Test Scenarios
- Valid payment flow
- Invalid UPI ID format
- Amount validation (min/max)
- UPI app not available
- Payment cancellation

## Security Notes

1. **Update merchant UPI ID** with your actual business UPI ID
2. **Use HTTPS** for any network communications
3. **Validate inputs** before processing
4. **Test thoroughly** before production deployment

## Ready to Test! 🚀

1. Update merchant configuration
2. Install UPI apps on test device
3. Test with small amounts
4. Verify transaction storage
5. Deploy to production

For complete documentation, see `UPI_PAYMENT_IMPLEMENTATION_GUIDE.md` 