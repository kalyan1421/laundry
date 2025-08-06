import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

class UpiApp {
  final String name;
  final String packageName;
  final String scheme;
  final String icon;

  const UpiApp({
    required this.name,
    required this.packageName,
    required this.scheme,
    required this.icon,
  });
}

class UpiAppSelectionService {
  static const String _merchantUpiId = '7396674546@axl';
  static const String _merchantName = 'Cloud Ironing Factory';
  
  final Logger _logger = Logger();

  /// Popular UPI apps with their details
  static const List<UpiApp> _popularUpiApps = [
    UpiApp(
      name: 'Google Pay',
      packageName: 'com.google.android.apps.nbu.paisa.user',
      scheme: 'gpay',
      icon: '💳', // We'll use emoji for now, can be replaced with proper icons
    ),
    UpiApp(
      name: 'PhonePe',
      packageName: 'com.phonepe.app',
      scheme: 'phonepe',
      icon: '📱',
    ),
    UpiApp(
      name: 'Paytm',
      packageName: 'net.one97.paytm',
      scheme: 'paytm',
      icon: '💰',
    ),
    UpiApp(
      name: 'BHIM UPI',
      packageName: 'in.org.npci.upiapp',
      scheme: 'upi',
      icon: '🏛️',
    ),
    UpiApp(
      name: 'Amazon Pay',
      packageName: 'in.amazon.mShop.android.shopping',
      scheme: 'amzn',
      icon: '📦',
    ),
    UpiApp(
      name: 'MobiKwik',
      packageName: 'com.mobikwik_new',
      scheme: 'mobikwik',
      icon: '🔵',
    ),
    UpiApp(
      name: 'FreeCharge',
      packageName: 'com.freecharge.android',
      scheme: 'freecharge',
      icon: '⚡',
    ),
    UpiApp(
      name: 'WhatsApp Pay',
      packageName: 'com.whatsapp',
      scheme: 'whatsapp',
      icon: '💬',
    ),
  ];

  /// Get list of available UPI apps (for now returns all popular apps)
  /// In a real implementation, you could check if apps are installed
  List<UpiApp> getAvailableUpiApps() {
    _logger.i('🔍 Getting available UPI apps');
    return _popularUpiApps;
  }

  /// Make payment with selected UPI app
  Future<Map<String, dynamic>> makePaymentWithApp({
    required UpiApp selectedApp,
    required double amount,
    required String description,
    String? orderId,
  }) async {
    try {
      // Validate minimum amount
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
      _logger.i('📱 Selected App: ${selectedApp.name}');

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
        _logger.i('✅ UPI payment launched successfully with ${selectedApp.name}');
        
        return {
          'success': true,
          'transactionId': transactionRef,
          'message': 'UPI payment initiated successfully with ${selectedApp.name}',
          'amount': amount,
          'upiId': _merchantUpiId,
          'selectedApp': selectedApp.name,
        };
      } else {
        _logger.e('❌ Could not launch UPI payment with ${selectedApp.name}');
        return {
          'success': false,
          'error': 'Could not launch ${selectedApp.name}',
          'message': 'Failed to open ${selectedApp.name}. Please try another UPI app.',
        };
      }
    } catch (e) {
      _logger.e('❌ Error initiating UPI payment with ${selectedApp.name}: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to initiate UPI payment with ${selectedApp.name}. Please try again.',
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

  /// Get manual payment details
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