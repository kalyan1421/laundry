import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Generates a unique 6-digit order number
  /// Format: XXXXXX (where X is a digit from 0-9)
  /// Range: 100000 to 999999
  static Future<String> generateUniqueOrderNumber() async {
    const int maxRetries = 50;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      // Generate 6-digit number between 100000 and 999999
      int orderNumber = 100000 + _random.nextInt(900000);
      String orderNumberStr = orderNumber.toString();

      // Check if this order number already exists
      bool exists = await _orderNumberExists(orderNumberStr);
      
      if (!exists) {
        return orderNumberStr;
      }

      retryCount++;
    }

    // If we couldn't generate a unique number after max retries,
    // use timestamp-based approach as fallback
    return _generateTimestampBasedOrderNumber();
  }

  /// Check if an order number already exists in Firestore
  static Future<bool> _orderNumberExists(String orderNumber) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('orderNumber', isEqualTo: orderNumber)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking order number existence: $e');
      // In case of error, assume it exists to be safe
      return true;
    }
  }

  /// Generate a timestamp-based 6-digit order number as fallback
  static String _generateTimestampBasedOrderNumber() {
    // Use current timestamp and some randomness
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    
    // Take last 4 digits of timestamp and add 2 random digits
    final lastFourDigits = timestamp % 10000;
    final randomTwoDigits = _random.nextInt(100);
    
    // Combine to create 6-digit number
    final orderNumber = (lastFourDigits * 100 + randomTwoDigits) % 1000000;
    
    // Ensure it's at least 6 digits
    return orderNumber.toString().padLeft(6, '0');
  }

  /// Validate if a string is a valid 6-digit order number
  static bool isValidOrderNumber(String orderNumber) {
    if (orderNumber.length != 6) return false;
    
    // Check if all characters are digits
    return RegExp(r'^\d{6}$').hasMatch(orderNumber);
  }

  /// Generate a formatted order number with prefix (e.g., "ORD-123456")
  static String generateFormattedOrderNumber(String orderNumber) {
    return 'ORD-$orderNumber';
  }
} 