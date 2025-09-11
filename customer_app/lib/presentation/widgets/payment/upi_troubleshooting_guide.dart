// UPI Payment Troubleshooting Guide
// This file contains solutions for common UPI payment issues

import 'package:flutter/material.dart';

class UpiTroubleshootingGuide {
  static void showTroubleshootingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('UPI Payment Help'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTroubleshootingSection(
                'UPI App Won\'t Open',
                [
                  'Ensure you have a UPI app installed (Google Pay, PhonePe, Paytm)',
                  'Update your UPI app to the latest version',
                  'Clear cache of your UPI app',
                  'Try a different UPI app',
                  'Use the QR Code method instead',
                ],
              ),
              const SizedBox(height: 16),
              _buildTroubleshootingSection(
                'Payment Not Processing',
                [
                  'Check your internet connection',
                  'Verify UPI ID: 7396674546-3@ybl',
                  'Ensure sufficient balance in your account',
                  'Try manual payment using UPI ID',
                  'Contact your bank if UPI is blocked',
                ],
              ),
              const SizedBox(height: 16),
              _buildTroubleshootingSection(
                'QR Code Issues',
                [
                  'Ensure good lighting when scanning',
                  'Hold phone steady while scanning',
                  'Try zooming in/out on the QR code',
                  'Use a different UPI app to scan',
                  'Use manual UPI ID method instead',
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Still Need Help?',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact our support team:\n'
                      '• Phone: +91 9063290012\n'
                      '• Email: support@cloudironing.com\n'
                      '• In-app chat support',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTroubleshootingSection(String title, List<String> solutions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...solutions.map((solution) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      solution,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

/*
COMMON UPI PAYMENT ISSUES AND SOLUTIONS:

1. APP WON'T OPEN:
   - The most common issue is missing or outdated UPI apps
   - App-specific schemes might not work on all devices
   - Solution: Use generic UPI scheme as fallback

2. INVALID UPI ID:
   - UPI ID format must be correct: username@bank
   - Some banks use different formats
   - Solution: Verify UPI ID is active and correct

3. AMOUNT ISSUES:
   - Some UPI apps have minimum amount limits
   - Very small amounts (< ₹1) might be rejected
   - Solution: Ensure minimum ₹1 amount

4. NETWORK ISSUES:
   - Poor internet connection
   - UPI servers down
   - Solution: Retry with better connection

5. ANDROID QUERY PERMISSIONS:
   - Android 11+ requires query permissions for app detection
   - Solution: Add proper queries in AndroidManifest.xml

DEBUGGING TIPS:

1. Check Android Logs:
   - Look for "UrlLauncher" logs
   - Check component resolution logs
   - Verify intent handling

2. Test Different Apps:
   - Try multiple UPI apps
   - Test with different amounts
   - Use both schemes (app-specific and generic)

3. Fallback Methods:
   - Always provide QR code option
   - Include manual UPI ID copy
   - Show clear error messages

4. User Guidance:
   - Provide clear instructions
   - Show troubleshooting tips
   - Offer alternative payment methods
*/
