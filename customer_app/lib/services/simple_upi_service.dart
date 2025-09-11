import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

class SimpleUpiService {
  static const String _merchantUpiId = '7396674546-3@ybl';
  static const String _merchantName = 'Cloud Ironing Factory';
  
  final Logger _logger = Logger();

  /// Try different UPI apps in order of preference
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String description,
    String? orderId,
  }) async {
    try {
      // Validate minimum amount (some UPI apps reject very small amounts)
      if (amount < 1.0) {
        _logger.w('⚠️ Amount too small: ₹$amount (minimum ₹1.00 recommended)');
        return {
          'success': false,
          'error': 'Amount too small',
          'message': 'Minimum amount for UPI payment is ₹1.00',
        };
      }

      // Generate transaction reference
      final transactionRef = orderId ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';
      
      _logger.i('🔄 Initiating UPI payment for ₹$amount');
      _logger.i('📝 Description: $description');
      _logger.i('🆔 Transaction ID: $transactionRef');
      _logger.i('💳 UPI ID: $_merchantUpiId');
      
      // Try multiple UPI apps in order of preference
      final upiApps = [
        {'name': 'Google Pay', 'package': 'com.google.android.apps.nbu.paisa.user'},
        {'name': 'PhonePe', 'package': 'com.phonepe.app'},
        {'name': 'Paytm', 'package': 'net.one97.paytm'},
        {'name': 'BHIM', 'package': 'in.org.npci.upiapp'},
      ];

      // Create UPI payment URL
      final upiUrl = _createUpiUrl(
        amount: amount,
        note: description,
        transactionRef: transactionRef,
      );
      
      _logger.i('🔗 UPI URL: $upiUrl');
      
      // Try to launch UPI payment
      final uri = Uri.parse(upiUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _logger.i('✅ UPI payment launched successfully');
        
        // Return success with transaction details and manual option
        return {
          'success': true,
          'transactionId': transactionRef,
          'message': 'UPI payment initiated successfully',
          'amount': amount,
          'upiId': _merchantUpiId,
          'showManualOption': true, // Allow manual payment as backup
        };
      } else {
        _logger.e('❌ No UPI app available to handle payment');
        return {
          'success': false,
          'error': 'No UPI app found on device',
          'message': 'Please install a UPI app like Google Pay, PhonePe, or Paytm',
          'showManualOption': true,
        };
      }
    } catch (e) {
      _logger.e('❌ Error initiating UPI payment: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to initiate UPI payment. Please try again.',
        'showManualOption': true,
      };
    }
  }

  /// Create UPI payment URL with proper encoding
  String _createUpiUrl({
    required double amount,
    required String note,
    required String transactionRef,
  }) {
    final Map<String, String> params = {
      'pa': _merchantUpiId,
      'pn': _merchantName,
      'tr': transactionRef,
      'tn': note,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'mc': '0000', // Merchant category code
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'upi://pay?$queryString';
  }

  /// Copy UPI ID to clipboard for manual payment
  Future<void> copyUpiId() async {
    await Clipboard.setData(ClipboardData(text: _merchantUpiId));
    _logger.i('📋 UPI ID copied to clipboard: $_merchantUpiId');
  }

  /// Get manual payment instructions
  Map<String, String> getManualPaymentDetails({
    required double amount,
    required String transactionRef,
    required String description,
  }) {
    return {
      'upiId': _merchantUpiId,
      'merchantName': _merchantName,
      'amount': '₹${amount.toStringAsFixed(2)}',
      'transactionRef': transactionRef,
      'description': description,
      'instructions': 'Open any UPI app → Send Money → Enter UPI ID → Enter amount → Add note',
    };
  }

  String get merchantUpiId => _merchantUpiId;
  String get merchantName => _merchantName;
} 