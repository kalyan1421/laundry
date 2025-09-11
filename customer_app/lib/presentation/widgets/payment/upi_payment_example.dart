// Example usage of UPI Payment Integration
// This file demonstrates how to use the UPI payment widgets in your Flutter app

import 'package:flutter/material.dart';
import 'upi_payment_widget.dart';

class UPIPaymentExampleScreen extends StatelessWidget {
  const UPIPaymentExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UPI Payment Integration Features:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              icon: Icons.apps,
              title: 'Deep Link Method',
              description: 'Direct integration with UPI apps like GPay, PhonePe, Paytm',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.qr_code,
              title: 'QR Code Generation',
              description: 'Generate QR codes for easy scanning and payment',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.copy,
              title: 'Manual UPI ID',
              description: 'Copy UPI ID for manual payment as fallback',
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => _showUPIPaymentExample(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Try UPI Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Integration Benefits:',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• No transaction charges\n'
                    '• Instant payment confirmation\n'
                    '• Multiple payment methods\n'
                    '• Secure and encrypted\n'
                    '• Works on both Android and iOS',
                    style: TextStyle(
                      color: Colors.green[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUPIPaymentExample(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: UPIPaymentWidget(
                amount: 100.0, // Example amount
                description: 'Example payment - Test order',
                orderId: 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
                onPaymentResult: (result) {
                  Navigator.pop(context);
                  
                  // Show result
                  final message = result['success'] == true
                      ? 'Payment completed successfully!'
                      : result['message'] ?? 'Payment failed';
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: result['success'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                },
                onCancel: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
HOW TO INTEGRATE UPI PAYMENT:

1. Add dependencies to pubspec.yaml:
   ```yaml
   dependencies:
     url_launcher: ^6.2.6
     qr_flutter: ^4.1.0
   ```

2. Add Android permissions (already done in your manifest):
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   
   <queries>
     <intent>
       <action android:name="android.intent.action.VIEW" />
       <data android:scheme="upi" />
     </intent>
   </queries>
   ```

3. Usage in your screen:
   ```dart
   import '../../widgets/payment/upi_payment_widget.dart';
   
   // In your payment method
   showModalBottomSheet(
     context: context,
     isScrollControlled: true,
     backgroundColor: Colors.transparent,
     builder: (context) => DraggableScrollableSheet(
       initialChildSize: 0.9,
       minChildSize: 0.5,
       maxChildSize: 0.95,
       builder: (context, scrollController) => Container(
         decoration: const BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
         ),
         child: SingleChildScrollView(
           controller: scrollController,
           child: Padding(
             padding: const EdgeInsets.all(20),
             child: UPIPaymentWidget(
               amount: yourAmount,
               description: 'Your payment description',
               orderId: 'YOUR_ORDER_ID',
               onPaymentResult: (result) {
                 Navigator.pop(context);
                 if (result['success'] == true) {
                   // Handle successful payment
                   processOrder(result['transactionId']);
                 } else {
                   // Handle payment failure
                   showErrorMessage(result['message']);
                 }
               },
               onCancel: () {
                 Navigator.pop(context);
               },
             ),
           ),
         ),
       ),
     ),
   );
   ```

PAYMENT METHODS SUPPORTED:

1. UPI Deep Link Method:
   - Direct integration with UPI apps
   - Opens user's preferred UPI app
   - Most reliable method

2. QR Code Method:
   - Generates UPI QR code
   - User scans with any UPI app
   - Good for desktop/web versions

3. Manual UPI ID Method:
   - Provides copyable UPI ID
   - Fallback when other methods fail
   - User can manually send payment

CONFIGURATION:

Update the UPI ID and merchant name in:
- upi_payment_widget.dart (lines 44-45)
- upi_app_selection_service.dart (lines 20-21)

Replace with your actual UPI ID:
```dart
static const String _merchantUpiId = 'your-upi-id@bank';
static const String _merchantName = 'Your Business Name';
```
*/
